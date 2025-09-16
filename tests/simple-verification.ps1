# simple-verification.ps1 - Verificación simple de nvm-windows
Write-Host "=== VERIFICACIÓN SIMPLE DE NVM-WINDOWS ===" -ForegroundColor Cyan
Write-Host ""

# Verificar NVM_DIR
$nvmDir = [Environment]::GetEnvironmentVariable('NVM_DIR', 'User')
Write-Host "NVM_DIR: $nvmDir" -ForegroundColor $(if ($nvmDir) { "Green" } else { "Red" })

# Verificar directorio
$dirExists = Test-Path $nvmDir
Write-Host "Directorio existe: $dirExists" -ForegroundColor $(if ($dirExists) { "Green" } else { "Red" })

# Verificar PATH
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$currentBin = "$nvmDir\current"
$pathConfigured = $userPath -like "*$currentBin*"
Write-Host "PATH configurado: $pathConfigured" -ForegroundColor $(if ($pathConfigured) { "Green" } else { "Red" })

# Verificar archivos
if ($dirExists) {
    $files = Get-ChildItem $nvmDir -Name
    Write-Host "Archivos: $($files -join ', ')" -ForegroundColor Green
}

# Probar nvm doctor
Write-Host ""
Write-Host "Probando nvm doctor..." -ForegroundColor Yellow
try {
    $doctorOutput = & "$nvmDir\nvm.ps1" doctor 2>&1
    Write-Host "nvm doctor funciona!" -ForegroundColor Green
    Write-Host "Salida:" -ForegroundColor Green
    $doctorOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} catch {
    Write-Host "Error en nvm doctor: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== FIN ===" -ForegroundColor Cyan