# verify-installation.ps1 - Script completo de verificación de instalación de nvm-windows
param(
    [switch]$Detailed
)

function Write-VerifyMessage {
    param([string]$Message, [string]$Type = "info")

    $icon = switch ($Type) {
        "success" { "OK" }
        "error" { "ERROR" }
        "warning" { "WARN" }
        default { "INFO" }
    }

    Write-Host "[$icon] $Message"
}

Write-Host "=== VERIFICACIÓN COMPLETA DE INSTALACIÓN NVM-WINDOWS ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar variable de entorno NVM_DIR
Write-VerifyMessage "Verificando variable de entorno NVM_DIR..."
$nvmDir = [Environment]::GetEnvironmentVariable("NVM_DIR", "User")
if ($nvmDir) {
    Write-VerifyMessage "NVM_DIR = '$nvmDir'" "success"
} else {
    Write-VerifyMessage "NVM_DIR no está configurada" "error"
}

# 2. Verificar que el directorio existe
Write-VerifyMessage "Verificando directorio de instalación..."
if ($nvmDir -and (Test-Path $nvmDir)) {
    Write-VerifyMessage "Directorio existe: $nvmDir" "success"
} else {
    Write-VerifyMessage "Directorio no existe: $nvmDir" "error"
}

# 3. Verificar archivos principales
Write-VerifyMessage "Verificando archivos principales..."
$requiredFiles = @("nvm.ps1", "nvm.cmd", "nvm-wrapper.cmd")
$missingFiles = @()

foreach ($file in $requiredFiles) {
    $filePath = Join-Path $nvmDir $file
    if (Test-Path $filePath) {
        Write-VerifyMessage "Archivo encontrado: $file" "success"
    } else {
        Write-VerifyMessage "Archivo faltante: $file" "error"
        $missingFiles += $file
    }
}

# 4. Verificar módulos
Write-VerifyMessage "Verificando módulos..."
$modulesPath = Join-Path $nvmDir "modules"
if (Test-Path $modulesPath) {
    Write-VerifyMessage "Directorio de módulos existe" "success"
    if ($Detailed) {
        $moduleFiles = Get-ChildItem -Path $modulesPath -File -Recurse | Select-Object -ExpandProperty Name
        Write-VerifyMessage "Archivos de módulos: $($moduleFiles -join ', ')" "info"
    }
} else {
    Write-VerifyMessage "Directorio de módulos no existe" "error"
}

# 5. Verificar PATH
Write-VerifyMessage "Verificando PATH..."
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$currentBin = "$nvmDir\current"
if ($currentPath -like "*$currentBin*") {
    Write-VerifyMessage "PATH configurado correctamente" "success"
} else {
    Write-VerifyMessage "PATH no contiene la entrada de nvm" "warning"
}

# 6. Verificar perfil de PowerShell
Write-VerifyMessage "Verificando perfil de PowerShell..."
$profilePath = $PROFILE
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -match "Set-Alias nvm.*nvm\.ps1") {
        Write-VerifyMessage "Alias de nvm configurado en perfil" "success"
    } else {
        Write-VerifyMessage "Alias de nvm no encontrado en perfil" "warning"
    }
} else {
    Write-VerifyMessage "Perfil de PowerShell no existe" "warning"
}

# 7. Verificar funcionalidad básica (si está disponible)
Write-VerifyMessage "Verificando funcionalidad básica..."
if ($nvmDir -and (Test-Path (Join-Path $nvmDir "nvm.ps1"))) {
    try {
        $nvmScript = Join-Path $nvmDir "nvm.ps1"
        $result = & powershell -ExecutionPolicy Bypass -NoProfile -Command "& '$nvmScript' --version 2>&1"
        if ($result -match "nvm-windows") {
            Write-VerifyMessage "Script de nvm funciona correctamente" "success"
        } else {
            Write-VerifyMessage "Script de nvm no responde correctamente" "warning"
        }
    } catch {
        Write-VerifyMessage "Error al ejecutar script de nvm: $($_.Exception.Message)" "error"
    }
} else {
    Write-VerifyMessage "No se puede verificar funcionalidad (archivos faltantes)" "error"
}

Write-Host ""
Write-Host "=== RESUMEN DE VERIFICACIÓN ===" -ForegroundColor Cyan

$errors = 0
$warnings = 0

if (-not $nvmDir) { $errors++ }
if ($nvmDir -and -not (Test-Path $nvmDir)) { $errors++ }
if ($missingFiles.Count -gt 0) { $errors++ }
if (-not (Test-Path $modulesPath)) { $errors++ }
if ($currentPath -notlike "*$currentBin*") { $warnings++ }
if (-not (Test-Path $profilePath) -or $profileContent -notmatch "Set-Alias nvm.*nvm\.ps1") { $warnings++ }

if ($errors -eq 0) {
    Write-VerifyMessage "Instalación COMPLETA y FUNCIONAL" "success"
} else {
    Write-VerifyMessage "Instalación INCOMPLETA - $errors errores encontrados" "error"
}

if ($warnings -gt 0) {
    Write-VerifyMessage "$warnings advertencias - revisar configuración" "warning"
}

Write-Host ""
Write-Host "Para aplicar todos los cambios, reinicia PowerShell." -ForegroundColor Yellow