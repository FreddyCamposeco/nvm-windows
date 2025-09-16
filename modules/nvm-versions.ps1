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

    # Obtener versiones desde la web (sin verificación de archivos cuando no hay caché)
    try {
        Write-Host "Creando caché de versiones..." -ForegroundColor Yellow
        Write-Progress -Activity "Descargando índice de versiones" -Status "Conectando a nodejs.org..." -PercentComplete 0
        
        $response = Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -ErrorAction Stop
        Write-Progress -Activity "Descargando índice de versiones" -Status "Procesando datos..." -PercentComplete 50
        
        $versions = $response.Content | ConvertFrom-Json
        Write-Progress -Activity "Descargando índice de versiones" -Status "Completado" -PercentComplete 100 -Completed

        # Nota: No filtramos por archivos Windows para acelerar la creación inicial del caché
        # Las versiones sin archivos Windows serán manejadas en el momento de instalación

        # Guardar en caché
        try {
            $versions | ConvertTo-Json -Depth 10 | Out-File -FilePath $cacheFile -Encoding UTF8 -Force
            Write-Host "Caché creado exitosamente." -ForegroundColor Green
        }
        catch {
            Write-Warning "No se pudo guardar el caché, pero continuando con los datos descargados."
        }

        return $versions
    }
    catch {
        Write-Progress -Activity "Descargando índice de versiones" -Status "Error" -Completed
        throw "Error al obtener versiones desde nodejs.org: $($_.Exception.Message)"
    }
}

# Función para forzar actualización del caché de versiones
function Update-NvmVersionCache {
    $cacheFile = "$NVM_DIR\.version_cache.json"

    try {
        Write-Output "Actualizando caché de versiones..."
        Write-Progress -Activity "Actualizando caché de versiones" -Status "Descargando índice..." -PercentComplete 0
        
        $response = Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -ErrorAction Stop
        Write-Progress -Activity "Actualizando caché de versiones" -Status "Procesando datos..." -PercentComplete 25
        
        $versions = $response.Content | ConvertFrom-Json
        Write-Progress -Activity "Actualizando caché de versiones" -Status "Verificando archivos Windows..." -PercentComplete 50

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
                $percent = [math]::Round(($processed / $totalVersions) * 50 + 50, 0)
                Write-Progress -Activity "Actualizando caché de versiones" -Status "Verificando archivos Windows... ($processed/$totalVersions)" -PercentComplete $percent
                Write-Host "." -NoNewline
            }
        }

        Write-Progress -Activity "Actualizando caché de versiones" -Status "Guardando caché..." -PercentComplete 90
        
        # Guardar caché filtrado
        $filteredVersions | ConvertTo-Json -Depth 10 | Out-File -FilePath $cacheFile -Encoding UTF8 -Force
        Write-Progress -Activity "Actualizando caché de versiones" -Status "Completado" -PercentComplete 100 -Completed
        
        Write-Output "Caché actualizado con $($filteredVersions.Count) versiones"
    }
    catch {
        Write-Progress -Activity "Actualizando caché de versiones" -Status "Error" -Completed
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
    # Primero intentar con archivos copiados en current
    $currentNodePath = "$NVM_DIR\current\node.exe"
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
        $isInstalled = $true  # System version is siempre "instalada" en el sistema
        $isCurrent = $currentVersion -eq $normalizedSystemVersion

        Format-NvmVersionLine -Type 'system' -Label 'system:' -Version $systemVersion -IsInstalled $isInstalled -IsCurrent $isCurrent -Compact:$Compact
    }

    # Show global version (always shown with →)
    $globalVersion = $defaultVersion
    if ($globalVersion) {
        Format-NvmVersionLine -Type 'global' -Label 'global:' -Version $globalVersion -IsInstalled $false -IsCurrent $false -Compact:$Compact
    }

    # Show latest version
    if ($latestVersion) {
        $isInstalled = $installedVersions -contains $latestVersion
        $isCurrent = $currentVersion -eq $latestVersion

        Format-NvmVersionLine -Type 'latest' -Label 'latest:' -Version $latestVersion -IsInstalled $isInstalled -IsCurrent $isCurrent -Compact:$Compact
    }

    # LTS versions
    foreach ($lts in $ltsVersions) {
        $normalizedLtsVersion = Normalize-Version $lts.version
        $isInstalled = $installedVersions -contains $normalizedLtsVersion
        $isCurrent = $currentVersion -eq $normalizedLtsVersion
        $name = $lts.lts.ToLower()
        $label = "lts/$name`:"

        Format-NvmVersionLine -Type 'lts' -Label $label -Version $lts.version -IsInstalled $isInstalled -IsCurrent $isCurrent -Compact:$Compact
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

        Format-NvmVersionLine -Type 'nvmrc' -Label '.nvmrc:' -Version $nvmrcVersion -IsInstalled $isInstalled -IsCurrent $isCurrent -Compact:$Compact
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
            $isCurrent = $currentVersion -eq $normalizedVersion
            $label = "v$($versionInfo.Major).x`:"

            Format-NvmVersionLine -Type 'non-lts' -Label $label -Version $versionInfo.Version -IsInstalled $true -IsCurrent $isCurrent -Compact:$Compact
        }
    }

    Write-Host ""
}

