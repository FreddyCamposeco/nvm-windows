# install.ps1 - Script de instalación/desinstalación para nvm en Windows

param(
    [string]$Action = "install"
)

# Configuración
$NVM_DIR = "$env:USERPROFILE\.nvm"
$SCRIPT_URL = "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/nvm.ps1"
$CMD_URL = "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/nvm.cmd"

# Función para instalar nvm
function Install-NVM {
    Write-Host "Verificando instalación de nvm para Windows..."

    # Crear directorio si no existe
    if (!(Test-Path $NVM_DIR)) {
        New-Item -ItemType Directory -Path $NVM_DIR
        Write-Host "Directorio $NVM_DIR creado"
    }

    # Verificar y descargar script principal
    $scriptPath = "$NVM_DIR\nvm.ps1"
    if (!(Test-Path $scriptPath)) {
        Write-Host "Descargando script principal..."
        Invoke-WebRequest -Uri $SCRIPT_URL -OutFile $scriptPath
        Write-Host "Script descargado en $scriptPath"
    } else {
        Write-Host "Script principal ya existe en $scriptPath"
    }

    # Verificar y descargar wrapper cmd
    $cmdPath = "$NVM_DIR\nvm.cmd"
    if (!(Test-Path $cmdPath)) {
        Write-Host "Descargando wrapper cmd..."
        Invoke-WebRequest -Uri $CMD_URL -OutFile $cmdPath
        Write-Host "Wrapper cmd descargado en $cmdPath"
    } else {
        Write-Host "Wrapper cmd ya existe en $cmdPath"
    }

    # Agregar a PATH automáticamente si no está
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$NVM_DIR*") {
        $newPath = "$currentPath;$NVM_DIR"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "nvm agregado a PATH. Reinicia la terminal para aplicar cambios."
    } else {
        Write-Host "nvm ya está en PATH"
    }

    Write-Host "Instalación completa. Usa: nvm help"
}

# Función para desinstalar nvm
function Uninstall-NVM {
    Write-Host "Desinstalando nvm para Windows..."

    # Remover del PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -like "*$NVM_DIR*") {
        $newPath = ($currentPath -split ';' | Where-Object { $_ -ne $NVM_DIR }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "nvm removido del PATH. Reinicia la terminal para aplicar cambios."
    } else {
        Write-Host "nvm no estaba en PATH"
    }

    # Remover archivos
    $scriptPath = "$NVM_DIR\nvm.ps1"
    if (Test-Path $scriptPath) {
        Remove-Item $scriptPath
        Write-Host "Script principal removido"
    }

    $cmdPath = "$NVM_DIR\nvm.cmd"
    if (Test-Path $cmdPath) {
        Remove-Item $cmdPath
        Write-Host "Wrapper cmd removido"
    }

    # Remover directorio si está vacío
    if (Test-Path $NVM_DIR) {
        $items = Get-ChildItem $NVM_DIR
        if ($items.Count -eq 0) {
            Remove-Item $NVM_DIR
            Write-Host "Directorio $NVM_DIR removido"
        } else {
            Write-Host "Directorio $NVM_DIR no está vacío, conserva versiones instaladas"
        }
    }

    Write-Host "Desinstalación completa"
}

# Ejecutar acción
switch ($Action) {
    "install" { Install-NVM }
    "uninstall" { Uninstall-NVM }
    default { Write-Host "Uso: .\install.ps1 [install|uninstall]" }
}