# nvm.ps1 - Node Version Manager para Windows (PowerShell)
# Equivalente a nvm.sh para sistemas Windows nativos

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

# Parsear argumentos
$Command = if ($Args -and $Args.Length -gt 0) { $Args[0] } else { $null }
if ($Args -and $Args.Length -gt 1) {
    # Si el segundo argumento parece una opción (empieza con -), no es una versión
    if ($Args[1] -like "-*") {
        $Version = $null
        $RemainingArgs = $Args[1..($Args.Length - 1)]
    }
    else {
        $Version = $Args[1]
        $RemainingArgs = if ($Args.Length -gt 2) { $Args[2..($Args.Length - 1)] } else { @() }
    }
}
else {
    $Version = $null
    $RemainingArgs = @()
}

# Configuración
$NVM_DIR = "$env:USERPROFILE\.nvm"
$NODE_MIRROR = "https://nodejs.org/dist"
$ARCH = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { "x64" } else { "x86" }

# Función para mostrar ayuda
function Show-Help {
    Write-Output "Uso: nvm <comando> [versión]"
    Write-Output "Comandos:"
    Write-Output "  install <versión>    Instala una versión específica de Node.js"
    Write-Output "  uninstall <versión> [--force]  Desinstala una versión específica de Node.js"
    Write-Output "  use <versión>        Cambia a una versión específica o alias"
    Write-Output "  ls                   Lista versiones instaladas con colores"
    Write-Output "  list                 Lista versiones instaladas (sinónimo de ls)"
    Write-Output "  ls-remote            Lista versiones disponibles para descargar"
    Write-Output "  current              Muestra la versión actualmente activa"
    Write-Output "  alias <nombre> <versión>  Crea un alias para una versión"
    Write-Output "  unalias <nombre>     Elimina un alias existente"
    Write-Output "  aliases              Lista todos los aliases definidos"
    Write-Output "  doctor               Verifica el estado de la instalación"
    Write-Output "  cleanup              Elimina versiones no actuales ni LTS"
    Write-Output "  self-update          Actualiza nvm-windows desde GitHub"
    Write-Output "  set-colors <colores>  Establece el esquema de colores (5 caracteres)"
    Write-Output "  set-default <versión> Establece versión por defecto para nuevas sesiones"
    Write-Output "  help                 Muestra esta ayuda"
    Write-Output ""
    Write-Output "Códigos de colores disponibles:"
    Write-Output "  r = rojo,   g = verde,   b = azul,   y = amarillo"
    Write-Output "  c = cyan,   m = magenta, k = negro,  e = gris claro"
    Write-Output "  R/G/B/C/M/Y/K/W/E = versiones en negrita"
    Write-Output ""
    Write-Output "Ejemplo: set-colors bygre"
    Write-Output "  b=blue (instaladas), y=yellow (sistema), g=green (actual)"
    Write-Output "  r=red (no instaladas), e=gray (por defecto)"
    Write-Output ""
    Write-Output "Variables de entorno:"
    Write-Output "  NVM_DIR              Directorio de instalación (por defecto: %USERPROFILE%\nvm)"
    Write-Output "  NVM_COLORS           Esquema de colores personalizado"
    Write-Output "  NO_COLOR             Desactiva colores (igual que NVM_NO_COLORS=--no-colors)"
    Write-Output ""
    Write-Output "Ejemplos:"
    Write-Output "  nvm install 18.19.0     Instala Node.js v18.19.0"
    Write-Output "  nvm uninstall 18.19.0   Desinstala Node.js v18.19.0"
    Write-Output "  nvm uninstall 18.19.0 --force  Fuerza desinstalación de versión activa"
    Write-Output "  nvm use 18.19.0         Cambia a Node.js v18.19.0"
    Write-Output "  nvm alias lts 18.19.0   Crea alias 'lts' para v18.19.0"
    Write-Output "  nvm use lts             Usa el alias 'lts'"
    Write-Output "  nvm aliases             Lista todos los aliases"
    Write-Output "  nvm doctor              Verifica la instalación"
}

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
        Invoke-WebRequest -Uri $url -OutFile $zipPath -ErrorAction Stop

        Write-Output "Extrayendo..."
        # Extraer directamente al directorio temporal primero
        $tempExtractPath = "$NVM_DIR\temp\$Version"
        if (!(Test-Path $tempExtractPath)) {
            New-Item -ItemType Directory -Path $tempExtractPath -Force | Out-Null
        }
        Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force -ErrorAction Stop

        # Mover el contenido del subdirectorio al directorio final
        $subDir = Get-ChildItem -Path $tempExtractPath -Directory | Select-Object -First 1
        if ($subDir) {
            $subDirPath = $subDir.FullName
            # Mover todo el contenido al directorio final
            Get-ChildItem -Path $subDirPath | Move-Item -Destination $extractPath -Force
        }
        else {
            # Si no hay subdirectorio, mover todo directamente
            Get-ChildItem -Path $tempExtractPath | Move-Item -Destination $extractPath -Force
        }

        # Limpiar directorio temporal
        Remove-Item $tempExtractPath -Recurse -Force

        Remove-Item $zipPath -Force
        Write-Output "Node.js $Version instalado en $extractPath"
    }
    catch {
        Write-NvmError "Error durante la instalación: $($_.Exception.Message)"
        # Limpiar archivos en caso de error
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
    }
}

