# Verificación básica de nvm-windows
Write-Host "VERIFICACION BASICA DE NVM-WINDOWS" -ForegroundColor Cyan
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

# Probar nvm doctor
Write-Host ""
Write-Host "Probando nvm doctor..." -ForegroundColor Yellow
try {
    $doctorOutput = & "$nvmDir\nvm.ps1" doctor 2>&1
    Write-Host "nvm doctor funciona!" -ForegroundColor Green
} catch {
    Write-Host "Error en nvm doctor" -ForegroundColor Red
}

Write-Host ""
Write-Host "FIN" -ForegroundColor Cyan