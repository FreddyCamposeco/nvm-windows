# nvm.ps1 - Node Version Manager para Windows (PowerShell)
# Equivalente a nvm.sh para sistemas Windows nativos

param(
    [string]$Command,
    [string]$Version
)

# Configuración
$NVM_DIR = "$env:USERPROFILE\.nvm"
$NODE_MIRROR = "https://nodejs.org/dist"
$ARCH = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { "x64" } else { "x86" }

# Función para mostrar ayuda
function Show-Help {
    Write-Output "Uso: .\nvm.ps1 <comando> [versión]"
    Write-Output "Comandos:"
    Write-Output "  install <versión>    Instala una versión de Node.js"
    Write-Output "  use <versión>        Cambia a una versión específica"
    Write-Output "  ls                   Lista versiones instaladas con colores"
    Write-Output "  list                 Lista versiones instaladas (sinónimo de ls)"
    Write-Output "  ls-remote            Lista versiones disponibles"
    Write-Output "  current              Muestra la versión actual"
    Write-Output "  alias <nombre> <versión>  Crea un alias"
    Write-Output "  unalias <nombre>     Elimina un alias"
    Write-Output "  set-colors <colores>  Establece el esquema de colores (5 caracteres)"
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
}

# Función para instalar Node.js
function Install-Node {
    param([string]$Version)
    $url = "$NODE_MIRROR/v$Version/node-v$Version-win-$ARCH.zip"
    $zipPath = "$NVM_DIR\temp\node-v$Version-win-$ARCH.zip"
    $extractPath = "$NVM_DIR\v$Version"

    if (!(Test-Path $NVM_DIR)) { New-Item -ItemType Directory -Path $NVM_DIR }
    if (!(Test-Path "$NVM_DIR\temp")) { New-Item -ItemType Directory -Path "$NVM_DIR\temp" }

    Write-Output "Descargando Node.js v$Version..."
    Invoke-WebRequest -Uri $url -OutFile $zipPath

    Write-Output "Extrayendo..."
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    Remove-Item $zipPath
    Write-Output "Node.js v$Version instalado en $extractPath"
}

# Función para usar una versión
function Use-Node {
    param([string]$Version)
    $nodePath = "$NVM_DIR\v$Version"
    if (!(Test-Path $nodePath)) {
        Write-Output "Versión no instalada. Instálala primero con: .\nvm.ps1 install $Version"
        return
    }

    # Actualizar PATH para la sesión actual
    $env:PATH = "$nodePath;$env:PATH"

    # Establecer variable de entorno para compatibilidad con Starship y otros tools
    $env:NODE_VERSION = $Version

    Write-Output "Ahora usando Node.js v$Version"
}

# Función para listar versiones instaladas
function Get-Version {
    if (!(Test-Path $NVM_DIR)) { Write-Output "No hay versiones instaladas."; return }
    Get-ChildItem -Path $NVM_DIR -Directory | Where-Object { $_.Name -match "^v\d" } | ForEach-Object { Write-Output $_.Name }
}

# Función para listar versiones remotas
function Get-RemoteVersion {
    Write-Output "Obteniendo lista de versiones disponibles..."
    $versions = Invoke-WebRequest -Uri "$NODE_MIRROR/index.json" | ConvertFrom-Json
    $versions | Select-Object -ExpandProperty version | ForEach-Object { Write-Output $_ }
}

# Función para mostrar versión actual
function Get-CurrentVersion {
    $nodePath = Get-Command node -ErrorAction SilentlyContinue
    if ($nodePath) {
        $version = & node --version
        Write-Output "Versión actual: $version"
    }
    else {
        Write-Output "Node.js no está en PATH"
    }
}

# Función para crear alias
function New-NvmAlias {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Name, [string]$Version)
    $aliasPath = "$NVM_DIR\alias\$Name"
    if (!(Test-Path "$NVM_DIR\alias")) { New-Item -ItemType Directory -Path "$NVM_DIR\alias" }
    if ($PSCmdlet.ShouldProcess("Alias '$Name'", "Crear")) {
        $Version | Out-File -FilePath $aliasPath
        Write-Output "Alias '$Name' creado para $Version"
    }
}