# Función para obtener versiones con cache inteligente
function Get-NvmVersionsWithCache {
    $cacheFile = "$NVM_DIR\.version_cache.json"
    $cacheExpiryHours = 24

    # Verificar si el cache es válido
    $cacheIsValid = $false
    if (Test-Path $cacheFile) {
        $cacheAge = (Get-Date) - (Get-Item $cacheFile).LastWriteTime
        $cacheIsValid = $cacheAge.TotalHours -lt $cacheExpiryHours
    }

    if ($cacheIsValid) {
        try {
            $versions = Get-Content $cacheFile -Raw | ConvertFrom-Json
            return $versions
        }
        catch {
            # Cache corrupto, continuar con descarga
        }
    }

    # Descargar versiones con reintento
    $versions = Get-VersionsWithRetry

    # Guardar en cache
    if ($versions) {
        try {
            $versions | ConvertTo-Json | Out-File $cacheFile -Encoding UTF8 -Force
        }
        catch {
            # Ignorar errores de cache
        }
    }

    return $versions
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

# Función para encontrar archivo .nvmrc o .node-version con mejor soporte
function Find-NodeVersionFile {
    $currentDir = Get-Location
    while ($currentDir) {
        $nvmrcPath = Join-Path $currentDir ".nvmrc"
        if (Test-Path $nvmrcPath) {
            return @{ Path = $nvmrcPath; Type = "nvmrc" }
        }
        $nodeVersionPath = Join-Path $currentDir ".node-version"
        if (Test-Path $nodeVersionPath) {
            return @{ Path = $nodeVersionPath; Type = "node-version" }
        }
        $currentDir = Split-Path $currentDir -Parent
    }
    return $null
}

# Función para leer versión de .nvmrc o .node-version
function Get-NvmrcVersion {
    $fileInfo = Find-NodeVersionFile
    if (-not $fileInfo) {
        return $null
    }

    try {
        $version = Get-Content $fileInfo.Path -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }

        # Validar versión
        if (-not (Test-NvmrcVersion $version)) {
            Write-NvmError "Versión inválida en $($fileInfo.Path): $version"
            return $null
        }

        return $version
    }
    catch {
        Write-NvmError "Error al leer $($fileInfo.Path): $($_.Exception.Message)"
        return $null
    }
}

# Función para obtener sugerencias de auto-completado
function Get-NvmSuggestions {
    $suggestions = @("latest", "lts")

    # Agregar versión .nvmrc si existe
    $nvmrcVersion = Get-NvmrcVersion
    if ($nvmrcVersion) {
        $suggestions = @($nvmrcVersion) + $suggestions
    }

    # Agregar versiones LTS disponibles
    try {
        $versions = Get-NvmVersionsWithCache
        $ltsNames = $versions | Where-Object { $_.lts } | Select-Object -ExpandProperty lts -Unique
        $suggestions += $ltsNames
    }
    catch {
        # Ignorar errores de red
    }

    return $suggestions
}

# Función para desinstalar Node.js
function Uninstall-Node {
    param([string]$Version, [switch]$Force)

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
    if ($currentVersion -eq $Version -and -not $Force) {
        Write-NvmError "No puedes desinstalar la versión actualmente activa. Cambia a otra versión primero con: nvm use <otra-versión>"
        Write-Output "O usa --force para forzar la desinstalación: nvm uninstall $Version --force"
        return
    }

    # Confirmar eliminación (solo si no es forzado)
    if (-not $Force) {
        $confirm = Read-Host "¿Estás seguro de que quieres desinstalar Node.js $Version? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Output "Cancelado."
            return
        }
    }
    else {
        Write-Output "Forzando desinstalación de la versión activa $Version..."
    }

    try {
        Remove-Item $installPath -Recurse -Force
        Write-Output "Node.js $Version desinstalado correctamente"
    }
    catch {
        Write-NvmError "Error al desinstalar: $($_.Exception.Message)"
    }
}
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

    # Limpiar versiones anteriores del PATH
    $pathEntries = $env:PATH -split ';'
    $cleanedPath = $pathEntries | Where-Object { $_ -notlike "*$NVM_DIR\v*" -and $_ -notlike "*node-*-win-*" } | Where-Object { $_ -ne "" }

    # Agregar la nueva versión al PATH
    $env:PATH = "$nodePath;$($cleanedPath -join ';')"

    # Establecer variable de entorno para compatibilidad con Starship y otros tools
    $env:NODE_VERSION = $resolvedVersion

    # Guardar la versión activa para persistencia entre sesiones
    Set-NvmActiveVersion $resolvedVersion

    Write-Output "Ahora usando Node.js $resolvedVersion"
}

