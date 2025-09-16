# nvm-install.ps1 - Funciones de instalación y desinstalación de NVM

# Función para instalar Node.js
function Install-Node {
    param([string]$Version)

    if ([string]::IsNullOrWhiteSpace($Version)) {
        Write-NvmError "Versión es requerida. Uso: nvm install <versión>"
        return
    }

    # Resolver alias o versión
    $resolvedVersion = Resolve-Version $Version
    if (-not $resolvedVersion) {
        return
    }

    $Version = $resolvedVersion

    $url = "$NODE_MIRROR/$Version/node-$Version-win-$ARCH.zip"
    $zipPath = "$NVM_DIR\temp\node-$Version-win-$ARCH.zip"
    $extractPath = "$NVM_DIR\$Version"

    # Verificar si ya está instalada
    if (Test-Path $extractPath) {
        Write-NvmError "Versión $Version ya está instalada"
        return
    }

    # Crear directorios necesarios
    if (!(Test-Path $NVM_DIR)) {
        New-Item -ItemType Directory -Path $NVM_DIR -Force | Out-Null
    }
    if (!(Test-Path "$NVM_DIR\temp")) {
        New-Item -ItemType Directory -Path "$NVM_DIR\temp" -Force | Out-Null
    }

    try {
        Write-Output "Descargando Node.js $Version..."
        
        # Obtener información del archivo antes de descargar
        try {
            $response = Invoke-WebRequest -Uri $url -Method Head -ErrorAction Stop
            $fileSize = [math]::Round($response.ContentLength / 1MB, 2)
            Write-Output "Tamaño aproximado: ${fileSize}MB"
        }
        catch {
            Write-Output "No se pudo obtener información del tamaño del archivo"
        }

        # Descargar con progreso visible
        $ProgressPreference = 'Continue'  # Asegurar que se muestre progreso
        Invoke-WebRequest -Uri $url -OutFile $zipPath -ErrorAction Stop
        
        Write-Output "Descarga completada!"

        # Verificar que el archivo se descargó correctamente
        if (!(Test-Path $zipPath)) {
            throw "Error: El archivo descargado no se encuentra en $zipPath"
        }

        $downloadedSize = (Get-Item $zipPath).Length
        $downloadedMB = [math]::Round($downloadedSize / 1MB, 2)
        Write-Output "Archivo descargado: ${downloadedMB}MB"

        Write-Output "Extrayendo archivos..."
        
        # Extraer directamente al directorio final
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force -ErrorAction Stop
        
        Write-Output "Extracción completada!"

        # Verificar si se creó un subdirectorio y mover contenido si es necesario
        $items = Get-ChildItem -Path $extractPath
        if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
            # Hay un solo subdirectorio, mover su contenido
            $subDirPath = $items[0].FullName
            $tempItems = Get-ChildItem -Path $subDirPath
            foreach ($item in $tempItems) {
                Move-Item -Path $item.FullName -Destination $extractPath -Force
            }
            # Eliminar el subdirectorio vacío
            Remove-Item $subDirPath -Force
        }

        Remove-Item $zipPath -Force
        Write-Output "Node.js $Version instalado en $extractPath"

        # Actualizar cache de versiones instaladas
        Save-InstalledVersionsCache
    }
    catch {
        Write-NvmError "Error durante la instalación: $($_.Exception.Message)"
        # Limpiar archivos en caso de error
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
    }
}

# Función para desinstalar Node.js
function Uninstall-Node {
    param(
        [string]$Version,
        [switch]$Force
    )

    if ([string]::IsNullOrWhiteSpace($Version)) {
        Write-NvmError "Versión es requerida. Uso: nvm uninstall <versión> [--force]"
        return
    }

    # Resolver alias o versión
    $resolvedVersion = Resolve-Version $Version
    if (-not $resolvedVersion) {
        return
    }

    $Version = $resolvedVersion

    $installPath = "$NVM_DIR\$Version"

    # Verificar si está instalada
    if (!(Test-Path $installPath)) {
        Write-NvmError "Versión $Version no está instalada"
        return
    }

    # Verificar si es la versión actualmente activa
    $currentVersion = Get-NvmCurrentVersion
    if ($currentVersion -eq $Version) {
        if (-not $Force) {
            Write-NvmError "Versión $Version está actualmente activa. Usa --force para forzar la desinstalación"
            return
        }
        Write-Output "ADVERTENCIA: Desinstalando versión actualmente activa ($Version)"
    }

    # Confirmar desinstalación
    if (-not $Force) {
        $confirmation = Read-Host "¿Estás seguro de que quieres desinstalar Node.js $Version? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Output "Desinstalación cancelada"
            return
        }
    }

    try {
        Remove-Item $installPath -Recurse -Force
        Write-Output "Node.js $Version desinstalado correctamente"

        # Si era la versión activa, intentar cambiar a otra versión disponible
        if ($currentVersion -eq $Version) {
            $installedVersions = Get-InstalledVersionsFromCache
            $remainingVersions = $installedVersions | Where-Object { $_ -ne $Version }
            if ($remainingVersions) {
                $fallbackVersion = $remainingVersions[0]
                Write-Output "Cambiando automáticamente a $fallbackVersion"
                Use-Node $fallbackVersion
            }
        }

        # Actualizar cache de versiones instaladas
        Save-InstalledVersionsCache
    }
    catch {
        Write-NvmError "Error durante la desinstalación: $($_.Exception.Message)"
    }
}

# Función para reintentar descarga con backoff exponencial
function Get-VersionsWithRetry {
    param([int]$MaxRetries = 3)

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            return Invoke-WebRequest -Uri "$NODE_MIRROR/index.json" -ErrorAction Stop | ConvertFrom-Json
        }
        catch {
            if ($i -eq $MaxRetries - 1) { throw }
            Start-Sleep -Seconds ([Math]::Pow(2, $i))  # Backoff exponencial
        }
    }
}

# Función para validar versiones .nvmrc
function Test-NvmrcVersion {
    param([string]$Version)

    if ([string]::IsNullOrWhiteSpace($Version)) { return $false }

    # Verificar formato básico
    if ($Version -notmatch '^v?\d+\.\d+\.\d+$|^lts|^latest$|^[a-zA-Z]+$') {
        return $false
    }

    # Si es una versión específica, verificar que exista remotamente
    if ($Version -match '^v?\d+\.\d+\.\d+$') {
        try {
            $versions = Get-NvmVersionsWithCache
            $normalized = $Version -replace '^v', ''
            $exists = $versions | Where-Object { $_.version -eq "v$normalized" }
            return $exists -ne $null
        }
        catch {
            return $true  # Si no podemos verificar, asumir válido
        }
    }

    return $true
}