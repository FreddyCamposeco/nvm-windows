# nvm-use.ps1 - Funciones de cambio y gestión de versiones activas de NVM

# Función para cambiar a una versión específica de Node.js
function Use-Node {
    param(
        [string]$Version,
        [switch]$Quiet
    )

    if ([string]::IsNullOrWhiteSpace($Version)) {
        # Buscar .nvmrc
        $nvmrcVersion = Get-NvmrcVersion
        if ($nvmrcVersion) {
            if (-not $Quiet) {
                Write-Output "Encontrado .nvmrc con versión: $nvmrcVersion"
            }
            $Version = $nvmrcVersion
        }
        else {
            Write-NvmError "Versión es requerida. Uso: nvm use <versión>"
            return
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

    # Crear directorio current si no existe
    if (!(Test-Path $currentDir)) {
        New-Item -ItemType Directory -Path $currentDir -Force | Out-Null
    }

    # Limpiar directorio current
    Get-ChildItem -Path $currentDir | Remove-Item -Recurse -Force

    # Verificar si podemos crear enlaces simbólicos
    $canCreateSymlinks = Test-SymlinkPermissions

    if ($canCreateSymlinks) {
        Write-Host "Creando enlaces simbólicos para Node.js $Version..." -ForegroundColor Cyan

        # Crear enlaces simbólicos para archivos y directorios
        $items = Get-ChildItem -Path $versionDir
        foreach ($item in $items) {
            $targetPath = Join-Path $currentDir $item.Name
            $sourcePath = $item.FullName

            try {
                if ($item.PSIsContainer) {
                    # Crear enlace simbólico para directorios
                    New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath | Out-Null
                } else {
                    # Crear enlace simbólico para archivos
                    New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath | Out-Null
                }
            } catch {
                Write-Host "No se pudo crear enlace simbólico para $($item.Name): $($_.Exception.Message)" -ForegroundColor Red
                # Fallback: copiar el archivo/directorio
                if ($item.PSIsContainer) {
                    Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
                } else {
                    Copy-Item -Path $sourcePath -Destination $targetPath -Force
                }
            }
        }

        # Verificar enlaces creados
        $symlinks = Get-ChildItem -Path $currentDir | Where-Object { $_.LinkType -eq "SymbolicLink" }
        if ($symlinks.Count -gt 0) {
            Write-Host "Enlaces simbólicos creados: $($symlinks.Count) archivos/directorios" -ForegroundColor Green
        }
    } else {
        Write-Host "No hay permisos para crear enlaces simbólicos. Usando sistema de copias..." -ForegroundColor Red
        Write-Host "Copiando archivos de Node.js $Version..." -ForegroundColor Cyan

        # Fallback: Copiar archivos (método actual)
        $items = Get-ChildItem -Path $versionDir
        foreach ($item in $items) {
            $targetPath = Join-Path $currentDir $item.Name
            $sourcePath = $item.FullName

            if ($item.PSIsContainer) {
                Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
            } else {
                Copy-Item -Path $sourcePath -Destination $targetPath -Force
            }
        }
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
    Write-Host "Iniciando migración al sistema de enlaces simbólicos..." -ForegroundColor Cyan

    # Verificar permisos para enlaces simbólicos
    $canCreateSymlinks = Test-SymlinkPermissions

    if (-not $canCreateSymlinks) {
        Write-Host "No se detectaron permisos para crear enlaces simbólicos." -ForegroundColor Red
        Write-Host "Para habilitar enlaces simbólicos:" -ForegroundColor Yellow
        Write-Host "  1. Ejecutar PowerShell como Administrador" -ForegroundColor Cyan
        Write-Host "  2. Ejecutar: fsutil behavior set SymlinkEvaluation L2L:1 L2R:1 R2L:1 R2R:1" -ForegroundColor Cyan
        Write-Host "  3. Reiniciar PowerShell y ejecutar: nvm migrate" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Continuando con sistema de copias..." -ForegroundColor Yellow
        return
    }

    # Obtener versión actualmente activa
    $currentVersion = Get-NvmCurrentVersion
    if ($currentVersion) {
        try {
            Write-Host "Migrando versión $currentVersion a enlaces simbólicos..." -ForegroundColor Cyan
            Set-NvmSymlinks $currentVersion

            # Verificar que los enlaces se crearon correctamente
            $symlinks = Get-ChildItem -Path "$NVM_DIR\current" | Where-Object { $_.LinkType -eq "SymbolicLink" }
            if ($symlinks.Count -gt 0) {
                Write-Host "✅ Migración completada exitosamente!" -ForegroundColor Green
                Write-Host "Ahora usando enlaces simbólicos: $($symlinks.Count) archivos/directorios" -ForegroundColor Green
            } else {
                Write-Host "Los enlaces simbólicos no se crearon correctamente. Usando sistema de copias." -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Error durante la migración: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Revirtiendo a sistema de copias..." -ForegroundColor Yellow
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

    $items = Get-ChildItem -Path $currentDir
    $symlinks = $items | Where-Object { $_.LinkType -eq "SymbolicLink" }
    $regularFiles = $items | Where-Object { $_.LinkType -ne "SymbolicLink" -and -not $_.PSIsContainer }
    $directories = $items | Where-Object { $_.PSIsContainer }

    Write-Host "Estado del directorio current:" -ForegroundColor Cyan
    Write-Host "  📂 Total de elementos: $($items.Count)" -ForegroundColor Cyan
    Write-Host "  🔗 Enlaces simbólicos: $($symlinks.Count)" -ForegroundColor Green
    Write-Host "  📄 Archivos regulares: $($regularFiles.Count)" -ForegroundColor Yellow
    Write-Host "  📁 Directorios: $($directories.Count)" -ForegroundColor Magenta

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
    Write-Host ""
    if ($canCreateSymlinks) {
        Write-Host "✅ Permisos para enlaces simbólicos: HABILITADOS" -ForegroundColor Green
    } else {
        Write-Host "❌ Permisos para enlaces simbólicos: DESHABILITADOS" -ForegroundColor Red
        Write-Host "   Para habilitar:" -ForegroundColor Yellow
        Write-Host "   1. Ejecutar PowerShell como Administrador" -ForegroundColor Cyan
        Write-Host "   2. Ejecutar: fsutil behavior set SymlinkEvaluation L2L:1 L2R:1 R2L:1 R2R:1" -ForegroundColor Cyan
        Write-Host "   3. Reiniciar PowerShell" -ForegroundColor Cyan
    }
}