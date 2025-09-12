# install-nvm.ps1 - Instalador independiente para nvm-windows
# Descarga y configura nvm para Windows desde GitHub
# Uso: Invoke-WebRequest -Uri "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/install-nvm.ps1" -OutFile "install-nvm.ps1"; .\install-nvm.ps1

param(
    [switch]$Uninstall
)

# Configuración
$REPO_URL = "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master"
$NVM_DIR = "$env:USERPROFILE\.nvm"
$SCRIPT_URL = "$REPO_URL/nvm.ps1"
$CMD_URL = "$REPO_URL/nvm.cmd"

Write-Host "=== Instalador de nvm para Windows ===" -ForegroundColor Cyan
Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray
Write-Host ""

if ($Uninstall) {
    Write-Host "Desinstalando nvm para Windows..." -ForegroundColor Yellow

    # Remover del PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -like "*$NVM_DIR*") {
        $newPath = ($currentPath -split ';' | Where-Object { $_ -ne $NVM_DIR }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "✓ Removido del PATH" -ForegroundColor Green
    }

    # Remover archivos
    if (Test-Path "$NVM_DIR\nvm.ps1") {
        Remove-Item "$NVM_DIR\nvm.ps1"
        Write-Host "✓ Script principal removido" -ForegroundColor Green
    }
    if (Test-Path "$NVM_DIR\nvm.cmd") {
        Remove-Item "$NVM_DIR\nvm.cmd"
        Write-Host "✓ Wrapper CMD removido" -ForegroundColor Green
    }

    # Remover directorio si está vacío
    if (Test-Path $NVM_DIR) {
        $items = Get-ChildItem $NVM_DIR
        if ($items.Count -eq 0) {
            Remove-Item $NVM_DIR
            Write-Host "✓ Directorio $NVM_DIR removido" -ForegroundColor Green
        } else {
            Write-Host "⚠ Directorio $NVM_DIR no está vacío, conserva versiones instaladas" -ForegroundColor Yellow
        }
    }

    # Remover alias del perfil
    $profilePath = $PROFILE
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
        $newContent = $profileContent -replace "(?s)# Alias for nvm-windows.*?\nSet-Alias nvm.*?\n", ""
        if ($newContent -ne $profileContent) {
            $newContent | Set-Content $profilePath
            Write-Host "✓ Alias removido del perfil de PowerShell" -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host "Desinstalación completada. Reinicia la terminal." -ForegroundColor Green
    exit 0
}

# Verificar si ya está instalado
if (Test-Path "$NVM_DIR\nvm.ps1") {
    Write-Host "nvm ya está instalado en $NVM_DIR" -ForegroundColor Yellow
    $overwrite = Read-Host "¿Deseas reinstalar? (s/n)"
    if ($overwrite -ne "s" -and $overwrite -ne "S") {
        Write-Host "Instalación cancelada." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Instalando nvm para Windows..." -ForegroundColor Green

# Crear directorio
if (!(Test-Path $NVM_DIR)) {
    New-Item -ItemType Directory -Path $NVM_DIR | Out-Null
    Write-Host "✓ Directorio $NVM_DIR creado" -ForegroundColor Green
}

# Descargar script principal
Write-Host "Descargando script principal..." -ForegroundColor Gray
try {
    Invoke-WebRequest -Uri $SCRIPT_URL -OutFile "$NVM_DIR\nvm.ps1" -ErrorAction Stop
    Write-Host "✓ Script principal descargado" -ForegroundColor Green
} catch {
    Write-Host "✗ Error descargando script principal: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Descargar wrapper CMD
Write-Host "Descargando wrapper CMD..." -ForegroundColor Gray
try {
    Invoke-WebRequest -Uri $CMD_URL -OutFile "$NVM_DIR\nvm.cmd" -ErrorAction Stop
    Write-Host "✓ Wrapper CMD descargado" -ForegroundColor Green
} catch {
    Write-Host "✗ Error descargando wrapper CMD: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Agregar a PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$NVM_DIR*") {
    $newPath = "$currentPath;$NVM_DIR"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "✓ Agregado a PATH del usuario" -ForegroundColor Green
} else {
    Write-Host "✓ Ya está en PATH" -ForegroundColor Green
}

# Configurar alias en perfil
$profilePath = $PROFILE
$aliasContent = @"

# Alias for nvm-windows
Set-Alias nvm "$env:USERPROFILE\.nvm\nvm.ps1"
"@

if (!(Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notlike "*nvm-windows*") {
    Add-Content -Path $profilePath -Value $aliasContent
    Write-Host "✓ Alias 'nvm' agregado al perfil de PowerShell" -ForegroundColor Green
} else {
    Write-Host "✓ Alias ya configurado en perfil" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Instalación Completada ===" -ForegroundColor Cyan
Write-Host "✓ nvm instalado en: $NVM_DIR" -ForegroundColor Green
Write-Host "✓ Agregado al PATH" -ForegroundColor Green
Write-Host "✓ Alias configurado" -ForegroundColor Green
Write-Host ""
Write-Host "Para usar nvm:" -ForegroundColor Yellow
Write-Host "1. Reinicia PowerShell o ejecuta: & `$PROFILE" -ForegroundColor White
Write-Host "2. Prueba: nvm help" -ForegroundColor White
Write-Host "3. Instala Node.js: nvm install 18.17.0" -ForegroundColor White
Write-Host ""
Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray
Write-Host "Documentación: https://github.com/FreddyCamposeco/nvm-windows#readme" -ForegroundColor Gray