# Función para eliminar alias
function Remove-NvmAlias {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Name)
    $aliasPath = "$NVM_DIR\alias\$Name"
    if (Test-Path $aliasPath) {
        if ($PSCmdlet.ShouldProcess("Alias '$Name'", "Eliminar")) {
            Remove-Item $aliasPath
            Write-Output "Alias '$Name' eliminado"
        }
    }
    else {
        Write-Output "Alias '$Name' no existe"
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
                } else {
                    Write-Host $Text -ForegroundColor $psColor
                }
            } else {
                # Fallback to ANSI codes if PowerShell color conversion fails
                $coloredText = "$([char]27)[$colorCode$Text$([char]27)[0m"
                if ($NoNewline) {
                    Write-Host $coloredText -NoNewline
                } else {
                    Write-Host $coloredText
                }
            }
        } else {
            if ($NoNewline) {
                Write-Host $Text -NoNewline
            } else {
                Write-Host $Text
            }
        }
    } else {
        if ($NoNewline) {
            Write-Host $Text -NoNewline
        } else {
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
    } else {
        Write-Host "Setting colors to: $ColorString"
        Write-Host "WARNING: Colors may not display because they are not supported in this shell."
    }
}

# Función para mostrar versiones con colores (equivalente a nvm list)
function Show-NvmVersions {
    <#
    .SYNOPSIS
        Shows installed Node.js versions with color coding
    .DESCRIPTION
        Displays a formatted list of installed Node.js versions with color indicators
        for current version, installed versions, etc.
    #>
    param(
        [string]$Pattern = ""
    )

    if (!(Test-Path $NVM_DIR)) {
        Write-NvmError "No versions installed."
        return
    }

    # Get current version
    $currentVersion = Get-NvmCurrentVersion

    # Get installed versions
    $installedVersions = Get-ChildItem -Path $NVM_DIR -Directory |
        Where-Object { $_.Name -match "^v\d" } |
        Select-Object -ExpandProperty Name |
        Sort-Object

    if ($installedVersions.Count -eq 0) {
        Write-NvmError "No versions installed."
        return
    }

    # Check if system Node.js is available
    $hasSystemNode = Test-NvmSystemNode

    Write-Host ""
    Write-Host "Installed versions:"

    foreach ($version in $installedVersions) {
        $displayText = $version.PadRight(15)

        if ($version -eq $currentVersion) {
            # Current version - show with arrow
            if (Test-NvmTerminalColors) {
                $colorCode = Get-NvmColors -Index 3  # Current color
                Write-Host "-> $displayText" -ForegroundColor Green -NoNewline
                Write-Host " *" -ForegroundColor Yellow
            } else {
                Write-Host "-> $displayText *"
            }
        } else {
            # Installed version
            if (Test-NvmTerminalColors) {
                Write-Host "   $displayText" -ForegroundColor Green -NoNewline
                Write-Host " *" -ForegroundColor Yellow
            } else {
                Write-Host "   $displayText *"
            }
        }
    }

    # Show system version if available
    if ($hasSystemNode) {
        $systemVersion = Get-NvmSystemVersion
        if ($systemVersion) {
            $displayText = "system".PadRight(15)
            if ($currentVersion -eq "system") {
                if (Test-NvmTerminalColors) {
                    Write-Host "-> $displayText" -ForegroundColor Cyan -NoNewline
                    Write-Host " *" -ForegroundColor Yellow
                } else {
                    Write-Host "-> $displayText *"
                }
            } else {
                if (Test-NvmTerminalColors) {
                    Write-Host "   $displayText" -ForegroundColor Cyan -NoNewline
                    Write-Host " *" -ForegroundColor Yellow
                } else {
                    Write-Host "   $displayText *"
                }
            }
        }
    }

    Write-Host ""
    Write-Host "Use 'nvm use <version>' to switch Node.js versions"
    Write-Host ""
}

# Función auxiliar para obtener la versión actual
function Get-NvmCurrentVersion {
    $nodePath = Get-Command node -ErrorAction SilentlyContinue
    if ($nodePath) {
        try {
            $version = & node --version 2>$null
            if ($version) {
                return $version
            }
        } catch {
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
            } catch {
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

# Lógica principal
switch ($Command) {
    "install" { if ($Version) { Install-Node $Version } else { Write-Output "Especifica una versión" } }
    "use" { if ($Version) { Use-Node $Version } else { Write-Output "Especifica una versión" } }
    "ls" { Show-NvmVersions }
    "list" { Show-NvmVersions }
    "ls-remote" { Get-RemoteVersion }
    "current" { Get-CurrentVersion }
    "alias" { if ($Version -and $args[0]) { New-NvmAlias $Version $args[0] } else { Write-Output "Uso: alias <nombre> <versión>" } }
    "unalias" { if ($Version) { Remove-NvmAlias $Version } else { Write-Output "Especifica un alias" } }
    "set-colors" { if ($Version) { Set-NvmColors $Version } else { Write-Output "Uso: set-colors <colores>" } }
    "help" { Show-Help }
    default { Show-Help }
}