# Función para listar versiones instaladas
function Get-Version {
    if (!(Test-Path $NVM_DIR)) { Write-Output "No hay versiones instaladas."; return }
    Get-ChildItem -Path $NVM_DIR -Directory | Where-Object { $_.Name -match "^v\d" } | ForEach-Object { Write-Output $_.Name }
}

# Función para listar versiones remotas
function Get-RemoteVersion {
    Write-Output "Obteniendo lista de versiones disponibles..."
    try {
        $versions = Get-NvmVersionsWithCache
    }
    catch {
        Write-NvmError "Error al obtener versiones remotas"
        return
    }
        
    # Procesar versiones para agregar etiquetas (inspirado en nvm.fish)
    $processedVersions = @()
        
    foreach ($ver in $versions) {
        $label = ""
        if ($ver.version -eq $versions[0].version) {
            $label = " latest"
        }
        elseif ($ver.lts) {
            $label = " lts/$($ver.lts.ToLower())"
        }
        $processedVersions += "$($ver.version)$label"
    }    $processedVersions | ForEach-Object { Write-Output $_ }
}

# Función para mostrar la versión actual
function Get-CurrentVersion {
    # Primero intentar con Get-Command
    $nodePath = Get-Command node -ErrorAction SilentlyContinue
    if ($nodePath) {
        try {
            $version = & node --version 2>$null
            if ($version) {
                Write-Output "Versión actual: $version"
                return
            }
        }
        catch {
            # Ignorar errores y continuar
        }
    }

    # Si Get-Command falla, intentar ejecutar directamente
    try {
        $version = & node --version 2>$null
        if ($version) {
            Write-Output "Versión actual: $version"
            return
        }
    }
    catch {
        # Ignorar errores
    }

    # Si todo falla, verificar si hay alguna versión de nvm en PATH
    $nvmPaths = $env:PATH -split ';' | Where-Object { $_ -like "*nvm*" -and $_ -like "*v*" }
    if ($nvmPaths) {
        Write-Output "Node.js no está en PATH. Usa 'nvm use <versión>' para activar una versión."
    }
    else {
        Write-Output "Node.js no está en PATH. No hay versiones de nvm activas."
    }
}

# Función para crear alias
function New-NvmAlias {
    param([string]$Name, [string]$Version)

    if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($Version)) {
        Write-NvmError "Nombre y versión son requeridos. Uso: nvm alias <nombre> <versión>"
        return
    }

    $aliasPath = "$NVM_DIR\alias\$Name"

    # Crear directorio si no existe
    if (!(Test-Path "$NVM_DIR\alias")) {
        New-Item -ItemType Directory -Path "$NVM_DIR\alias" -Force | Out-Null
    }

    # Verificar que la versión existe
    $versionPath = "$NVM_DIR\$Version"
    if (!(Test-Path $versionPath)) {
        Write-NvmError "Versión $Version no está instalada. Instálala primero."
        return
    }

    # Crear el archivo de alias
    try {
        $Version | Out-File -FilePath $aliasPath -Encoding UTF8 -Force
        Write-Output "Alias '$Name' creado para $Version"
    }
    catch {
        Write-NvmError "Error al crear alias: $($_.Exception.Message)"
    }
}

# Función para eliminar alias
function Remove-NvmAlias {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-NvmError "Nombre del alias es requerido. Uso: nvm unalias <nombre>"
        return
    }

    $aliasPath = "$NVM_DIR\alias\$Name"

    if (Test-Path $aliasPath) {
        try {
            Remove-Item $aliasPath -Force
            Write-Output "Alias '$Name' eliminado"
        }
        catch {
            Write-NvmError "Error al eliminar alias: $($_.Exception.Message)"
        }
    }
    else {
        Write-Output "Alias '$Name' no existe"
    }
}

# Función para listar alias
function Get-NvmAliases {
    $aliasDir = "$NVM_DIR\alias"
    if (!(Test-Path $aliasDir)) {
        Write-Output "No hay aliases definidos"
        return
    }

    $aliases = Get-ChildItem -Path $aliasDir -File
    if ($aliases.Count -eq 0) {
        Write-Output "No hay aliases definidos"
        return
    }

    Write-Output "Aliases definidos:"
    foreach ($alias in $aliases) {
        try {
            $version = Get-Content $alias.FullName -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
            Write-Output "  $($alias.Name) -> $version"
        }
        catch {
            Write-Output "  $($alias.Name) -> [error al leer]"
        }
    }
}

