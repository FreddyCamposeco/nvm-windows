# nvm-versions.ps1 - Funciones de gestión de versiones de NVM

# Función para resolver aliases y versiones
function Resolve-Version {
    param([string]$Version)

    # Si ya es una versión completa, devolver normalizada
    if ($Version -match '^v?\d+\.\d+\.\d+$') {
        if ($Version -notlike 'v*') {
            return "v$Version"
        }
        return $Version
    }

    # Obtener versiones remotas
    try {
        $versions = Get-NvmVersionsWithCache
    }
    catch {
        Write-NvmError "Error al obtener versiones remotas: $($_.Exception.Message)"
        return $null
    }

    switch ($Version.ToLower()) {
        "latest" {
            return $versions[0].version
        }
        "lts" {
            $ltsVersion = $versions | Where-Object { $_.lts } | Select-Object -First 1
            if ($ltsVersion) {
                return $ltsVersion.version
            }
            else {
                Write-NvmError "No se encontró una versión LTS"
                return $null
            }
        }
        default {
            # Verificar si es un nombre de LTS (ej. "jod")
            $ltsVersion = $versions | Where-Object { $_.lts -and $_.lts.ToLower() -eq $Version.ToLower() } | Select-Object -First 1
            if ($ltsVersion) {
                return $ltsVersion.version
            }
            else {
                Write-NvmError "Alias o versión '$Version' no reconocido. Usa 'latest', 'lts', un nombre de LTS (ej. 'jod'), o una versión específica (ej. '18.19.0')"
                return $null
            }
        }
    }
}

# Función para obtener versiones remotas con caché
function Get-NvmVersionsWithCache {
    $cacheFile = "$NVM_DIR\.version_cache.json"
    $cacheDuration = [TimeSpan]::FromMinutes($NVM_CACHE_DURATION_MINUTES)

    # Verificar si el caché existe y no está expirado
    if ((Test-Path $cacheFile) -and ((Get-Date) - (Get-Item $cacheFile).LastWriteTime) -lt $cacheDuration) {
        try {
            $cachedData = Get-Content $cacheFile -Raw -Encoding UTF8 | ConvertFrom-Json
            return $cachedData
        }
        catch {
            # Si hay error leyendo el caché, continuar con descarga
        }
    }

    # Obtener versiones desde la web
    try {
        $response = Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -ErrorAction Stop
        $versions = $response.Content | ConvertFrom-Json

        # Filtrar solo versiones que tienen archivos para Windows
        $versions = $versions | Where-Object {
            $version = $_.version -replace '^v', ''
            $url = "https://nodejs.org/dist/$($_.version)/node-$($_.version)-win-$ARCH.zip"
            try {
                $null = Invoke-WebRequest -Uri $url -Method Head -ErrorAction Stop -TimeoutSec 5
                $true
            }
            catch {
                $false
            }
        }

        # Guardar en caché
        try {
            $versions | ConvertTo-Json -Depth 10 | Out-File -FilePath $cacheFile -Encoding UTF8 -Force
        }
        catch {
            # Ignorar errores de guardado de caché
        }

        return $versions
    }
    catch {
        throw "Error al obtener versiones desde nodejs.org: $($_.Exception.Message)"
    }
}

# Función para forzar actualización del caché de versiones
function Update-NvmVersionCache {
    $cacheFile = "$NVM_DIR\.version_cache.json"

    try {
        Write-Output "Actualizando caché de versiones..."
        $response = Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -ErrorAction Stop
        $versions = $response.Content | ConvertFrom-Json

        # Filtrar versiones con archivos Windows disponibles
        $filteredVersions = @()
        $totalVersions = $versions.Count
        $processed = 0

        foreach ($version in $versions) {
            $processed++
            $versionNum = $version.version -replace '^v', ''
            $url = "https://nodejs.org/dist/$($version.version)/node-$($version.version)-win-$ARCH.zip"

            try {
                $null = Invoke-WebRequest -Uri $url -Method Head -ErrorAction Stop -TimeoutSec 2
                $filteredVersions += $version
            }
            catch {
                # Versión no disponible para Windows, omitir
            }

            # Mostrar progreso cada 50 versiones
            if ($processed % 50 -eq 0) {
                Write-Host "." -NoNewline
            }
        }

        # Guardar en caché
        $filteredVersions | ConvertTo-Json -Depth 10 | Out-File -FilePath $cacheFile -Encoding UTF8 -Force

        Write-Output ""
        Write-Output "Caché actualizado con $($filteredVersions.Count) versiones"
    }
    catch {
        Write-NvmError "Error al actualizar caché: $($_.Exception.Message)"
    }
}

