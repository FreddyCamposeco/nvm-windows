# verify-complete-installation.ps1 - Verificación completa de instalación de nvm-windows
Write-Host "=== VERIFICACIÓN COMPLETA DE NVM-WINDOWS ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar variables de entorno
Write-Host "1. Variables de entorno:" -ForegroundColor Yellow
$nvmDir = [Environment]::GetEnvironmentVariable('NVM_DIR', 'User')
$nvmNoColor = [Environment]::GetEnvironmentVariable('NVM_NO_COLOR', 'User')
$nvmColors = [Environment]::GetEnvironmentVariable('NVM_COLORS', 'User')

Write-Host "   NVM_DIR: $nvmDir" -ForegroundColor $(if ($nvmDir) { "Green" } else { "Red" })
Write-Host "   NVM_NO_COLOR: $nvmNoColor" -ForegroundColor $(if (-not $nvmNoColor) { "Green" } else { "Yellow" })
Write-Host "   NVM_COLORS: $nvmColors" -ForegroundColor $(if (-not $nvmColors) { "Green" } else { "Yellow" })

# 2. Verificar directorio de instalación
Write-Host ""
Write-Host "2. Directorio de instalación:" -ForegroundColor Yellow
$dirExists = Test-Path $nvmDir
Write-Host "   Directorio existe: $dirExists" -ForegroundColor $(if ($dirExists) { "Green" } else { "Red" })

if ($dirExists) {
    $files = Get-ChildItem $nvmDir -Name
    Write-Host "   Archivos encontrados: $($files -join ', ')" -ForegroundColor Green
}

# 3. Verificar PATH
Write-Host ""
Write-Host "3. Configuración PATH:" -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$currentBin = "$nvmDir\current"
$pathConfigured = $userPath -like "*$currentBin*"
Write-Host "   PATH configurado: $pathConfigured" -ForegroundColor $(if ($pathConfigured) { "Green" } else { "Red" })

# 4. Verificar alias
Write-Host ""
Write-Host "4. Alias de PowerShell:" -ForegroundColor Yellow
$profilePath = $PROFILE
$aliasExists = $false
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    $aliasExists = $profileContent -like "*Set-Alias nvm*"
}
Write-Host "   Alias configurado: $aliasExists" -ForegroundColor $(if ($aliasExists) { "Green" } else { "Red" })

# 5. Probar funcionalidad básica
Write-Host ""
Write-Host "5. Prueba de funcionalidad:" -ForegroundColor Yellow
try {
    $doctorOutput = & "$nvmDir\nvm.ps1" doctor 2>&1
    $doctorWorks = $doctorOutput -like "*NVM Doctor*"
    Write-Host "   Comando 'nvm doctor': $doctorWorks" -ForegroundColor $(if ($doctorWorks) { "Green" } else { "Red" })

    if ($doctorWorks) {
        Write-Host "   Salida de doctor:" -ForegroundColor Green
        $doctorOutput | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
    }
} catch {
    Write-Host "   Error al ejecutar nvm doctor: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Resumen final
Write-Host ""
Write-Host "=== RESUMEN FINAL ===" -ForegroundColor Cyan
$allGood = $nvmDir -and $dirExists -and $pathConfigured -and $aliasExists -and $doctorWorks

if ($allGood) {
    Write-Host "✅ INSTALACIÓN COMPLETA Y FUNCIONAL" -ForegroundColor Green
    Write-Host ""
    Write-Host "Próximos pasos recomendados:" -ForegroundColor Yellow
    Write-Host "  1. Reinicia PowerShell para activar el alias 'nvm'" -ForegroundColor White
    Write-Host "  2. Ejecuta: nvm install lts" -ForegroundColor White
    Write-Host "  3. Ejecuta: nvm use lts" -ForegroundColor White
} else {
    Write-Host "❌ PROBLEMAS DETECTADOS - REVISAR LOGS" -ForegroundColor Red
    Write-Host "   NVM_DIR: $(if ($nvmDir) { 'OK' } else { 'FALTA' })" -ForegroundColor White
    Write-Host "   Directorio: $(if ($dirExists) { 'OK' } else { 'FALTA' })" -ForegroundColor White
    Write-Host "   PATH: $(if ($pathConfigured) { 'OK' } else { 'FALTA' })" -ForegroundColor White
    Write-Host "   Alias: $(if ($aliasExists) { 'OK' } else { 'FALTA' })" -ForegroundColor White
    Write-Host "   Doctor: $(if ($doctorWorks) { 'OK' } else { 'FALTA' })" -ForegroundColor White
}

Write-Host ""
Write-Host "=== FIN DE VERIFICACIÓN ===" -ForegroundColor Cyan