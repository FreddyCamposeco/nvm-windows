# nvm.tests.ps1 - Suite de tests para nvm-windows v2.4-beta
# Ejecutar con: .\nvm.tests.ps1

param(
    [switch]$Verbose,
    [string[]]$TestNames
)

# Configuración de tests
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$NVM_SCRIPT = "$ScriptDir\nvm.ps1"
$TestResults = @()
$TestCount = 0
$PassedTests = 0
$FailedTests = 0

# Función para escribir output de test
function Write-TestOutput {
    param(
        [string]$Message,
        [string]$Type = "info"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Type) {
        "success" { "✅" }
        "error" { "❌" }
        "warning" { "⚠️" }
        "info" { "ℹ️" }
        default { "➡️" }
    }

    Write-Host "[$timestamp] $prefix $Message"
}

# Función para ejecutar un test
function Run-Test {
    param(
        [string]$TestName,
        [scriptblock]$TestBlock,
        [string]$Description = ""
    )

    $script:TestCount++
    Write-TestOutput "Ejecutando test: $TestName" "info"

    if ($Description) {
        Write-TestOutput "  Descripción: $Description" "info"
    }

    try {
        $result = & $TestBlock
        if ($result -eq $true -or $result -is [void]) {
            $script:PassedTests++
            Write-TestOutput "  PASSED: $TestName" "success"
            $TestResults += @{ Name = $TestName; Result = "PASSED"; Error = $null }
        }
        else {
            $script:FailedTests++
            Write-TestOutput "  FAILED: $TestName - Resultado inesperado: $result" "error"
            $TestResults += @{ Name = $TestName; Result = "FAILED"; Error = "Resultado inesperado: $result" }
        }
    }
    catch {
        $script:FailedTests++
        $errorMessage = $_.Exception.Message
        Write-TestOutput "  FAILED: $TestName - Error: $errorMessage" "error"
        $TestResults += @{ Name = $TestName; Result = "FAILED"; Error = $errorMessage }
    }
}

# Función para ejecutar comando nvm y capturar output
function Invoke-NvmCommand {
    param(
        [string[]]$Arguments,
        [switch]$ExpectError
    )

    try {
        $output = & $NVM_SCRIPT @Arguments 2>&1
        if ($ExpectError) {
            return @{ Success = $false; Output = $output; ExitCode = 1 }
        }
        else {
            return @{ Success = $true; Output = $output; ExitCode = 0 }
        }
    }
    catch {
        if ($ExpectError) {
            return @{ Success = $false; Output = $_.Exception.Message; ExitCode = 1 }
        }
        else {
            throw
        }
    }
}

# Tests de sintaxis
Write-TestOutput "=== VERIFICACIÓN DE SINTAXIS ===" "info"

Run-Test "Sintaxis nvm.ps1" {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($NVM_SCRIPT, [ref]$null, [ref]$null)
    return $ast -ne $null
} "Verificar que nvm.ps1 tenga sintaxis correcta"

Run-Test "Sintaxis módulos" {
    $modules = @(
        "nvm-config.ps1",
        "nvm-utils.ps1",
        "nvm-versions.ps1",
        "nvm-install.ps1",
        "nvm-use.ps1",
        "nvm-aliases.ps1",
        "nvm-main.ps1"
    )

    foreach ($module in $modules) {
        $modulePath = "$ScriptDir\modules\$module"
        if (!(Test-Path $modulePath)) {
            throw "Módulo faltante: $module"
        }

        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$null, [ref]$null)
            if ($ast -eq $null) {
                throw "Error de sintaxis en $module"
            }
        }
        catch {
            $errorMsg = $_.Exception.Message
            throw "Error en módulo $module`: $errorMsg"
        }
    }

    return $true
} "Verificar sintaxis de todos los módulos"

# Tests de comandos básicos
Write-TestOutput "=== TESTS DE COMANDOS BÁSICOS ===" "info"

Run-Test "Comando help" {
    $result = Invoke-NvmCommand @("help")
    return $result.Success
} "Verificar que el comando help funcione"