function Test-NvmTerminalColors {
    <#
    .SYNOPSIS
        Tests if the terminal supports colors
    .DESCRIPTION
        Checks if the current terminal/console supports ANSI color codes
    .OUTPUTS
        Boolean indicating if colors are supported
    #>
    [OutputType([bool])]
    param()

    # Check if running in a terminal that supports colors
    # Windows Terminal, Windows Console Host with Virtual Terminal Processing, or other ANSI-compatible terminals
    $script:NvmHasColors = $true

    # Check for NO_COLOR environment variable
    if ($env:NO_COLOR -or $env:NVM_NO_COLORS -eq '--no-colors') {
        $script:NvmHasColors = $false
    }

    return $script:NvmHasColors
}

function Get-NvmColorCode {
    <#
    .SYNOPSIS
        Gets the ANSI color code for a given color identifier
    .DESCRIPTION
        Converts a color identifier (r, g, b, y, etc.) to its corresponding ANSI color code
    .PARAMETER Color
        The color identifier (r=red, g=green, b=blue, y=yellow, etc.)
    .OUTPUTS
        String containing the ANSI color code
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Color
    )

    switch ($Color.ToLower()) {
        '0' { return '' }
        'r' { return '0;31m' }  # red
        'R' { return '1;31m' }  # bold red
        'g' { return '0;32m' }  # green
        'G' { return '1;32m' }  # bold green
        'b' { return '0;34m' }  # blue
        'B' { return '1;34m' }  # bold blue
        'c' { return '0;36m' }  # cyan
        'C' { return '1;36m' }  # bold cyan
        'm' { return '0;35m' }  # magenta
        'M' { return '1;35m' }  # bold magenta
        'y' { return '0;33m' }  # yellow
        'Y' { return '1;33m' }  # bold yellow
        'k' { return '0;30m' }  # black
        'K' { return '1;30m' }  # bold black
        'e' { return '0;37m' }  # light grey
        'W' { return '1;37m' }  # white
        default {
            Write-NvmError "Invalid color code: $Color"
            return ''
        }
    }
}

function Get-NvmColors {
    <#
    .SYNOPSIS
        Gets the color code for a specific color index
    .DESCRIPTION
        Returns the ANSI color code for predefined color positions used in nvm output
    .PARAMETER Index
        The color index (1=installed, 2=system, 3=current, 4=not installed, 5=default, 6=LTS)
    .OUTPUTS
        String containing the ANSI color code
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Index
    )

    # Default color scheme: bygre (blue, yellow, green, red, grey)
    $colors = $env:NVM_COLORS
    if (-not $colors) {
        $colors = 'bygre'
    }

    $colorChar = $colors[$Index - 1]
    if (-not $colorChar) {
        Write-NvmError "Invalid color index: $Index"
        return ''
    }

    $colorCode = Get-NvmColorCode -Color $colorChar

    # For LTS color (index 6), make it bold by replacing 0; with 1;
    if ($Index -eq 6) {
        $colorCode = $colorCode -replace '^0;', '1;'
    }

    return $colorCode
}

function Write-NvmColoredText {
    <#
    .SYNOPSIS
        Writes text with color formatting
    .DESCRIPTION
        Outputs text wrapped with ANSI color codes if colors are supported
    .PARAMETER Text
        The text to color
    .PARAMETER Color
        The color identifier
    .PARAMETER NoNewline
        If specified, doesn't add a newline at the end
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Color,

        [switch]$NoNewline
    )

    if (Test-NvmTerminalColors) {
        $colorCode = Get-NvmColorCode -Color $Color
        if ($colorCode) {
            # Use PowerShell's Write-Host with -ForegroundColor for better compatibility
            $psColor = Convert-NvmColorToPSColor -Color $Color
            if ($psColor) {
                if ($NoNewline) {
                    Write-Host $Text -ForegroundColor $psColor -NoNewline
                }
                else {
                    Write-Host $Text -ForegroundColor $psColor
                }
            }
            else {
                # Fallback to ANSI codes if PowerShell color conversion fails
                $coloredText = "$([char]27)[$colorCode$Text$([char]27)[0m"
                if ($NoNewline) {
                    Write-Host $coloredText -NoNewline
                }
                else {
                    Write-Host $coloredText
                }
            }
        }
        else {
            if ($NoNewline) {
                Write-Host $Text -NoNewline
            }
            else {
                Write-Host $Text
            }
        }
    }
    else {
        if ($NoNewline) {
            Write-Host $Text -NoNewline
        }
        else {
            Write-Host $Text
        }
    }
}

function Convert-NvmColorToPSColor {
    <#
    .SYNOPSIS
        Converts nvm color codes to PowerShell console colors
    .DESCRIPTION
        Maps nvm color identifiers to PowerShell's ConsoleColor enum values
    .PARAMETER Color
        The nvm color identifier
    .OUTPUTS
        PowerShell ConsoleColor value or $null if not supported
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Color
    )

    switch ($Color.ToLower()) {
        'r' { return [ConsoleColor]::Red }
        'g' { return [ConsoleColor]::Green }
        'b' { return [ConsoleColor]::Blue }
        'y' { return [ConsoleColor]::Yellow }
        'c' { return [ConsoleColor]::Cyan }
        'm' { return [ConsoleColor]::Magenta }
        'k' { return [ConsoleColor]::Black }
        'w' { return [ConsoleColor]::White }
        'e' { return [ConsoleColor]::Gray }
        default { return $null }
    }
}

