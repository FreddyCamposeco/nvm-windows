# Ejemplo de Desinstalación Remota de nvm-windows
# Este script demuestra cómo desinstalar nvm-windows sin clonar el repositorio

Write-Host "=== Demostración: Desinstalación Remota de nvm-windows ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Paso 1: Descargar el script de desinstalación" -ForegroundColor Yellow
Write-Host "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/install-nvm.ps1' -OutFile 'uninstall-nvm.ps1'"
Write-Host ""

Write-Host "Paso 2: Ejecutar la desinstalación" -ForegroundColor Yellow
Write-Host ".\uninstall-nvm.ps1 -Uninstall"
Write-Host ""

Write-Host "El proceso de desinstalación incluye:" -ForegroundColor Green
Write-Host "✓ Verificación de confirmación del usuario" -ForegroundColor White
Write-Host "✓ Remoción del PATH (usuario y sistema)" -ForegroundColor White
Write-Host "✓ Eliminación de archivos principales" -ForegroundColor White
Write-Host "✓ Limpieza de alias del perfil de PowerShell" -ForegroundColor White
Write-Host "✓ Opción para eliminar versiones instaladas" -ForegroundColor White
Write-Host "✓ Mensajes de progreso detallados" -ForegroundColor White
Write-Host ""

Write-Host "Nota: Las versiones de Node.js instaladas se conservan por defecto" -ForegroundColor Yellow
Write-Host "El script pregunta si quieres eliminarlas también." -ForegroundColor Yellow
Write-Host ""

Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray