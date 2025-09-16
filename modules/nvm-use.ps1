# nvm-use.ps1 - Funciones de cambio y gestión de versiones activas de NVM

# Función para cambiar a una versión específica de Node.js
function Use-Node {
    param([string]$Version)

    if ([string]::IsNullOrWhiteSpace($Version)) {
        # Buscar .nvmrc
        $nvmrcVersion = Get-NvmrcVersion
        if ($nvmrcVersion) {
            Write-Output "Encontrado .nvmrc con versión: $nvmrcVersion"
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
    if ($resolvedVersion -ne $Version -and $Version -notmatch '^v?\d+\.\d+\.\d+$') {
        Write-Output "Usando alias '$Version' -> '$resolvedVersion'"
    }

    # Verificar si hay un alias guardado como archivo (para compatibilidad)
    $aliasPath = "$NVM_DIR\alias\$Version"
    if ((Test-Path $aliasPath) -and ($resolvedVersion -eq $Version)) {
        try {
            $fileAliasVersion = Get-Content $aliasPath -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
            if ($fileAliasVersion -and $fileAliasVersion -ne $Version) {
                $resolvedVersion = $fileAliasVersion
                Write-Output "Usando alias guardado '$Version' -> '$resolvedVersion'"
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
    }
    catch {
        Write-NvmError "Error al crear enlaces simbólicos: $($_.Exception.Message)"
        return
    }

    # Establecer variable de entorno para compatibilidad con Starship y otros tools
    $env:NODE_VERSION = $resolvedVersion

    # Guardar la versión activa para persistencia entre sesiones
    Set-NvmActiveVersion $resolvedVersion

    Write-Output "Ahora usando Node.js $resolvedVersion"
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

    # Copiar archivos de la versión seleccionada (enfoque simple sin enlaces simbólicos)
    $items = Get-ChildItem -Path $versionDir
    foreach ($item in $items) {
        $targetPath = Join-Path $currentDir $item.Name
        $sourcePath = $item.FullName

        if ($item.PSIsContainer) {
            # Copiar directorios recursivamente
            Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
        }
        else {
            # Copiar archivos
            Copy-Item -Path $sourcePath -Destination $targetPath -Force
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
    Write-Output "Migrando al sistema de enlaces simbólicos..."

    # Obtener versión actualmente activa
    $currentVersion = Get-NvmCurrentVersion
    if ($currentVersion) {
        try {
            Set-NvmSymlinks $currentVersion
            Write-Output "Migración completada. Ahora usando enlaces simbólicos."
        }
        catch {
            Write-NvmError "Error durante la migración: $($_.Exception.Message)"
        }
    }
    else {
        Write-NvmError "No se pudo determinar la versión actual para migrar"
    }
}