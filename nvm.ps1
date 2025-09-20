# nvm.ps1 - Node Version Manager para Windows (PowerShell) v2.5
# Equivalente a nvm.sh para sistemas Windows nativos

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

# Configurar NVM_DIR si no está definido
if (-not $env:NVM_DIR) {
    $env:NVM_DIR = "$env:USERPROFILE\.nvm"
}

# Importar módulos usando dot sourcing
$modulesPath = Join-Path $PSScriptRoot 'modules'
. (Join-Path $modulesPath 'nvm-utils.ps1')
. (Join-Path $modulesPath 'nvm-config.ps1')
. (Join-Path $modulesPath 'nvm-versions.ps1')
. (Join-Path $modulesPath 'nvm-aliases.ps1')
. (Join-Path $modulesPath 'nvm-install.ps1')
. (Join-Path $modulesPath 'nvm-use.ps1')
. (Join-Path $modulesPath 'nvm-main.ps1')

# Ejecutar el comando principal usando la función del módulo
try {
    Invoke-NvmMain -Args $Args
}
catch {
    Write-NvmError "Error ejecutando comando: $($_.Exception.Message)"
}