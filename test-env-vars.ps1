# test-env-vars.ps1 - Script de prueba para validar gestión de variables de entorno
param(
    [switch]$TestSet,
    [switch]$TestRemove
)

function Test-EnvironmentVariable {
    param([string]$Name, [string]$ExpectedValue = $null)

    $currentValue = [Environment]::GetEnvironmentVariable($Name, "User")
    if ($ExpectedValue) {
        if ($currentValue -eq $ExpectedValue) {
            Write-Host "OK $Name = '$currentValue' (correcto)" -ForegroundColor Green
        } else {
            Write-Host "ERROR $Name = '$currentValue' (esperado: '$ExpectedValue')" -ForegroundColor Red
        }
    } else {
        if ($currentValue) {
            Write-Host "INFO $Name = '$currentValue'" -ForegroundColor Yellow
        } else {
            Write-Host "OK $Name no esta configurada" -ForegroundColor Green
        }
    }
}

Write-Host "=== PRUEBA DE VARIABLES DE ENTORNO NVM ===" -ForegroundColor Cyan

if ($TestSet) {
    Write-Host "`nConfigurando variables de entorno..." -ForegroundColor Yellow

    # Simular configuración de variables
    [Environment]::SetEnvironmentVariable("NVM_DIR", "$env:USERPROFILE\.nvm", "User")
    [Environment]::SetEnvironmentVariable("NVM_NO_COLOR", "1", "User")
    [Environment]::SetEnvironmentVariable("NVM_COLORS", "red,green,blue", "User")

    Write-Host "Variables configuradas." -ForegroundColor Green
}

if ($TestRemove) {
    Write-Host "`nEliminando variables de entorno..." -ForegroundColor Yellow

    # Simular eliminación de variables
    [Environment]::SetEnvironmentVariable("NVM_DIR", $null, "User")
    [Environment]::SetEnvironmentVariable("NVM_NO_COLOR", $null, "User")
    [Environment]::SetEnvironmentVariable("NVM_COLORS", $null, "User")

    Write-Host "Variables eliminadas." -ForegroundColor Green
}

Write-Host "`nVerificando estado actual..." -ForegroundColor Yellow
Test-EnvironmentVariable "NVM_DIR" "$env:USERPROFILE\.nvm"
Test-EnvironmentVariable "NVM_NO_COLOR"
Test-EnvironmentVariable "NVM_COLORS"

Write-Host "`n=== FIN DE PRUEBA ===" -ForegroundColor Cyan