function Set-NvmColors {
    <#
    .SYNOPSIS
        Sets custom color scheme for nvm output
    .DESCRIPTION
        Configures the color scheme used by nvm for displaying version information
    .PARAMETER ColorString
        A 5-character string representing the color scheme (e.g., "bygre")
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[rRgGbBcCyYmMkKeW]{5}$')]
        [string]$ColorString
    )

    if ($ColorString.Length -ne 5) {
        Write-NvmError 'Color string must be exactly 5 characters long'
        return
    }

    $env:NVM_COLORS = $ColorString

    if (Test-NvmTerminalColors) {
        Write-Host "Setting colors to: " -NoNewline
        for ($i = 0; $i -lt $ColorString.Length; $i++) {
            $color = $ColorString[$i]
            Write-NvmColoredText -Text $color -Color $color -NoNewline
        }
        Write-Host ""
    }
    else {
        Write-Host "Setting colors to: $ColorString"
        Write-Host "WARNING: Colors may not display because they are not supported in this shell."
    }
}

# Función para mostrar versiones con colores (equivalente a nvm list) - Inspirado en nvm.fish
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
    $installedVersions = Get-ChildItem -Path $NVM_DIR -Directory |
    Where-Object { $_.Name -match "^v\d" } |
    Select-Object -ExpandProperty Name

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
    if ($nvmrcVersion -and -not $nvmrcVersion.StartsWith('v')) {
        $nvmrcVersion = "v$nvmrcVersion"
    }

    # Function to normalize version for comparison
    function Normalize-Version {
        param([string]$Version)
        if ($Version -and -not $Version.StartsWith('v')) {
            return "v$Version"
        }
        return $Version
    }

    # Function to format version to v#.#.# without padding
    function Format-Version {
        param([string]$Version)
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
    $totalWidth = $Compact ? 20 : 28

    # Show system version if exists
    $systemVersion = Get-NvmSystemVersion
    if ($systemVersion) {
        $normalizedSystemVersion = Normalize-Version $systemVersion
        $isInstalled = $true  # System version is always "installed" in system
        $indicator = if ($currentVersion -eq $normalizedSystemVersion) { "▶" } else { " " }
        $label = "system:"
        $padding = " " * (14 - $label.Length)
        $formattedVersion = Format-Version $systemVersion
        $lineContent = "$indicator $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length - ($isInstalled ? 1 : 0)
        $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

        # Color indicator
        if ($currentVersion -eq $normalizedSystemVersion) {
            Write-NvmColoredText "▶" "G" -NoNewline
        }
        else {
            Write-Host " " -NoNewline
        }
        Write-NvmColoredText " $label$padding" "y" -NoNewline  # Amarillo para sistema
        Write-NvmColoredText "$formattedVersion" "y" -NoNewline
        Write-Host "$finalSpaces" -NoNewline
        if ($isInstalled) {
            Write-NvmColoredText "✓" "G"
        }
        else {
            Write-Host ""
        }
    }

    # Show global version (always shown with →)
    $globalVersion = $defaultVersion
    if ($globalVersion) {
        $isInstalled = $installedVersions -contains $globalVersion
        $label = "global:"
        $padding = " " * (14 - $label.Length)  # Fixed padding for labels
        $formattedVersion = Format-Version $globalVersion
        $lineContent = "→ $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length - ($isInstalled ? 1 : 0)  # -1 for the ✓
        $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

        # Color output: → in blue (default), label in gray, version in blue (default), ✓ in blue
        Write-NvmColoredText "→" "b" -NoNewline
        Write-NvmColoredText " $label$padding" "e" -NoNewline
        Write-NvmColoredText "$formattedVersion" "b" -NoNewline
        Write-Host "$finalSpaces" -NoNewline
        if ($isInstalled) {
            Write-NvmColoredText "✓" "G"
        }
        else {
            Write-Host ""
        }
    }

    # Show default version if different from global
    if ($defaultVersion -and $defaultVersion -ne $globalVersion) {
        $isInstalled = $installedVersions -contains $defaultVersion
        $label = "default:"
        $padding = " " * (14 - $label.Length)
        $formattedVersion = Format-Version $defaultVersion
        $lineContent = "→ $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length - ($isInstalled ? 1 : 0)
        $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

        Write-NvmColoredText "→" "b" -NoNewline
        Write-NvmColoredText " $label$padding" "e" -NoNewline
        Write-NvmColoredText "$formattedVersion" "b" -NoNewline
        Write-Host "$finalSpaces" -NoNewline
        if ($isInstalled) {
            Write-NvmColoredText "✓" "G"
        }
        else {
            Write-Host ""
        }
    }

    # Latest version
    if ($latestVersion) {
        $isInstalled = $installedVersions -contains $latestVersion
        $label = "latest:"
        $padding = " " * (14 - $label.Length)
        $indicator = if ($currentVersion -eq $latestVersion) { "▶" } else { " " }
        $formattedVersion = Format-Version $latestVersion
        $lineContent = "$indicator $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length - ($isInstalled ? 1 : 0)
        $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

        # Color indicator
        if ($currentVersion -eq $latestVersion) {
            Write-NvmColoredText "▶" "G" -NoNewline
        }
        else {
            Write-Host " " -NoNewline
        }
        Write-NvmColoredText " $label$padding" "e" -NoNewline
        Write-NvmColoredText "$formattedVersion" "e" -NoNewline
        Write-Host "$finalSpaces" -NoNewline
        if ($isInstalled) {
            Write-NvmColoredText "✓" "G"
        }
        else {
            Write-Host ""
        }
    }

    # LTS versions
    foreach ($lts in $ltsVersions) {
        $normalizedLtsVersion = Normalize-Version $lts.version
        $isInstalled = $installedVersions -contains $normalizedLtsVersion
        $indicator = if ($currentVersion -eq $normalizedLtsVersion) { "▶" } else { " " }
        $name = $lts.lts.ToLower()
        $label = "lts/$name`:" 
        $padding = " " * (14 - $label.Length)
        $formattedVersion = Format-Version $lts.version
        $lineContent = "$indicator $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length - ($isInstalled ? 1 : 0)
        $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

        # Color indicator
        if ($currentVersion -eq $normalizedLtsVersion) {
            Write-NvmColoredText "▶" "G" -NoNewline
        }
        else {
            Write-Host " " -NoNewline
        }
        Write-NvmColoredText " $label$padding" "M" -NoNewline  # Bold magenta for LTS labels
        Write-NvmColoredText "$formattedVersion" "M" -NoNewline  # Bold magenta for LTS versions
        Write-Host "$finalSpaces" -NoNewline
        if ($isInstalled) {
            Write-NvmColoredText "✓" "G"
        }
        else {
            Write-Host ""
        }

        # Show installed versions in this LTS line that are not the latest
        $installedInLine = $installedLtsMapping.Keys | Where-Object { $installedLtsMapping[$_] -eq $lts.lts -and $_ -ne $normalizedLtsVersion } | Sort-Object { [version]($_ -replace '^v', '') } -Descending
        foreach ($installedVer in $installedInLine) {
            $normalizedInstalled = Normalize-Version $installedVer
            $isCurrentInstalled = $currentVersion -eq $normalizedInstalled
            $indicatorInstalled = if ($isCurrentInstalled) { "▶" } else { " " }
            $formattedInstalled = Format-Version $installedVer
            $prefix = "     ↳          "
            $lineContentInstalled = "$prefix$formattedInstalled"
            $spacesNeededInstalled = $totalWidth - $lineContentInstalled.Length - 1  # Always show ✓
            $finalSpacesInstalled = " " * [Math]::Max(1, $spacesNeededInstalled)

            # Color for installed LTS versions
            if ($isCurrentInstalled) {
                Write-NvmColoredText $prefix "G" -NoNewline
            }
            else {
                Write-NvmColoredText $prefix "e" -NoNewline
            }
            Write-NvmColoredText $formattedInstalled "M" -NoNewline
            Write-Host "$finalSpacesInstalled" -NoNewline
            Write-NvmColoredText "✓" "G"
        }
    }

    # .nvmrc version (if exists)
    if ($nvmrcVersion) {
        $isInstalled = $installedVersions -contains $nvmrcVersion
        $isCurrent = $currentVersion -eq $nvmrcVersion
        
        if ($isCurrent) {
            # If .nvmrc version is current, show as ▶ .nvmrc: with ✓
            $indicator = "▶"
            $showCheckmark = $true
        }
        elseif ($isInstalled) {
            # If installed but not current, show as • .nvmrc: with ✓
            $indicator = "•"
            $showCheckmark = $true
        }
        else {
            # If not installed, show as • .nvmrc: without ✓
            $indicator = "•"
            $showCheckmark = $false
        }
        $label = ".nvmrc:"
        $padding = " " * (14 - $label.Length)
        $formattedVersion = Format-Version $nvmrcVersion
        $lineContent = "$indicator $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length - ($showCheckmark ? 1 : 0)
        $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

        # Color indicator
        if ($isCurrent) {
            Write-NvmColoredText "▶" "G" -NoNewline
        }
        else {
            Write-NvmColoredText "ϟ" "C" -NoNewline
        }
        Write-NvmColoredText " $label$padding" "e" -NoNewline
        Write-NvmColoredText "$formattedVersion" "e" -NoNewline
        Write-Host "$finalSpaces" -NoNewline
        if ($showCheckmark) {
            Write-NvmColoredText "✓" "G"
        }
        else {
            Write-Host ""
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
                "•"
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
                Write-NvmColoredText "ϟ" "C" -NoNewline
            }
            else {
                Write-Host " " -NoNewline
            }
            Write-NvmColoredText " $label$padding" "e" -NoNewline
            Write-NvmColoredText "$formattedVersion" "e" -NoNewline
            Write-Host "$finalSpaces" -NoNewline
            Write-NvmColoredText "✓" "G"
        }
    }

    Write-Host ""
}