# Función para guardar caché de versiones instaladas
function Save-InstalledVersionsCache {
    $cacheFile = "$NVM_DIR\.installed_versions_cache.json"

    try {
        $installedVersions = Get-ChildItem -Path $NVM_DIR -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^v\d+\.\d+\.\d+$' } |
            Select-Object -ExpandProperty Name |
            Sort-Object { [version]($_ -replace '^v', '') } -Descending

        $cacheData = @{
            versions = $installedVersions
            timestamp = (Get-Date).ToString("o")
        }

        $cacheData | ConvertTo-Json | Out-File -FilePath $cacheFile -Encoding UTF8 -Force
    }
    catch {
        # Ignorar errores de guardado de caché
    }
}

# Función para obtener versiones instaladas desde caché
function Get-InstalledVersionsFromCache {
    $cacheFile = "$NVM_DIR\.installed_versions_cache.json"
    $cacheDuration = [TimeSpan]::FromMinutes($NVM_INSTALLED_CACHE_DURATION_MINUTES)

    # Verificar si el caché existe y no está expirado
    if ((Test-Path $cacheFile) -and ((Get-Date) - (Get-Item $cacheFile).LastWriteTime) -lt $cacheDuration) {
        try {
            $cachedData = Get-Content $cacheFile -Raw -Encoding UTF8 | ConvertFrom-Json
            return $cachedData.versions
        }
        catch {
            # Si hay error leyendo el caché, continuar con escaneo
        }
    }

    # Obtener versiones instaladas del sistema de archivos
    try {
        $installedVersions = Get-ChildItem -Path $NVM_DIR -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^v\d+\.\d+\.\d+$' } |
            Select-Object -ExpandProperty Name |
            Sort-Object { [version]($_ -replace '^v', '') } -Descending

        # Update cache
        Save-InstalledVersionsCache

        return $installedVersions
    }
    catch {
        return @()
    }
}

# Función para obtener la versión actual de Node.js activa
function Get-NvmCurrentVersion {
    # Primero intentar con enlaces simbólicos en current\bin
    $currentNodePath = "$NVM_DIR\current\bin\node.exe"
    if (Test-Path $currentNodePath) {
        try {
            $version = & $currentNodePath --version 2>$null
            if ($version) {
                return $version.Trim()
            }
        }
        catch {
            # Ignorar errores y continuar
        }
    }

    # Si falla, intentar ejecutar node directamente (para compatibilidad)
    try {
        $version = & node --version 2>$null
        if ($version) {
            return $version.Trim()
        }
    }
    catch {
        # Ignorar errores
    }

    return $null
}

# Función para obtener versión del sistema
function Get-NvmSystemVersion {
    # Buscar instalación de Node.js a nivel del sistema (fuera de nvm)
    $systemPaths = $env:PATH -split ';' | Where-Object {
        $_ -and $_ -notlike "*$NVM_DIR*" -and (Test-Path (Join-Path $_ "node.exe"))
    }

    foreach ($path in $systemPaths) {
        try {
            $nodeExe = Join-Path $path "node.exe"
            if (Test-Path $nodeExe) {
                $version = & $nodeExe --version 2>$null
                if ($version) {
                    return $version.Trim()
                }
            }
        }
        catch {
            # Continuar buscando
        }
    }

    return $null
}

# Función para obtener versión del .nvmrc
function Get-NvmrcVersion {
    $nvmrcPath = Find-NodeVersionFile
    if (-not $nvmrcPath) {
        return $null
    }

    try {
        $version = Get-Content $nvmrcPath -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
        return $version
    }
    catch {
        return $null
    }
}