# Función para formatear mensajes informativos
function Format-NvmInfoMessage {
    <#
    .SYNOPSIS
        Formats informational messages with consistent styling
    .PARAMETER Message
        The message to format
    .PARAMETER Type
        Type of message: 'info', 'success', 'warning', 'error'
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('info', 'success', 'warning', 'error')]
        [string]$Type = 'info'
    )

    switch ($Type) {
        'info' {
            Write-NvmColoredText "ℹ️ $Message" "c"
        }
        'success' {
            Write-NvmColoredText "✅ $Message" "G"
        }
        'warning' {
            Write-NvmColoredText "⚠️ $Message" "y"
        }
        'error' {
            Write-NvmColoredText "❌ $Message" "r"
        }
    }
}

# Función para formatear encabezados de sección
function Format-NvmSectionHeader {
    <#
    .SYNOPSIS
        Formats section headers with consistent styling
    .PARAMETER Title
        The section title
    .PARAMETER Level
        Header level (1-3, affects styling)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 3)]
        [int]$Level = 1
    )

    Write-Host ""
    switch ($Level) {
        1 {
            Write-NvmColoredText "═══ $Title ═══" "c"
        }
        2 {
            Write-NvmColoredText "── $Title ──" "y"
        }
        3 {
            Write-NvmColoredText "· $Title ·" "e"
        }
    }
    Write-Host ""
}

# Función para mostrar progreso con formato
function Format-NvmProgress {
    <#
    .SYNOPSIS
        Shows progress messages with consistent formatting
    .PARAMETER Message
        The progress message
    .PARAMETER Step
        Current step number
    .PARAMETER Total
        Total number of steps
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [int]$Step,

        [Parameter(Mandatory = $false)]
        [int]$Total
    )

    if ($Step -and $Total) {
        $progress = "[$Step/$Total]"
        Write-NvmColoredText "$progress $Message" "b"
    } else {
        Write-NvmColoredText "⏳ $Message" "b"
    }
}

# Función para mostrar estadísticas formateadas
function Format-NvmStats {
    <#
    .SYNOPSIS
        Shows statistics in a formatted table
    .PARAMETER Stats
        Hashtable with statistic name-value pairs
    .PARAMETER Title
        Optional title for the stats section
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Stats,

        [Parameter(Mandatory = $false)]
        [string]$Title
    )

    if ($Title) {
        Format-NvmSectionHeader -Title $Title -Level 3
    }

    $maxKeyLength = ($Stats.Keys | Measure-Object -Property Length -Maximum).Maximum

    foreach ($key in $Stats.Keys | Sort-Object) {
        $padding = " " * ($maxKeyLength - $key.Length)
        Write-NvmColoredText "  $key$padding : " "e" -NoNewline
        Write-NvmColoredText "$($Stats[$key])" "c"
    }
}