# Función auxiliar para obtener la versión actual
function Get-NvmCurrentVersion {
    # Primero intentar detectar desde PATH
    $nodePath = Get-Command node -ErrorAction SilentlyContinue
    if ($nodePath) {
        try {
            $version = & node --version 2>$null
            if ($version) {
                return $version
            }
        }
        catch {
            # Ignore errors
        }
    }
    
    # Si no se detecta en PATH, intentar leer la versión activa guardada
    $activeVersion = Get-NvmActiveVersion
    if ($activeVersion) {
        return $activeVersion
    }
    
    return $null
}

# Función para guardar la versión activa
function Set-NvmActiveVersion {
    param([string]$Version)
    
    $activeFile = "$NVM_DIR\.active_version"
    try {
        $Version | Out-File -FilePath $activeFile -Encoding UTF8 -Force
    }
    catch {
        Write-NvmError "Error al guardar versión activa: $($_.Exception.Message)"
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

# Función auxiliar para verificar si hay Node.js del sistema
function Test-NvmSystemNode {
    # Check if there's a system Node.js installation
    $systemPaths = @(
        "$env:SystemDrive\Windows\System32\node.exe",
        "$env:ProgramFiles\nodejs\node.exe",
        "$env:ProgramFiles(x86)\nodejs\node.exe"
    )

    foreach ($path in $systemPaths) {
        if (Test-Path $path) {
            return $true
        }
    }

    return $false
}

# Función auxiliar para obtener la versión del sistema
function Get-NvmSystemVersion {
    $systemPaths = @(
        "$env:SystemDrive\Windows\System32\node.exe",
        "$env:ProgramFiles\nodejs\node.exe",
        "$env:ProgramFiles(x86)\nodejs\node.exe"
    )

    foreach ($path in $systemPaths) {
        if (Test-Path $path) {
            try {
                $version = & $path --version 2>$null
                if ($version) {
                    return $version
                }
            }
            catch {
                # Ignore errors
            }
        }
    }

    return $null
}

# Función auxiliar para escribir errores
function Write-NvmError {
    <#
    .SYNOPSIS
        Writes an error message to the console
    .DESCRIPTION
        Outputs error messages with appropriate formatting
    .PARAMETER Message
        The error message to display
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "Error: $Message" -ForegroundColor Red
}

# Función para limpiar versiones antiguas
function Cleanup-Nvm {
    if (!(Test-Path $NVM_DIR)) {
        Write-NvmError "No hay versiones instaladas."
        return
    }
    
    # Obtener versiones instaladas
    $installedVersions = Get-ChildItem -Path $NVM_DIR -Directory |
    Where-Object { $_.Name -match "^v\d" } |
    Select-Object -ExpandProperty Name
    
    if ($installedVersions.Count -eq 0) {
        Write-Output "No hay versiones instaladas para limpiar."
        return
    }
    
    # Obtener versión actual
    $currentVersion = Get-NvmCurrentVersion
    if ($currentVersion) {
        $currentVersion = $currentVersion.Trim()
    }
    
    # Obtener versión LTS
    try {
        $versions = Get-NvmVersionsWithCache
        $ltsVersion = $versions | Where-Object { $_.lts } | Select-Object -First 1 | Select-Object -ExpandProperty version
    }
    catch {
        $ltsVersion = $null
    }
    
    # Versiones a mantener
    $keepVersions = @()
    if ($currentVersion) { $keepVersions += $currentVersion }
    if ($ltsVersion) { $keepVersions += $ltsVersion }
    
    # Versiones a remover
    $toRemove = $installedVersions | Where-Object { $_ -notin $keepVersions }
    
    if ($toRemove.Count -eq 0) {
        Write-Output "No hay versiones para limpiar."
        return
    }
    
    Write-Output "Versiones a mantener: $($keepVersions -join ', ')"
    Write-Output "Versiones a remover: $($toRemove -join ', ')"
    
    $confirm = Read-Host "¿Confirmar eliminación? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Output "Cancelado."
        return
    }
    
    foreach ($version in $toRemove) {
        $path = "$NVM_DIR\$version"
        try {
            Remove-Item $path -Recurse -Force
            Write-Output "Eliminada: $version"
        }
        catch {
            Write-NvmError "Error al eliminar ${version}: $($_.Exception.Message)"
        }
    }
    
    Write-Output "Limpieza completada."
}
function Set-NvmDefaultVersion {
    param([string]$Version)
    
    if ([string]::IsNullOrWhiteSpace($Version)) {
        Write-NvmError "Versión es requerida. Uso: nvm set-default <versión>"
        return
    }
    
    # Resolver la versión
    $resolvedVersion = Resolve-Version $Version
    if (-not $resolvedVersion) {
        return
    }
    
    # Guardar en variable de entorno
    [Environment]::SetEnvironmentVariable("nvm_default_version", $resolvedVersion, "User")
    
    Write-Output "Versión por defecto establecida a $resolvedVersion"
    
    # Integrar en perfil de PowerShell para nuevas sesiones
    $profilePath = $PROFILE
    $nvmInit = "if (Test-Path '$NVM_DIR\nvm.ps1') { & '$NVM_DIR\nvm.ps1' use `$env:nvm_default_version }"
    
    if (!(Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }
    
    $profileContent = Get-Content $profilePath -Raw -Encoding UTF8
    if ($profileContent -notlike "*nvm.ps1*") {
        Add-Content $profilePath "`n# nvm-windows default version`n$nvmInit" -Encoding UTF8
        Write-Output "Integrado en perfil de PowerShell. Reinicia la terminal para aplicar."
    }
}
function Update-Nvm {
    $url = "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/nvm.ps1"
    $tempPath = "$NVM_DIR\temp\nvm.ps1.new"
    
    try {
        Write-Output "Descargando actualización..."
        Invoke-WebRequest -Uri $url -OutFile $tempPath -ErrorAction Stop
        
        # Verificar que el archivo se descargó
        if (!(Test-Path $tempPath)) {
            Write-NvmError "Error: no se pudo descargar la actualización"
            return
        }
        
        # Hacer backup del actual
        $backupPath = "$NVM_DIR\nvm.ps1.backup"
        Copy-Item "$NVM_DIR\nvm.ps1" $backupPath -Force
        
        # Reemplazar
        Move-Item $tempPath "$NVM_DIR\nvm.ps1" -Force
        
        Write-Output "✅ nvm-windows actualizado. Reinicia la terminal para usar la nueva versión."
    }
    catch {
        Write-NvmError "Error al actualizar: $($_.Exception.Message)"
        if (Test-Path $tempPath) { Remove-Item $tempPath -Force }
    }
}
function Test-NvmInstallation {
    Write-Output "Verificando instalación de nvm-windows..."

    $issues = @()

    # Verificar directorio principal
    if (!(Test-Path $NVM_DIR)) {
        $issues += "Directorio principal no existe: $NVM_DIR"
    }

    # Verificar script principal
    $scriptPath = "$NVM_DIR\nvm.ps1"
    if (!(Test-Path $scriptPath)) {
        $issues += "Script principal no encontrado: $scriptPath"
    }

    # Verificar wrapper CMD
    $cmdPath = "$NVM_DIR\nvm.cmd"
    if (!(Test-Path $cmdPath)) {
        $issues += "Wrapper CMD no encontrado: $cmdPath"
    }

    # Verificar PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$NVM_DIR*") {
        $issues += "nvm no está en PATH de usuario"
    }

    if ($issues.Count -eq 0) {
        Write-Output "✅ Instalación correcta"
        return $true
    }
    else {
        Write-Output "❌ Problemas encontrados:"
        foreach ($issue in $issues) {
            Write-Output "  - $issue"
        }
        return $false
    }
}

# Lógica principal
switch ($Command) {
    "install" { if ($Version) { Install-Node $Version } else { Write-Output "Especifica una versión" } }
    "uninstall" { 
        if ($Version) { 
            $force = $RemainingArgs -contains "--force"
            Uninstall-Node $Version -Force:$force 
        }
        else { 
            Write-Output "Especifica una versión" 
        } 
    }
    "use" { if ($Version) { Use-Node $Version } else { Write-Output "Especifica una versión" } }
    "ls" { 
        $compact = $RemainingArgs -contains "--compact"
        Show-NvmVersions -Compact:$compact
    }
    "list" { 
        $compact = $RemainingArgs -contains "--compact"
        Show-NvmVersions -Compact:$compact
    }
    "ls-remote" { Get-RemoteVersion }
    "current" { Get-CurrentVersion }
    "alias" { if ($Version -and $RemainingArgs[0]) { New-NvmAlias $Version $RemainingArgs[0] } else { Write-Output "Uso: alias <nombre> <versión>" } }
    "unalias" { if ($Version) { Remove-NvmAlias $Version } else { Write-Output "Especifica un alias" } }
    "aliases" { Get-NvmAliases }
    "doctor" { Test-NvmInstallation }
    "cleanup" { Cleanup-Nvm }
    "self-update" { Update-Nvm }
    "set-colors" { if ($Version) { Set-NvmColors $Version } else { Write-Output "Especifica esquema de colores" } }
    "set-default" { if ($Version) { Set-NvmDefaultVersion $Version } else { Write-Output "Especifica una versión" } }
    "help" { Show-Help }
    default { Show-Help }
}
