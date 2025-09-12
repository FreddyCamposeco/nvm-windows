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
    Write-Output "  ls                   Lista versiones instaladas"
    Write-Output "  ls-remote            Lista versiones disponibles"
    Write-Output "  current              Muestra la versión actual"
    Write-Output "  alias <nombre> <versión>  Crea un alias"
    Write-Output "  unalias <nombre>     Elimina un alias"
    Write-Output "  help                 Muestra esta ayuda"
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

# Lógica principal
switch ($Command) {
    "install" { if ($Version) { Install-Node $Version } else { Write-Output "Especifica una versión" } }
    "use" { if ($Version) { Use-Node $Version } else { Write-Output "Especifica una versión" } }
    "ls" { Get-Version }
    "ls-remote" { Get-RemoteVersion }
    "current" { Get-CurrentVersion }
    "alias" { if ($Version -and $args[0]) { New-NvmAlias $Version $args[0] } else { Write-Output "Uso: alias <nombre> <versión>" } }
    "unalias" { if ($Version) { Remove-NvmAlias $Version } else { Write-Output "Especifica un alias" } }
    "help" { Show-Help }
    default { Show-Help }
}