# Función para mostrar versiones en formato de lista simple
function Format-NvmSimpleList {
    <#
    .SYNOPSIS
        Shows a simple list of versions without complex formatting
    .PARAMETER Versions
        Array of version strings
    .PARAMETER Title
        Optional title for the list
    .PARAMETER Highlight
        Version to highlight (shows with different color)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Versions,

        [Parameter(Mandatory = $false)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Highlight
    )

    if ($Title) {
        Write-Host "$Title`:"
    }

    foreach ($version in $Versions) {
        if ($Highlight -and $version -eq $Highlight) {
            Write-NvmColoredText "  → $version" "G"
        } else {
            Write-Host "    $version"
        }
    }

    if ($Versions.Count -eq 0) {
        Write-NvmColoredText "  (ninguna)" "e"
    }
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

function Format-NvmVersionLine {
    <#
    .SYNOPSIS
        Formats a single version line for nvm ls output
    .DESCRIPTION
        Creates a consistently formatted line with proper colors and alignment
    .PARAMETER Type
        Type of version line: 'system', 'global', 'latest', 'lts', 'nvmrc', 'non-lts'
    .PARAMETER Label
        The label text (e.g., 'latest:', 'lts/iron:')
    .PARAMETER Version
        The version string
    .PARAMETER IsInstalled
        Whether the version is installed
    .PARAMETER IsCurrent
        Whether this is the currently active version
    .PARAMETER LtsName
        For LTS versions, the LTS name (e.g., 'iron', 'jod')
    .PARAMETER Compact
        Whether to use compact formatting
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('system', 'global', 'latest', 'lts', 'nvmrc', 'non-lts')]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $false)]
        [bool]$IsInstalled = $false,

        [Parameter(Mandatory = $false)]
        [bool]$IsCurrent = $false,

        [Parameter(Mandatory = $false)]
        [string]$LtsName = "",

        [Parameter(Mandatory = $false)]
        [switch]$Compact
    )

    # Format the version
    $formattedVersion = Format-Version $Version

    # Fixed column positions:
    # Column 1: indicator
    # Column 3: label starts (after indicator + 1 space)
    # Column 17: version starts
    # Column 27: check mark

    # Determine indicator based on type
    $indicator = switch ($Type) {
        'system' {
            if ($IsCurrent) { "▶" } else { " " }
        }
        'global' {
            "→"
        }
        'latest' {
            if ($IsCurrent) { "▶" } else { " " }
        }
        'lts' {
            if ($IsCurrent) { "▶" } else { " " }
        }
        'nvmrc' {
            if ($IsCurrent) { "▶" } else { "ϟ" }
        }
        'non-lts' {
            if ($IsCurrent) { "▶" } else { " " }
        }
    }

    # Determine colors based on type
    $labelColor = switch ($Type) {
        'system' { "y" }  # Yellow for system
        'global' { "e" }  # Gray for global label
        'latest' { "e" }  # Gray for latest label
        'lts' { "y" }     # Yellow for LTS labels
        'nvmrc' { "m" }   # Purple for .nvmrc
        'non-lts' { "e" } # Gray for non-LTS
    }

    $versionColor = switch ($Type) {
        'system' { "y" }  # Yellow for system
        'global' { "c" }  # Cyan for global version
        'latest' { "c" }  # Cyan for latest version
        'lts' { "e" }     # Gray for LTS versions
        'nvmrc' { "m" }   # Purple for .nvmrc
        'non-lts' { "e" } # Gray for non-LTS
    }

    # Calculate spacing
    # Label starts at column 3, so after indicator we need 1 space
    $spaceAfterIndicator = " "
    # Label area: columns 3-16 (14 characters max for label)
    $maxLabelLength = 14
    $labelPadding = " " * [Math]::Max(0, $maxLabelLength - $Label.Length)
    # Version starts at column 17, check at column 27
    # Space between version end and check: column 27 - (17 + version length)
    $versionStartColumn = 17
    $checkColumn = 27
    $spaceAfterVersion = " " * [Math]::Max(0, $checkColumn - $versionStartColumn - $formattedVersion.Length)

    # Output the formatted line with fixed column positions

    # Column 1: Indicator
    switch ($Type) {
        'system' {
            if ($IsCurrent) {
                Write-NvmColoredText "▶" "G" -NoNewline
            } else {
                Write-Host " " -NoNewline
            }
        }
        'global' {
            Write-NvmColoredText "→" "c" -NoNewline
        }
        'latest' {
            if ($IsCurrent) {
                Write-NvmColoredText "▶" "G" -NoNewline
            } else {
                Write-Host " " -NoNewline
            }
        }
        'lts' {
            if ($IsCurrent) {
                Write-NvmColoredText "▶" "G" -NoNewline
            } else {
                Write-Host " " -NoNewline
            }
        }
        'nvmrc' {
            if ($IsCurrent) {
                Write-NvmColoredText "▶" "Y" -NoNewline
            } else {
                Write-NvmColoredText "ϟ" "Y" -NoNewline
            }
        }
        'non-lts' {
            if ($IsCurrent) {
                Write-NvmColoredText "▶" "G" -NoNewline
            } else {
                Write-Host " " -NoNewline
            }
        }
    }

    # Space after indicator (column 2)
    Write-Host $spaceAfterIndicator -NoNewline

    # Column 3-16: Label with padding
    Write-NvmColoredText "$Label$labelPadding" $labelColor -NoNewline

    # Column 17+: Version
    Write-NvmColoredText $formattedVersion $versionColor -NoNewline

    # Space between version and check
    Write-Host $spaceAfterVersion -NoNewline

    # Column 27: Installation indicator
    if ($IsInstalled) {
        Write-NvmColoredText "✓" "G"
    } else {
        Write-Host " "
    }
}