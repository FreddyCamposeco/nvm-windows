# nvm-use.ps1 - Funciones de cambio y gestión de versiones activas de NVM

# Función para cambiar a una versión específica de Node.js
function Use-Node {
    param(
        [string]$Version,
        [switch]$Quiet
    )

    if ([string]::IsNullOrWhiteSpace($Version)) {
        # Buscar .nvmrc (prioridad máxima)
        $nvmrcVersion = Get-NvmrcVersion
        if ($nvmrcVersion) {
            if (-not $Quiet) {
                Write-Output "Encontrado .nvmrc con versión: $nvmrcVersion"
            }
            $Version = $nvmrcVersion
        }
        else {
            # Buscar versión por defecto (fallback)
            $defaultVersion = [Environment]::GetEnvironmentVariable("NVM_DEFAULT_VERSION", "User")
            if ($defaultVersion) {
                if (-not $Quiet) {
                    Write-Output "Usando versión por defecto: $defaultVersion"
                }
                $Version = $defaultVersion
            }
            else {
                Write-NvmError "Versión es requerida. Establece una versión por defecto con 'nvm set-default <version>' o crea un .nvmrc"
                return
            }
        }
    }

    # Resolver alias especial (latest, lts, etc.) o versión específica
    $resolvedVersion = Resolve-Version $Version
    if (-not $resolvedVersion) {
        return
    }

    # Si la resolución fue diferente, mostrar el alias usado
    if ($resolvedVersion -ne $Version -and $Version -notmatch '^v?\d+\.\d+\.\d+$' -and -not $Quiet) {
        Write-Output "Usando alias '$Version' -> '$resolvedVersion'"
    }

    # Verificar si hay un alias guardado como archivo (para compatibilidad)
    $aliasPath = "$NVM_DIR\alias\$Version"
    if ((Test-Path $aliasPath) -and ($resolvedVersion -eq $Version)) {
        try {
            $fileAliasVersion = Get-Content $aliasPath -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
            if ($fileAliasVersion -and $fileAliasVersion -ne $Version) {
                $resolvedVersion = $fileAliasVersion
                if (-not $Quiet) {
                    Write-Output "Usando alias guardado '$Version' -> '$resolvedVersion'"
                }
            }
        }
        catch {
            Write-NvmError "Error al leer alias '$Version': $($_.Exception.Message)"
            return
        }
    }

    $nodePath = "$NVM_DIR\$resolvedVersion"
    if (!(Test-Path $nodePath)) {
        Write-NvmError "Versión $resolvedVersion no está instalada. Instálala primero con: nvm install $resolvedVersion"
        return
    }

    # Crear enlaces simbólicos en lugar de modificar PATH
    try {
        Set-NvmSymlinks $resolvedVersion

        if (-not $Quiet) {
            Write-Output "Ahora usando Node.js $resolvedVersion"
        }
    }
    catch {
        Write-NvmError "Error al crear enlaces simbólicos: $($_.Exception.Message)"
        return
    }

    # Establecer variable de entorno para compatibilidad con Starship y otros tools
    $env:NODE_VERSION = $resolvedVersion

    # Guardar la versión activa para persistencia entre sesiones
    Set-NvmActiveVersion $resolvedVersion
}

# Función para crear enlaces simbólicos para la versión activa
function Set-NvmSymlinks {
    param([string]$Version)

    $currentDir = "$NVM_DIR\current"
    $versionDir = "$NVM_DIR\$Version"

    # Verificar si podemos crear enlaces simbólicos
    $canCreateSymlinks = Test-SymlinkPermissions
    $canCreateJunctions = Test-JunctionPermissions

    if ($canCreateSymlinks) {
        Write-Host "Creando enlace simbólico para Node.js $Version..." -ForegroundColor Cyan

        try {
            # Limpiar directorio current si existe
            if (Test-Path $currentDir) {
                Remove-Item -Path $currentDir -Recurse -Force
            }

            # Crear enlace simbólico del directorio current completo
            New-Item -ItemType SymbolicLink -Path $currentDir -Target $versionDir | Out-Null

            Write-Host "Enlace simbólico creado: $currentDir -> $versionDir" -ForegroundColor Green
            Write-Host "Cambios de versión ahora son instantáneos!" -ForegroundColor Green

        } catch {
            Write-host "No se pudo crear enlace simbólico: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Intentando con junction points..." -ForegroundColor Yellow
            Create-JunctionFallback $Version
        }
    } elseif ($canCreateJunctions) {
        Write-Host "Creando junction point para Node.js $Version..." -ForegroundColor Cyan
        Create-JunctionFallback $Version
    } else {
        Write-Host "No hay permisos para crear enlaces simbólicos o junctions. Usando sistema de copias..." -ForegroundColor Red
        Create-CopyFallback $Version
    }
}

