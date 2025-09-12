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
    Write-Host "Uso: .\nvm.ps1 <comando> [versión]"
    Write-Host "Comandos:"
    Write-Host "  install <versión>    Instala una versión de Node.js"
    Write-Host "  use <versión>        Cambia a una versión específica"
    Write-Host "  ls                   Lista versiones instaladas"
    Write-Host "  ls-remote            Lista versiones disponibles"
    Write-Host "  current              Muestra la versión actual"
    Write-Host "  alias <nombre> <versión>  Crea un alias"
    Write-Host "  unalias <nombre>     Elimina un alias"
    Write-Host "  help                 Muestra esta ayuda"
}

# Función para instalar Node.js
function Install-Node {
    param([string]$Version)
    $url = "$NODE_MIRROR/v$Version/node-v$Version-win-$ARCH.zip"
    $zipPath = "$NVM_DIR\temp\node-v$Version-win-$ARCH.zip"
    $extractPath = "$NVM_DIR\v$Version"

    if (!(Test-Path $NVM_DIR)) { New-Item -ItemType Directory -Path $NVM_DIR }
    if (!(Test-Path "$NVM_DIR\temp")) { New-Item -ItemType Directory -Path "$NVM_DIR\temp" }

    Write-Host "Descargando Node.js v$Version..."
    Invoke-WebRequest -Uri $url -OutFile $zipPath

    Write-Host "Extrayendo..."
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    Remove-Item $zipPath
    Write-Host "Node.js v$Version instalado en $extractPath"
}

# Función para usar una versión
function Use-Node {
    param([string]$Version)
    $nodePath = "$NVM_DIR\v$Version"
    if (!(Test-Path $nodePath)) {
        Write-Host "Versión no instalada. Instálala primero con: .\nvm.ps1 install $Version"
        return
    }

    # Actualizar PATH para la sesión actual
    $env:PATH = "$nodePath;$env:PATH"

    # Establecer variable de entorno para compatibilidad con Starship y otros tools
    $env:NODE_VERSION = $Version

    Write-Host "Ahora usando Node.js v$Version"
}

# Función para listar versiones instaladas
function List-Versions {
    if (!(Test-Path $NVM_DIR)) { Write-Host "No hay versiones instaladas."; return }
    Get-ChildItem -Path $NVM_DIR -Directory | Where-Object { $_.Name -match "^v\d" } | ForEach-Object { Write-Host $_.Name }
}

# Función para listar versiones remotas
function List-Remote {
    Write-Host "Obteniendo lista de versiones disponibles..."
    $versions = Invoke-WebRequest -Uri "$NODE_MIRROR/index.json" | ConvertFrom-Json
    $versions | Select-Object -ExpandProperty version | ForEach-Object { Write-Host $_ }
}

# Función para mostrar versión actual
function Current-Version {
    $nodePath = Get-Command node -ErrorAction SilentlyContinue
    if ($nodePath) {
        $version = & node --version
        Write-Host "Versión actual: $version"
    } else {
        Write-Host "Node.js no está en PATH"
    }
}

# Función para crear alias
function Set-Alias {
    param([string]$Name, [string]$Version)
    $aliasPath = "$NVM_DIR\alias\$Name"
    if (!(Test-Path "$NVM_DIR\alias")) { New-Item -ItemType Directory -Path "$NVM_DIR\alias" }
    $Version | Out-File -FilePath $aliasPath
    Write-Host "Alias '$Name' creado para v$Version"
}

# Función para eliminar alias
function Remove-Alias {
    param([string]$Name)
    $aliasPath = "$NVM_DIR\alias\$Name"
    if (Test-Path $aliasPath) {
        Remove-Item $aliasPath
        Write-Host "Alias '$Name' eliminado"
    } else {
        Write-Host "Alias '$Name' no existe"
    }
}

# Lógica principal
switch ($Command) {
    "install" { if ($Version) { Install-Node $Version } else { Write-Host "Especifica una versión" } }
    "use" { if ($Version) { Use-Node $Version } else { Write-Host "Especifica una versión" } }
    "ls" { List-Versions }
    "ls-remote" { List-Remote }
    "current" { Current-Version }
    "alias" { if ($args[1]) { Set-Alias $args[0] $args[1] } else { Write-Host "Uso: alias <nombre> <versión>" } }
    "unalias" { if ($args[0]) { Remove-Alias $args[0] } else { Write-Host "Especifica un alias" } }
    "help" { Show-Help }
    default { Show-Help }
}