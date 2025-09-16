# nvm.ps1 - Node Version Manager para Windows (PowerShell) v2.4-beta
# Equivalente a nvm.sh para sistemas Windows nativos

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

# Configurar NVM_DIR si no está definido
if (-not $env:NVM_DIR) {
    $env:NVM_DIR = "$env:USERPROFILE\.nvm"
}

# Función básica para doctor
function Invoke-NvmDoctor {
    Write-Host "=== NVM Doctor ===" -ForegroundColor Cyan
    Write-Host ""

    # Verificar NVM_DIR
    if ($env:NVM_DIR) {
        Write-Host "NVM_DIR: $env:NVM_DIR" -ForegroundColor Green
        if (Test-Path $env:NVM_DIR) {
            Write-Host "Estado: Directorio existe" -ForegroundColor Green
        } else {
            Write-Host "Estado: Directorio NO existe" -ForegroundColor Red
        }
    } else {
        Write-Host "NVM_DIR: No configurado" -ForegroundColor Red
    }

    # Verificar PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $currentBin = "$env:NVM_DIR\current"
    if ($currentPath -like "*$currentBin*") {
        Write-Host "PATH: Configurado correctamente" -ForegroundColor Green
    } else {
        Write-Host "PATH: No configurado" -ForegroundColor Red
    }

    # Verificar versiones instaladas
    if (Test-Path $env:NVM_DIR) {
        $versions = Get-ChildItem -Path $env:NVM_DIR -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^v\d+\.\d+\.\d+$' } |
            Select-Object -ExpandProperty Name

        Write-Host "Versiones instaladas: $($versions.Count)" -ForegroundColor Yellow
        if ($versions.Count -gt 0) {
            Write-Host "Lista: $($versions -join ', ')" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "=== Fin del diagnostico ===" -ForegroundColor Cyan
}

# Procesar argumentos
if ($Args.Count -eq 0) {
    Write-Host "Uso: nvm <comando> [opciones]" -ForegroundColor Yellow
    Write-Host "Comandos disponibles: install, use, list, doctor, etc." -ForegroundColor Yellow
    return
}

$command = $Args[0]
$commandArgs = $Args[1..($Args.Count-1)]

switch ($command) {
    "doctor" {
        Invoke-NvmDoctor
    }
    "list" {
        Write-Host "Comando 'list' no implementado en esta version simplificada" -ForegroundColor Yellow
    }
    "install" {
        Write-Host "Comando 'install' no implementado en esta version simplificada" -ForegroundColor Yellow
    }
    "use" {
        Write-Host "Comando 'use' no implementado en esta version simplificada" -ForegroundColor Yellow
    }
    default {
        Write-Host "Comando '$command' no reconocido" -ForegroundColor Red
        Write-Host "Comandos disponibles: doctor, list, install, use" -ForegroundColor Yellow
    }
}