# Función para obtener la versión activa guardada
function Get-NvmActiveVersion {
    $activeFile = "$NVM_DIR\.active_version"
    if (Test-Path $activeFile) {
        try {
            $version = Get-Content $activeFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
            return $version
        }
        catch {
            # Ignore errors
        }
    }
    return $null
}

# Función para establecer la versión activa
function Set-NvmActiveVersion {
    param([string]$Version)

    $activeFile = "$NVM_DIR\.active_version"
    try {
        $Version | Out-File -FilePath $activeFile -Encoding UTF8 -NoNewline
    }
    catch {
        Write-NvmError "Error al guardar la versión activa: $($_.Exception.Message)"
    }
}

# Función para mostrar la versión actualmente activa
function Show-CurrentVersion {
    $currentVersion = Get-NvmCurrentVersion
    if ($currentVersion) {
        Write-Output $currentVersion
    }
    else {
        Write-NvmError "No se pudo determinar la versión actual de Node.js"
    }
}

# Función para migrar al sistema de enlaces simbólicos
function Migrate-ToSymlinks {
    Write-Host "Iniciando migración al sistema de enlaces optimizados..." -ForegroundColor Cyan

    # Verificar permisos para diferentes tipos de enlaces
    $canCreateSymlinks = Test-SymlinkPermissions
    $canCreateJunctions = Test-JunctionPermissions

    if (-not $canCreateSymlinks -and -not $canCreateJunctions) {
        Write-Host "No se detectaron permisos para crear enlaces simbólicos o junctions." -ForegroundColor Red
        Write-Host "Opciones para habilitar enlaces:" -ForegroundColor Yellow
        Write-Host "  1. Ejecutar PowerShell como Administrador y ejecutar:" -ForegroundColor Cyan
        Write-Host "     fsutil behavior set SymlinkEvaluation L2L:1 L2R:1 R2L:1 R2R:1" -ForegroundColor Cyan
        Write-Host "  2. O usar el sistema de copias optimizado (funciona sin permisos especiales)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Continuando con sistema de copias optimizado..." -ForegroundColor Yellow
        return
    }

    # Obtener versión actualmente activa
    $currentVersion = Get-NvmCurrentVersion
    if ($currentVersion) {
        try {
            Write-Host "Migrando versión $currentVersion..." -ForegroundColor Cyan

            if ($canCreateSymlinks) {
                Write-Host "Usando enlaces simbólicos (requiere administrador)..." -ForegroundColor Green
                Set-NvmSymlinks $currentVersion
            } elseif ($canCreateJunctions) {
                Write-Host "Usando junction points (no requiere permisos especiales)..." -ForegroundColor Green
                Create-JunctionFallback $currentVersion
            }

            # Verificar que los enlaces se crearon correctamente
            $currentItem = Get-Item "$NVM_DIR\current" -ErrorAction SilentlyContinue
            if ($currentItem) {
                if ($currentItem.LinkType -eq "SymbolicLink") {
                    Write-Host "✅ Migración completada exitosamente (Symbolic Link)!" -ForegroundColor Green
                    Write-Host "Ahora usando enlace simbólico: $NVM_DIR\current -> $($currentItem.Target)" -ForegroundColor Green
                } elseif ($currentItem.LinkType -eq "Junction") {
                    Write-Host "✅ Migración completada exitosamente (Junction Point)!" -ForegroundColor Green
                    Write-Host "Ahora usando junction point: $NVM_DIR\current -> $($currentItem.Target)" -ForegroundColor Green
                } else {
                    Write-Host "Migración completada con sistema de copias optimizado" -ForegroundColor Yellow
                }
            } else {
                Write-Host "El enlace no se creó correctamente. Usando sistema de copias." -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Error durante la migración: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Revirtiendo a sistema de copias optimizado..." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "No se pudo determinar la versión actual para migrar" -ForegroundColor Red
    }
}

# Función para verificar permisos de enlaces simbólicos
function Test-SymlinkPermissions {
    try {
        $testDir = "$NVM_DIR\.symlink_test"
        $testFile = "$testDir\test.txt"

        # Crear directorio de prueba
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null

        # Crear archivo de prueba
        "test" | Out-File -FilePath $testFile -Encoding UTF8

        # Intentar crear enlace simbólico
        $symlinkPath = "$testDir\test_link.txt"
        New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $testFile -ErrorAction Stop | Out-Null

        # Verificar que el enlace se creó
        if (Test-Path $symlinkPath) {
            $item = Get-Item $symlinkPath -ErrorAction SilentlyContinue
            $isSymlink = $item -and $item.LinkType -eq "SymbolicLink"
        } else {
            $isSymlink = $false
        }

        # Limpiar archivos de prueba
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue

        return $isSymlink
    } catch {
        # Limpiar archivos de prueba en caso de error
        if (Test-Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
}

# Función para verificar estado de enlaces simbólicos
function Get-NvmSymlinkStatus {
    $currentDir = "$NVM_DIR\current"

    if (!(Test-Path $currentDir)) {
        Write-host "Directorio current no existe" -ForegroundColor Yellow
        return
    }

    # Verificar si current es un enlace simbólico o junction
    $currentItem = Get-Item $currentDir -ErrorAction SilentlyContinue
    $isSymlink = $currentItem -and $currentItem.LinkType -eq "SymbolicLink"
    $isJunction = $currentItem -and $currentItem.LinkType -eq "Junction"

    if ($isSymlink) {
        Write-Host "Estado del directorio current:" -ForegroundColor Cyan
        Write-Host "  [SYMLINK] Directorio current es un enlace simbólico" -ForegroundColor Green
        Write-Host "  [TARGET] Apunta a: $($currentItem.Target)" -ForegroundColor Green
        Write-Host "  [FAST] Cambios de versión instantáneos activados" -ForegroundColor Green
        return
    }

    if ($isJunction) {
        Write-Host "Estado del directorio current:" -ForegroundColor Cyan
        Write-Host "  [JUNCTION] Directorio current es un junction point" -ForegroundColor Green
        Write-Host "  [TARGET] Apunta a: $($currentItem.Target)" -ForegroundColor Green
        Write-Host "  [FAST] Cambios de versión casi instantáneos activados" -ForegroundColor Green
        return
    }

    # Si no es un enlace simbólico ni junction, verificar archivos individuales (modo compatibilidad)
    $items = Get-ChildItem -Path $currentDir
    $symlinks = $items | Where-Object { $_.LinkType -eq "SymbolicLink" }
    $regularFiles = $items | Where-Object { $_.LinkType -ne "SymbolicLink" -and $_.LinkType -ne "Junction" -and -not $_.PSIsContainer }
    $directories = $items | Where-Object { $_.PSIsContainer }

    Write-Host "Estado del directorio current:" -ForegroundColor Cyan
    Write-Host "  [DIR] Total de elementos: $($items.Count)" -ForegroundColor Cyan
    Write-Host "  [SYMLINK] Enlaces simbólicos: $($symlinks.Count)" -ForegroundColor Green
    Write-Host "  [FILE] Archivos regulares: $($regularFiles.Count)" -ForegroundColor Yellow
    Write-Host "  [FOLDER] Directorios: $($directories.Count)" -ForegroundColor Magenta

    # Verificar versión actual
    $versionFile = "$currentDir\.nvm_version"
    if (Test-Path $versionFile) {
        try {
            $version = Get-Content $versionFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
            Write-Host "  [VERSION] Versión actual: $version" -ForegroundColor Cyan
        } catch {
            Write-Host "  [VERSION] Error al leer versión" -ForegroundColor Red
        }
    }

    if ($symlinks.Count -gt 0) {
        Write-Host ""
        Write-Host "Enlaces simbólicos encontrados:" -ForegroundColor Green
        foreach ($symlink in $symlinks) {
            try {
                $target = (Get-Item $symlink.FullName).Target
                Write-Host "  $($symlink.Name) -> $target" -ForegroundColor Gray
            } catch {
                Write-Host "  $($symlink.Name) -> [Error al obtener target]" -ForegroundColor Red
            }
        }
    }

    # Verificar permisos
    $canCreateSymlinks = Test-SymlinkPermissions
    $canCreateJunctions = Test-JunctionPermissions

    Write-Host ""
    if ($canCreateSymlinks) {
        Write-Host "✅ Permisos para enlaces simbólicos: HABILITADOS" -ForegroundColor Green
        Write-Host "   Recomendado: nvm migrate (instantáneo)" -ForegroundColor Cyan
    } elseif ($canCreateJunctions) {
        Write-Host "✅ Permisos para junction points: HABILITADOS" -ForegroundColor Green
        Write-Host "   Recomendado: nvm migrate (casi instantáneo)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Permisos para enlaces simbólicos: DESHABILITADOS" -ForegroundColor Red
        Write-Host "❌ Permisos para junction points: DESHABILITADOS" -ForegroundColor Red
        Write-Host "   Usando: Sistema de copias optimizado" -ForegroundColor Yellow
        Write-Host "   Para mejorar rendimiento:" -ForegroundColor Cyan
        Write-Host "   1. Ejecutar PowerShell como Administrador" -ForegroundColor Cyan
        Write-Host "   2. Ejecutar: fsutil behavior set SymlinkEvaluation L2L:1 L2R:1 R2L:1 R2R:1" -ForegroundColor Cyan
        Write-Host "   3. Reiniciar PowerShell y ejecutar: nvm migrate" -ForegroundColor Cyan
    }
}

# Función para verificar permisos de junction points
function Test-JunctionPermissions {
    try {
        $testDir = "$NVM_DIR\.junction_test"

        # Crear directorio de prueba
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null

        # Crear subdirectorio de prueba
        $subDir = "$testDir\subdir"
        New-Item -ItemType Directory -Path $subDir -Force | Out-Null

        # Intentar crear junction point usando cmd
        $junctionCmd = "cmd /c mklink /j `"$testDir\junction`" `"$subDir`""
        $result = Invoke-Expression $junctionCmd 2>&1

        # Verificar que el junction se creó
        $isJunction = Test-Path "$testDir\junction"

        # Limpiar archivos de prueba
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue

        return $isJunction
    } catch {
        # Limpiar archivos de prueba en caso de error
        if (Test-Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
}

# Función para crear junction point como alternativa
function Create-JunctionFallback {
    param([string]$Version)

    $currentDir = "$NVM_DIR\current"
    $versionDir = "$NVM_DIR\$Version"

    try {
        # Limpiar directorio current si existe
        if (Test-Path $currentDir) {
            Remove-Item -Path $currentDir -Recurse -Force
        }

        # Crear junction point usando cmd
        $junctionCmd = "cmd /c mklink /j `"$currentDir`" `"$versionDir`""
        $result = Invoke-Expression $junctionCmd 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Junction point creado: $currentDir -> $versionDir" -ForegroundColor Green
            Write-Host "Cambios de versión ahora son casi instantáneos!" -ForegroundColor Green
        } else {
            throw "Error al crear junction point: $result"
        }

    } catch {
        Write-Host "No se pudo crear junction point: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Usando sistema de copias como último recurso..." -ForegroundColor Yellow
        Create-CopyFallback $Version
    }
}

# Función para crear sistema de copias optimizado
function Create-CopyFallback {
    param([string]$Version)

    $currentDir = "$NVM_DIR\current"
    $versionDir = "$NVM_DIR\$Version"

    # Crear directorio current si no existe
    if (!(Test-Path $currentDir)) {
        New-Item -ItemType Directory -Path $currentDir -Force | Out-Null
    }

    # Verificar si ya está usando la versión correcta (optimización)
    $currentVersionFile = "$currentDir\.nvm_version"
    $needsUpdate = $true

    if (Test-Path $currentVersionFile) {
        try {
            $currentVersion = Get-Content $currentVersionFile -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
            if ($currentVersion -eq $Version) {
                $needsUpdate = $false
                Write-Host "Versión $Version ya está activa (sin cambios necesarios)" -ForegroundColor Green
            }
        } catch {
            # Ignorar errores de lectura
        }
    }

    if ($needsUpdate) {
        Write-Host "Copiando archivos de Node.js $Version..." -ForegroundColor Cyan

        # Limpiar directorio current (excepto archivos de control)
        Get-ChildItem -Path $currentDir | Where-Object { $_.Name -ne ".nvm_version" } | Remove-Item -Recurse -Force

        # Copiar archivos de manera optimizada (solo archivos modificados)
        $items = Get-ChildItem -Path $versionDir
        $totalItems = $items.Count
        $processed = 0

        foreach ($item in $items) {
            $targetPath = Join-Path $currentDir $item.Name
            $sourcePath = $item.FullName

            if ($item.PSIsContainer) {
                # Para directorios, verificar si existen y son diferentes
                if (!(Test-Path $targetPath)) {
                    Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
                }
            } else {
                # Para archivos, verificar si existen y son diferentes
                $needsCopy = $true
                if (Test-Path $targetPath) {
                    try {
                        $sourceHash = Get-FileHash $sourcePath -Algorithm MD5
                        $targetHash = Get-FileHash $targetPath -Algorithm MD5
                        if ($sourceHash.Hash -eq $targetHash.Hash) {
                            $needsCopy = $false
                        }
                    } catch {
                        # Si hay error al calcular hash, copiar de todas formas
                    }
                }

                if ($needsCopy) {
                    Copy-Item -Path $sourcePath -Destination $targetPath -Force
                }
            }

            $processed++
            if ($processed % 5 -eq 0) {
                Write-Host "  Progreso: $processed / $totalItems archivos..." -ForegroundColor Gray
            }
        }

        # Guardar marca de versión
        $Version | Out-File -FilePath $currentVersionFile -Encoding UTF8 -NoNewline

        Write-Host "Archivos copiados exitosamente" -ForegroundColor Green
    }
}