# Función para encontrar archivo de versión de Node
function Find-NodeVersionFile {
    $currentDir = Get-Location
    $dir = $currentDir.Path

    while ($dir -and (Test-Path $dir)) {
        $nvmrcPath = Join-Path $dir ".nvmrc"
        if (Test-Path $nvmrcPath) {
            return $nvmrcPath
        }

        $nodeVersionPath = Join-Path $dir ".node-version"
        if (Test-Path $nodeVersionPath) {
            return $nodeVersionPath
        }

        # Subir al directorio padre
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) {
            break
        }
        $dir = $parent
    }

    return $null
}

# Función para mostrar versiones con colores (equivalente a nvm list)
function Show-NvmVersions {
    <#
    .SYNOPSIS
        Shows Node.js versions in a compact, informative format
    .DESCRIPTION
        Displays versions with indicators for current, installed, and project config
    #>
    param(
        [string]$Pattern = "",
        [switch]$Compact
    )

    try {
        $versions = Get-NvmVersionsWithCache
    }
    catch {
        Write-NvmError "No se pudo obtener información de versiones"
        return
    }

    # Get current version
    $currentVersion = Get-NvmCurrentVersion

    # Get installed versions
    $installedVersions = Get-InstalledVersionsFromCache

    # Get latest version
    $latestVersion = $versions[0].version

    # Create a mapping of installed versions to LTS names
    $installedLtsMapping = @{}
    foreach ($installed in $installedVersions) {
        $remoteVersion = $versions | Where-Object { $_.version -eq $installed }
        if ($remoteVersion -and $remoteVersion.lts) {
            $installedLtsMapping[$installed] = $remoteVersion.lts
        }
    }

    # Get latest version for each LTS line
    $latestLtsVersions = $versions | Where-Object { $_.lts } | Group-Object -Property lts | ForEach-Object {
        $_.Group | Sort-Object { [version]($_.version -replace '^v', '') } -Descending | Select-Object -First 1
    }

    # LTS versions (latest of each line)
    $ltsVersions = $latestLtsVersions

    # Get some recent non-LTS versions (last 3 major versions before latest)
    $latestMajor = [version]($latestVersion -replace '^v', '') | Select-Object -ExpandProperty Major
    $nonLtsVersions = @()
    for ($i = 1; $i -le 3; $i++) {
        $major = $latestMajor - $i
        $version = $versions | Where-Object { $_ -match "^v$major\." } | Select-Object -First 1
        if ($version) {
            $nonLtsVersions += $version
        }
    }

    # Get default version
    $defaultVersion = [Environment]::GetEnvironmentVariable("nvm_default_version", "User")
    if ($defaultVersion -and -not $defaultVersion.StartsWith('v')) {
        $defaultVersion = "v$defaultVersion"
    }

    # Get .nvmrc version
    $nvmrcVersion = Get-NvmrcVersion
    if ($nvmrcVersion -and -not $nvmrcVersion.StartsWith('v') -and $nvmrcVersion -match '^\d') {
        $nvmrcVersion = "v$nvmrcVersion"
    }

    # Function to normalize version for comparison
    function Normalize-Version {
        param([string]$Version)
        if ($Version -and -not $Version.StartsWith('v') -and $Version -match '^\d') {
            return "v$Version"
        }
        return $Version
    }

    # Function to format version to v#.#.# without padding
    function Format-Version {
        param([string]$Version)

        # If version is not numeric (like 'lts', 'latest'), return as-is
        if ($Version -notmatch '^\d') {
            return $Version
        }

        # Remove 'v' prefix if present
        $cleanVersion = $Version -replace '^v', ''
        # Split version parts
        $parts = $cleanVersion -split '\.'
        # Ensure we have 3 parts, pad with zeros if needed
        while ($parts.Length -lt 3) {
            $parts += "0"
        }
        # Keep original format without zero padding
        $major = $parts[0]
        $minor = $parts[1]
        $patch = $parts[2]
        # Return formatted version with 'v' prefix
        return "v$major.$minor.$patch"
    }

    # Normalize versions for comparison
    $currentVersion = Normalize-Version $currentVersion
    $defaultVersion = Normalize-Version $defaultVersion
    $latestVersion = Normalize-Version $latestVersion
    $nvmrcVersion = Normalize-Version $nvmrcVersion

    # Display versions
    Write-Host ""

    # Define total width based on compact mode
    $totalWidth = $Compact ? 20 : 27

    # Show system version if exists
    $systemVersion = Get-NvmSystemVersion
    if ($systemVersion) {
        $normalizedSystemVersion = Normalize-Version $systemVersion
        $isInstalled = $true  # System version is always "installed" in system
        $indicator = if ($currentVersion -eq $normalizedSystemVersion) { "▶ " } else { " " }
        $label = "system:"
        $padding = " " * (14 - $label.Length)
        $formattedVersion = Format-Version $systemVersion
        $lineContent = "$indicator $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length
        $finalSpaces = " " * [Math]::Max(0, $spacesNeeded)

        # Color indicator
        if ($currentVersion -eq $normalizedSystemVersion) {
            Write-NvmColoredText "▶ " "G" -NoNewline
        }
        else {
            Write-Host " " -NoNewline
        }
        Write-NvmColoredText " $label$padding" "y" -NoNewline  # Amarillo para sistema
        Write-NvmColoredText "$formattedVersion" "y" -NoNewline
        Write-Host "$finalSpaces" -NoNewline
        Write-NvmColoredText "✓" "M"
    }

    # Show global version (always shown with →)
    $globalVersion = $defaultVersion
    if ($globalVersion) {
        $label = "global:"
        $padding = " " * (14 - $label.Length)  # Fixed padding for labels
        $formattedVersion = Format-Version $globalVersion
        $lineContent = "→ $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length
        $finalSpaces = " " * [Math]::Max(0, $spacesNeeded)

        # Color output: → in cyan, label in gray, version in cyan
        Write-NvmColoredText "→" "c" -NoNewline
        Write-NvmColoredText " $label$padding" "e" -NoNewline
        Write-NvmColoredText "$formattedVersion" "c" -NoNewline
        Write-Host "$finalSpaces "
    }

    # Show latest version
    if ($latestVersion) {
        $isInstalled = $installedVersions -contains $latestVersion
        $isCurrent = $currentVersion -eq $latestVersion
        $label = "latest:"
        $padding = " " * (14 - $label.Length)
        $formattedVersion = Format-Version $latestVersion
        $indicator = if ($isCurrent) { "▶ " } else { "  " }
        $lineContent = "$indicator $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length
        $finalSpaces = " " * [Math]::Max(0, $spacesNeeded)

        # Color indicator
        if ($isCurrent) {
            Write-NvmColoredText "▶ " "G" -NoNewline
        }
        else {
            Write-Host "  " -NoNewline
        }
        Write-NvmColoredText "$label$padding" "e" -NoNewline
        Write-NvmColoredText "$formattedVersion" "c" -NoNewline  # Cyan for latest
        Write-Host "$finalSpaces" -NoNewline
        if ($isInstalled) {
            Write-NvmColoredText "✓" "G"
        }
        else {
            Write-Host " "
        }
    }

    # LTS versions
    foreach ($lts in $ltsVersions) {
        $normalizedLtsVersion = Normalize-Version $lts.version
        $isInstalled = $installedVersions -contains $normalizedLtsVersion
        $isCurrent = $currentVersion -eq $normalizedLtsVersion
        $name = $lts.lts.ToLower()
        $label = "lts/$name`:" 
        $padding = " " * (14 - $label.Length)
        $formattedVersion = Format-Version $lts.version
        $indicator = if ($isCurrent) { "▶ " } else { "  " }
        $lineContent = "$indicator $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length
        $finalSpaces = " " * [Math]::Max(0, $spacesNeeded)

        # Color indicator
        if ($isCurrent) {
            Write-NvmColoredText "▶ " "G" -NoNewline
        }
        else {
            Write-Host "  " -NoNewline
        }
        Write-NvmColoredText "$label$padding" "y" -NoNewline  # Yellow for LTS labels
        Write-NvmColoredText "$formattedVersion" "e" -NoNewline  # Gray for all LTS versions (consistent with HTML)
        Write-Host "$finalSpaces" -NoNewline
        if ($isInstalled) {
            Write-NvmColoredText "✓" "G"
        }
        else {
            Write-Host " "
        }
    }

    # .nvmrc version (if exists)
    if ($nvmrcVersion) {
        # Resolver la versión del .nvmrc (convertir aliases como 'lts' a versiones específicas)
        $resolvedNvmrcVersion = Resolve-Version $nvmrcVersion
        if ($resolvedNvmrcVersion) {
            $normalizedNvmrcVersion = Normalize-Version $resolvedNvmrcVersion
            $isInstalled = $installedVersions -contains $normalizedNvmrcVersion
            $isCurrent = $currentVersion -eq $normalizedNvmrcVersion
        } else {
            $isInstalled = $false
            $isCurrent = $false
        }

        $label = ".nvmrc:"
        $padding = " " * (15 - $label.Length)  # Extra space for .nvmrc since indicator is 1 char
        $formattedVersion = Format-Version $nvmrcVersion
        $indicator = if ($isCurrent) { "▶" } else { "ϟ" }
        $lineContent = "$indicator$label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length
        $finalSpaces = " " * [Math]::Max(0, $spacesNeeded)

        # Color indicator
        if ($isCurrent) {
            Write-NvmColoredText "▶" "Y" -NoNewline
        }
        else {
            Write-NvmColoredText "ϟ" "Y" -NoNewline
        }
        Write-NvmColoredText "$label$padding" "m" -NoNewline  # Purple for .nvmrc label
        Write-NvmColoredText "$formattedVersion" "m" -NoNewline  # Purple for .nvmrc version
        Write-Host "$finalSpaces" -NoNewline
        if ($isInstalled) {
            Write-NvmColoredText "✓" "G"  # Green checkmark if installed
        }
        else {
            Write-NvmColoredText "✗" "R"  # Red X if not installed
        }
    }

    # Non-LTS versions - show only installed non-LTS versions
    $ltsVersionStrings = $ltsVersions | Select-Object -ExpandProperty version
    $installedNonLtsVersions = $installedVersions | Where-Object { $_ -notin $ltsVersionStrings -and $_ -ne $nvmrcVersion -and $_ -match "^v\d" } | ForEach-Object {
        $ver = $_
        $major = [version]($ver -replace '^v', '') | Select-Object -ExpandProperty Major
        @{
            Version = $ver
            Major   = $major
        }
    } | Group-Object Major | ForEach-Object { $_.Group | Sort-Object { [version]($_.Version -replace '^v', '') } -Descending | Select-Object -First 1 } | Sort-Object { [version]($_.Version -replace '^v', '') } -Descending | Select-Object -First 3

    if ($installedNonLtsVersions.Count -gt 0 -and -not $Compact) {
        Write-Host ""
        Write-Host "Installed (non-LTS):"
        foreach ($versionInfo in $installedNonLtsVersions) {
            $normalizedVersion = Normalize-Version $versionInfo.Version
            $indicator = if ($currentVersion -eq $normalizedVersion) { 
                "▶" 
            }
            elseif ($nvmrcVersion -and $normalizedVersion -eq (Normalize-Version $nvmrcVersion)) {
                "ϟ"
            }
            else { 
                " " 
            }
            $label = "v$($versionInfo.Major).x`:" 
            $padding = " " * (14 - $label.Length)
            $formattedVersion = Format-Version $versionInfo.Version
            $lineContent = "$indicator $label$padding$formattedVersion"
            $spacesNeeded = $totalWidth - $lineContent.Length - 1  # Always show ✓ for installed versions
            $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

            # Color indicator
            if ($currentVersion -eq $normalizedVersion) {
                Write-NvmColoredText "▶" "G" -NoNewline
            }
            elseif ($nvmrcVersion -and $normalizedVersion -eq (Normalize-Version $nvmrcVersion)) {
                Write-NvmColoredText "ϟ" "Y" -NoNewline
            }
            else {
                Write-Host " " -NoNewline
            }
            Write-NvmColoredText " $label$padding" "e" -NoNewline
            Write-NvmColoredText "$formattedVersion" "e" -NoNewline
            Write-Host "$finalSpaces" -NoNewline
            Write-NvmColoredText "✓" "M"
        }
    }

    Write-Host ""
}

# Función para mostrar versiones remotas
function Show-RemoteVersions {
    try {
        $versions = Get-NvmVersionsWithCache
        $versions | ForEach-Object { Write-Host $_.version }
    }
    catch {
        Write-NvmError "Failed to fetch remote versions: $($_.Exception.Message)"
    }
}