# nvm.ps1 - Node Version Manager para Windows (PowerShell) v2.4-beta
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

# Función auxiliar para mostrar errores
function Write-NvmError {
    param([string]$Message)
    Write-Host "Error: $Message" -ForegroundColor Red
}

# Función para mostrar ayuda
function Show-Help {
    Write-Output "Uso: nvm <comando> [versión]"
    Write-Output "Comandos:"
    Write-Output "  install <versión>    Instala una versión específica de Node.js"
    Write-Output "  uninstall <versión> [--force]  Desinstala una versión específica de Node.js"
    Write-Output "  use <versión>        Cambia a una versión específica o alias"
    Write-Output "  ls                   Lista versiones instaladas con colores"
    Write-Output "  lsu                  Fuerza actualización de la lista de versiones"
    Write-Output "  list                 Lista versiones instaladas (sinónimo de ls)"
    Write-Output "  ls-remote            Lista versiones disponibles para descargar"
    Write-Output "  current              Muestra la versión actualmente activa"
    Write-Output "  alias <nombre> <versión>  Crea un alias para una versión"
    Write-Output "  unalias <nombre>     Elimina un alias existente"
    Write-Output "  aliases              Lista todos los aliases definidos"
    Write-Output "  doctor               Verifica el estado de la instalación"
    Write-Output "  migrate               Migra al sistema de enlaces simbólicos"
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
        # Limpiar directorio de destino si existe
        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }

        # Extraer directamente al directorio final
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force -ErrorAction Stop

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

        # Si el archivo está vacío, ignorarlo silenciosamente
        if ([string]::IsNullOrWhiteSpace($version)) {
            return $null
        }

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
    # Primero intentar con enlaces simbólicos
    $currentNodePath = "$NVM_DIR\current\bin\node.exe"
    if (Test-Path $currentNodePath) {
        try {
            $version = & $currentNodePath --version 2>$null
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
    $nvmPaths = $env:PATH -split ';' | Where-Object { $_ -like "*nvm*" -and $_ -like "*current*" }
    if ($nvmPaths) {
        Write-Output "Node.js no está disponible. Usa 'nvm use <versión>' para activar una versión."
    }
    else {
        Write-Output "Node.js no está disponible. No hay versiones de nvm activas."
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

# Función para obtener versiones de Node.js con cache local
function Get-NvmVersionsWithCache {
    <#
    .SYNOPSIS
        Gets Node.js versions with local caching for 15 minutes
    .DESCRIPTION
        Retrieves Node.js versions from nodejs.org with local caching to improve performance
    #>
    param()

    $cacheFile = Join-Path $NVM_DIR '.version_cache.json'
    $cacheExpiryMinutes = 15

    # Check if cache exists and is not expired
    if (Test-Path $cacheFile) {
        try {
            $cacheData = Get-Content $cacheFile -Raw | ConvertFrom-Json
            $cacheTime = [DateTime]::Parse($cacheData.timestamp)
            $timeDiff = (Get-Date) - $cacheTime

            if ($timeDiff.TotalMinutes -lt $cacheExpiryMinutes) {
                Write-Verbose "Using cached versions (age: $([math]::Round($timeDiff.TotalMinutes, 1)) minutes)"
                return $cacheData.versions
            }
        }
        catch {
            Write-Verbose "Cache file corrupted, will fetch fresh data"
        }
    }

    # Fetch fresh data from nodejs.org
    Write-Verbose "Fetching fresh version data from nodejs.org..."
    try {
        $response = Invoke-WebRequest -Uri 'https://nodejs.org/dist/index.json' -UseBasicParsing
        $versions = $response.Content | ConvertFrom-Json

        # Cache the data
        $cacheData = @{
            timestamp = (Get-Date).ToString('o')
            versions = $versions
        }
        $cacheData | ConvertTo-Json -Depth 10 | Set-Content $cacheFile -Encoding UTF8

        Write-Verbose "Cached $(($versions | Measure-Object).Count) versions"
        return $versions
    }
    catch {
        Write-NvmError "Failed to fetch versions from nodejs.org: $($_.Exception.Message)"
        throw
    }
}

# Función para actualizar el cache de versiones forzosamente
function Update-NvmVersionCache {
    <#
    .SYNOPSIS
        Forces an update of the local version cache
    .DESCRIPTION
        Downloads fresh version data from nodejs.org and updates the local cache
    #>
    param()

    $cacheFile = Join-Path $NVM_DIR '.version_cache.json'

    Write-Host "Updating version cache..."
    try {
        $response = Invoke-WebRequest -Uri 'https://nodejs.org/dist/index.json' -UseBasicParsing
        $versions = $response.Content | ConvertFrom-Json

        # Cache the data
        $cacheData = @{
            timestamp = (Get-Date).ToString('o')
            versions = $versions
        }
        $cacheData | ConvertTo-Json -Depth 10 | Set-Content $cacheFile -Encoding UTF8

        Write-Host "Cache updated with $(($versions | Measure-Object).Count) versions"
    }
    catch {
        Write-NvmError "Failed to update cache: $($_.Exception.Message)"
        throw
    }
}

# Función para guardar versiones instaladas en cache local
function Save-InstalledVersionsCache {
    <#
    .SYNOPSIS
        Saves installed Node.js versions to local cache
    .DESCRIPTION
        Scans installed versions and saves them to a local cache file for faster access
    #>
    param()

    $cacheFile = Join-Path $NVM_DIR '.installed_versions_cache.json'

    try {
        $installedVersions = Get-ChildItem (Join-Path $NVM_DIR 'v*') -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^v\d+\.\d+\.\d+$' } |
            ForEach-Object { 
                $versionString = $_.Name -replace '^v', ''
                try {
                    [version]$versionString | Out-Null
                    $_.Name
                } catch {
                    # Skip invalid version strings
                    Write-Verbose "Skipping invalid version directory: $($_.Name)"
                }
            } |
            Sort-Object { [version]($_ -replace '^v', '') } -Descending

        $cacheData = @{
            timestamp = (Get-Date).ToString('o')
            versions = $installedVersions
        }
        $cacheData | ConvertTo-Json | Set-Content $cacheFile -Encoding UTF8

        Write-Verbose "Cached $(($installedVersions | Measure-Object).Count) installed versions"
    }
    catch {
        Write-Verbose "Failed to save installed versions cache: $($_.Exception.Message)"
    }
}

# Función para obtener versiones instaladas desde cache local
function Get-InstalledVersionsFromCache {
    <#
    .SYNOPSIS
        Gets installed Node.js versions from local cache
    .DESCRIPTION
        Retrieves installed versions from cache, falling back to directory scan if cache is stale
    #>
    param()

    $cacheFile = Join-Path $NVM_DIR '.installed_versions_cache.json'
    $cacheExpiryMinutes = 5  # Cache installed versions for 5 minutes

    # Check if cache exists and is not expired
    if (Test-Path $cacheFile) {
        try {
            $cacheData = Get-Content $cacheFile -Raw | ConvertFrom-Json
            $cacheTime = [DateTime]::Parse($cacheData.timestamp)
            $timeDiff = (Get-Date) - $cacheTime

            if ($timeDiff.TotalMinutes -lt $cacheExpiryMinutes) {
                Write-Verbose "Using cached installed versions (age: $([math]::Round($timeDiff.TotalMinutes, 1)) minutes)"
                return $cacheData.versions
            }
        }
        catch {
            Write-Verbose "Installed versions cache corrupted, will scan directories"
        }
    }

    # Fallback to directory scan
    Write-Verbose "Scanning for installed versions..."
    $installedVersions = Get-ChildItem (Join-Path $NVM_DIR 'v*') -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^v\d+\.\d+\.\d+$' } |
        ForEach-Object { 
            $versionString = $_.Name -replace '^v', ''
            try {
                [version]$versionString | Out-Null
                $_.Name
            } catch {
                # Skip invalid version strings
                Write-Verbose "Skipping invalid version directory: $($_.Name)"
            }
        } |
        Sort-Object { [version]($_ -replace '^v', '') } -Descending

    # Update cache
    Save-InstalledVersionsCache

    return $installedVersions
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
            Write-NvmColoredText "✓" "M"
        }
        else {
            Write-Host ""
        }
    }

    # Show global version (always shown with →)
    $globalVersion = $defaultVersion
    if ($globalVersion) {
        $label = "global:"
        $padding = " " * (14 - $label.Length)  # Fixed padding for labels
        $formattedVersion = Format-Version $globalVersion
        $lineContent = "→ $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length  # No checkmark for global
        $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

        # Color output: → in cyan, label in gray, version in cyan (no checkmark for global)
        Write-NvmColoredText "→" "c" -NoNewline
        Write-NvmColoredText " $label$padding" "e" -NoNewline
        Write-NvmColoredText "$formattedVersion" "c" -NoNewline
        Write-Host "$finalSpaces"
    }

    # Show latest version
    if ($latestVersion) {
        $isInstalled = $installedVersions -contains $latestVersion
        $label = "latest:"
        $padding = " " * (14 - $label.Length)
        $formattedVersion = Format-Version $latestVersion
        $lineContent = "  $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length - ($isInstalled ? 1 : 0)
        $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

        Write-Host "  " -NoNewline
        Write-NvmColoredText "$label$padding" "e" -NoNewline
        Write-NvmColoredText "$formattedVersion" "c" -NoNewline  # Cyan for latest
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
        $name = $lts.lts.ToLower()
        $label = "lts/$name`:" 
        $padding = " " * (14 - $label.Length)
        $formattedVersion = Format-Version $lts.version
        $lineContent = "  $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length - ($isInstalled ? 1 : 0)
        $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

        Write-Host "  " -NoNewline
        Write-NvmColoredText "$label$padding" "y" -NoNewline  # Yellow for LTS labels
        Write-NvmColoredText "$formattedVersion" "e" -NoNewline  # Gray for LTS versions
        Write-Host "$finalSpaces" -NoNewline
        if ($isInstalled) {
            Write-NvmColoredText "✓" "G"
        }
        else {
            Write-Host ""
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
        $padding = " " * (14 - $label.Length)
        $formattedVersion = Format-Version $nvmrcVersion
        $lineContent = "  $label$padding$formattedVersion"
        $spacesNeeded = $totalWidth - $lineContent.Length - 1  # Always show indicator
        $finalSpaces = " " * [Math]::Max(1, $spacesNeeded)

        # Color indicator
        if ($isCurrent) {
            Write-NvmColoredText "▶" "Y" -NoNewline
        }
        else {
            Write-NvmColoredText "ϟ" "Y" -NoNewline
        }
        Write-NvmColoredText " $label$padding" "m" -NoNewline  # Purple for .nvmrc label
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

# Función para obtener versiones remotas
function Show-RemoteVersions {
    try {
        $versions = Get-NvmVersionsWithCache
        $versions | ForEach-Object { Write-Host $_.version }
    }
    catch {
        Write-NvmError "Failed to fetch remote versions: $($_.Exception.Message)"
    }
}

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

# Función para crear enlaces simbólicos para la versión activa
function Set-NvmSymlinks {
    param([string]$Version)

    $currentDir = "$NVM_DIR\current"
    $versionDir = "$NVM_DIR\$Version"

    # Crear directorio current si no existe
    if (!(Test-Path $currentDir)) {
        New-Item -ItemType Directory -Path $currentDir -Force | Out-Null
    }

    # Crear subdirectorios necesarios
    $binDir = "$currentDir\bin"
    if (!(Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    }

    # Eliminar enlaces simbólicos existentes
    Get-ChildItem -Path $binDir -File | ForEach-Object {
        if ($_.LinkType -eq "SymbolicLink") {
            Remove-Item $_.FullName -Force
        }
    }

    # Crear enlaces simbólicos para los ejecutables principales
    $executables = @("node.exe", "npm.cmd", "npx.cmd", "yarn.cmd")
    foreach ($exe in $executables) {
        $sourcePath = "$versionDir\$exe"
        $targetPath = "$binDir\$exe"

        if (Test-Path $sourcePath) {
            try {
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
            }
            catch {
                # Si falla el enlace simbólico, intentar copia (para sistemas sin privilegios)
                Copy-Item $sourcePath $targetPath -Force
            }
        }
    }

    # Crear enlace simbólico para node_modules global si existe
    $globalModulesDir = "$versionDir\node_modules"
    if (Test-Path $globalModulesDir) {
        $targetModulesDir = "$currentDir\node_modules"
        if (Test-Path $targetModulesDir) {
            Remove-Item $targetModulesDir -Recurse -Force
        }
        try {
            New-Item -ItemType SymbolicLink -Path $targetModulesDir -Target $globalModulesDir -Force | Out-Null
        }
        catch {
            # Si falla, copiar directorio
            Copy-Item $globalModulesDir $targetModulesDir -Recurse -Force
        }
    }
}

# Función para inicializar PATH con ubicación virtual
function Initialize-NvmPath {
    $currentBinDir = "$NVM_DIR\current\bin"

    # Verificar si ya está en PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$currentBinDir*") {
        $newPath = "$currentBinDir;$currentPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Output "Agregado $currentBinDir al PATH de usuario"
    }
}

# Función de inicialización automática
function Initialize-Nvm {
    # Inicializar PATH con ubicación virtual
    Initialize-NvmPath

    # Si hay una versión activa guardada, recrear enlaces simbólicos
    $activeVersion = Get-NvmActiveVersion
    if ($activeVersion -and (Test-Path "$NVM_DIR\$activeVersion")) {
        try {
            Set-NvmSymlinks $activeVersion
        }
        catch {
            # Silenciar errores durante inicialización
        }
    }
    elseif ($env:nvm_default_version -and (Test-Path "$NVM_DIR\$env:nvm_default_version")) {
        # Si no hay versión activa pero hay versión por defecto, usarla
        try {
            Set-NvmSymlinks $env:nvm_default_version
            Set-NvmActiveVersion $env:nvm_default_version
        }
        catch {
            # Silenciar errores durante inicialización
        }
    }
}

# Función para migrar del sistema PATH al sistema de enlaces simbólicos
function Migrate-NvmToSymlinks {
    Write-Output "Migrando nvm-windows al sistema de enlaces simbólicos..."

    # Inicializar PATH con ubicación virtual
    Initialize-NvmPath

    # Obtener versión activa actual
    $currentVersion = Get-NvmCurrentVersion
    if ($currentVersion) {
        Write-Output "Configurando enlaces simbólicos para versión actual: $currentVersion"
        try {
            Set-NvmSymlinks $currentVersion
            Write-Output "✅ Migración completada"
        }
        catch {
            Write-NvmError "Error durante la migración: $($_.Exception.Message)"
            return
        }
    }
    else {
        Write-Output "No hay versión activa. Usa 'nvm use <versión>' para activar una versión."
    }

    # Limpiar PATH antiguo (opcional - pedir confirmación)
    $pathEntries = $env:PATH -split ';'
    $oldNvmPaths = $pathEntries | Where-Object { $_ -like "*$NVM_DIR\v*" -or $_ -like "*node-*-win-*" }
    if ($oldNvmPaths) {
        Write-Output ""
        Write-Output "Se encontraron las siguientes entradas antiguas en PATH:"
        $oldNvmPaths | ForEach-Object { Write-Output "  $_" }
        $confirm = Read-Host "¿Quieres limpiar estas entradas del PATH? (y/N)"
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            $cleanedPath = $pathEntries | Where-Object { $_ -notlike "*$NVM_DIR\v*" -and $_ -notlike "*node-*-win-*" } | Where-Object { $_ -ne "" }
            $env:PATH = $cleanedPath -join ';'
            [Environment]::SetEnvironmentVariable("Path", $env:PATH, "User")
            Write-Output "✅ PATH limpiado"
        }
    }
}

# Inicializar automáticamente al cargar el script
Initialize-Nvm

# Función para verificar la instalación
function Test-NvmInstallation {
    Write-Host "Verificando instalación de nvm-windows..."
    
    # Verificar NVM_DIR
    if (!(Test-Path $NVM_DIR)) {
        Write-NvmError "NVM_DIR no existe: $NVM_DIR"
        return
    }
    Write-Host "✓ NVM_DIR existe: $NVM_DIR"
    
    # Verificar versiones instaladas
    $installedVersions = Get-InstalledVersionsFromCache
    if ($installedVersions.Count -gt 0) {
        Write-Host "✓ Versiones instaladas: $($installedVersions -join ', ')"
    }
    else {
        Write-Host "! No hay versiones instaladas"
    }
    
    # Verificar versión actual
    $current = Get-NvmCurrentVersion
    if ($current) {
        Write-Host "✓ Versión actual: $current"
    }
    else {
        Write-Host "! No hay versión activa"
    }
    
    Write-Host "Verificación completada"
}

# Función para migrar instalación
function Migrate-NvmInstallation {
    Write-Host "Migrando a sistema de enlaces simbólicos..."
    # Esta es una función compleja, por ahora solo mostrar mensaje
    Write-NvmError "La migración aún no está implementada"
}

# Función para auto-actualizar
function Update-NvmSelf {
    Write-Host "Actualizando nvm-windows..."
    # Esta función requeriría descargar la última versión
    Write-NvmError "La auto-actualización aún no está implementada"
}

# Función para establecer versión por defecto
function Set-NvmDefault {
    param([string]$Version)
    
    if ([string]::IsNullOrWhiteSpace($Version)) {
        Write-NvmError "Versión es requerida"
        return
    }
    
    # Resolver alias o versión
    $resolvedVersion = Resolve-Version $Version
    if (-not $resolvedVersion) {
        return
    }
    
    # Guardar en variable de entorno
    [Environment]::SetEnvironmentVariable("nvm_default_version", $resolvedVersion, "User")
    Write-Host "Versión por defecto establecida: $resolvedVersion"
}

# Main command handling
if ($Command) {
    switch ($Command.ToLower()) {
        "help" {
            Show-Help
        }
        "install" {
            Install-Node $Version
        }
        "uninstall" {
            $force = $RemainingArgs -contains "--force"
            Uninstall-Node $Version -Force:$force
        }
        "use" {
            Use-Node $Version
        }
        "ls" {
            Show-NvmVersions
        }
        "lsu" {
            Update-NvmVersionCache
        }
        "list" {
            Show-NvmVersions
        }
        "ls-remote" {
            try {
                $versions = Get-NvmVersionsWithCache
                $versions | ForEach-Object { Write-Host $_.version }
            }
            catch {
                Write-NvmError "Failed to fetch remote versions: $($_.Exception.Message)"
            }
        }
        "current" {
            $current = Get-NvmCurrentVersion
            if ($current) {
                Write-Host $current
            }
            else {
                Write-Host "No version is currently active"
            }
        }
        "alias" {
            if ($Version -and $RemainingArgs) {
                New-NvmAlias $Version $RemainingArgs[0]
            }
            elseif ($Version) {
                # Get specific alias
                $aliasPath = "$NVM_DIR\alias\$Version"
                if (Test-Path $aliasPath) {
                    try {
                        $version = Get-Content $aliasPath -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
                        Write-Host "$Version -> $version"
                    }
                    catch {
                        Write-NvmError "Error reading alias '$Version'"
                    }
                }
                else {
                    Write-NvmError "Alias '$Version' not found"
                }
            }
            else {
                Get-NvmAliases
            }
        }
        "unalias" {
            if ($Version) {
                Remove-NvmAlias $Version
            }
            else {
                Write-NvmError "Alias name is required"
            }
        }
        "aliases" {
            Get-NvmAliases
        }
        "doctor" {
            Test-NvmInstallation
        }
        "migrate" {
            Migrate-NvmInstallation
        }
        "self-update" {
            Update-NvmSelf
        }
        "set-colors" {
            if ($Version) {
                Set-NvmColors $Version
            }
            else {
                Write-NvmError "Color string is required"
            }
        }
        "set-default" {
            if ($Version) {
                Set-NvmDefault $Version
            }
            else {
                Write-NvmError "Version is required"
            }
        }
        default {
            Write-NvmError "Unknown command: $Command"
            Write-Host "Use 'nvm help' to see available commands"
        }
    }
}
else {
    Show-Help
}