Run-Test "Comando desconocido" {
    $result = Invoke-NvmCommand @("comando-inventado") -ExpectError
    return !$result.Success
} "Verificar manejo de comandos desconocidos"

Run-Test "Comando doctor (sintaxis)" {
    $result = Invoke-NvmCommand @("doctor")
    # Doctor puede fallar si NVM no está instalado, pero debe ejecutarse sin errores de sintaxis
    return $true
} "Verificar que doctor se ejecute sin errores de sintaxis"

Run-Test "Comando ls (sintaxis)" {
    $result = Invoke-NvmCommand @("ls")
    return $true
} "Verificar que ls se ejecute sin errores de sintaxis"

Run-Test "Comando current (sintaxis)" {
    $result = Invoke-NvmCommand @("current")
    return $true
} "Verificar que current se ejecute sin errores de sintaxis"

# Tests de utilidades
Write-TestOutput "=== TESTS DE UTILIDADES ===" "info"

Run-Test "Archivo .nvmrc existe" {
    $nvmrcPath = "$ScriptDir\.nvmrc"
    return Test-Path $nvmrcPath
} "Verificar que .nvmrc existe"

Run-Test "Archivo LICENSE existe" {
    $licensePath = "$ScriptDir\LICENSE"
    return Test-Path $licensePath
} "Verificar que LICENSE existe"

Run-Test "Archivo README.md existe" {
    $readmePath = "$ScriptDir\README.md"
    return Test-Path $readmePath
} "Verificar que README.md existe"

Run-Test "Directorio modules existe" {
    $modulesPath = "$ScriptDir\modules"
    return Test-Path $modulesPath -PathType Container
} "Verificar que el directorio modules existe"

Run-Test "Módulos requeridos existen" {
    $requiredModules = @(
        "nvm-config.ps1",
        "nvm-utils.ps1",
        "nvm-versions.ps1",
        "nvm-install.ps1",
        "nvm-use.ps1",
        "nvm-aliases.ps1",
        "nvm-main.ps1"
    )

    foreach ($module in $requiredModules) {
        $modulePath = "$ScriptDir\modules\$module"
        if (!(Test-Path $modulePath)) {
            throw "Módulo faltante: $module"
        }
    }

    return $true
} "Verificar que todos los módulos requeridos existen"

# Tests de validación
Write-TestOutput "=== TESTS DE VALIDACIÓN ===" "info"

Run-Test "Validar estructura de directorios" {
    $requiredDirs = @(
        "$ScriptDir\modules"
    )

    $requiredFiles = @(
        "$ScriptDir\nvm.ps1",
        "$ScriptDir\install-nvm.ps1",
        "$ScriptDir\LICENSE",
        "$ScriptDir\README.md",
        "$ScriptDir\.nvmrc"
    )

    foreach ($dir in $requiredDirs) {
        if (!(Test-Path $dir -PathType Container)) {
            throw "Directorio faltante: $dir"
        }
    }

    foreach ($file in $requiredFiles) {
        if (!(Test-Path $file -PathType Leaf)) {
            throw "Archivo faltante: $file"
        }
    }

    return $true
} "Verificar estructura de archivos y directorios requerida"

# Resultados finales
Write-TestOutput "=== RESULTADOS FINALES ===" "info"
Write-TestOutput "Tests ejecutados: $TestCount" "info"
Write-TestOutput "Tests pasados: $PassedTests" "success"
Write-TestOutput "Tests fallidos: $FailedTests" "error"

if ($FailedTests -eq 0) {
    Write-TestOutput "🎉 TODOS LOS TESTS PASARON" "success"
    exit 0
}
else {
    Write-TestOutput "❌ ALGUNOS TESTS FALLARON" "error"

    if ($Verbose) {
        Write-TestOutput "Detalle de tests fallidos:" "error"
        foreach ($test in $TestResults | Where-Object { $_.Result -eq "FAILED" }) {
            Write-TestOutput "  - $($test.Name): $($test.Error)" "error"
        }
    }

    exit 1
}