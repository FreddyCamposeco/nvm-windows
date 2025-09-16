# nvm.ps1 - Node Version Manager para Windows (PowerShell) v2.4-beta
# Equivalente a nvm.sh para sistemas Windows nativos

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ScriptArgs = @()
)

# Importar módulos
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\modules\nvm-config.ps1"
. "$ScriptDir\modules\nvm-utils.ps1"
. "$ScriptDir\modules\nvm-versions.ps1"
. "$ScriptDir\modules\nvm-install.ps1"
. "$ScriptDir\modules\nvm-use.ps1"
. "$ScriptDir\modules\nvm-aliases.ps1"
. "$ScriptDir\modules\nvm-main.ps1"

# Ejecutar lógica principal
Invoke-NvmMain -Args $ScriptArgs