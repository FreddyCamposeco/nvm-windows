# install-nvm.ps1 - Script de instalación para nvm-windows v2.5
param(
    [switch]$Uninstall,
    [switch]$SkipLtsInstall
)

function Write-InstallMessage {
    param([string]$Message, [string]$Type = "info")

    $icon = switch ($Type) {
        "success" { "OK" }
        "error" { "ERROR" }
        "warning" { "WARN" }
        default { "INFO" }
    }

    Write-Host "[$icon] $Message"
}

function Install-Nvm {
    Write-InstallMessage "Instalando nvm-windows v2.4-beta..."

    # Determinar directorio de instalación
    $NvmDir = $env:NVM_DIR
    if (-not $NvmDir) {
        $NvmDir = "$env:USERPROFILE\.nvm"
    }

    # SIEMPRE configurar NVM_DIR como variable de entorno persistente
    Set-NvmEnvironmentVariable -Name "NVM_DIR" -Value $NvmDir -Description "Directorio de instalación de nvm-windows"

    Write-InstallMessage "Directorio de instalación: $NvmDir"

    # Crear directorio si no existe
    if (-not (Test-Path $NvmDir)) {
        New-Item -ItemType Directory -Path $NvmDir -Force | Out-Null
        Write-InstallMessage "Directorio creado: $NvmDir"
    }

    # Copiar archivos principales
    $ScriptDir = if ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $null
    }

    # Si no se puede determinar el directorio del script, intentar usar el directorio actual
    if (-not $ScriptDir -or -not (Test-Path $ScriptDir)) {
        $ScriptDir = Get-Location
        Write-InstallMessage "Usando directorio actual como fuente: $ScriptDir" "warning"
    }

    Write-InstallMessage "Directorio fuente: $ScriptDir"

    $filesToCopy = @("nvm.ps1", "nvm.cmd", "nvm-wrapper.cmd")

    foreach ($file in $filesToCopy) {
        $source = Join-Path $ScriptDir $file
        $destination = Join-Path $NvmDir $file

        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $destination -Force
            Write-InstallMessage "Copiado: $file"
        } else {
            Write-InstallMessage "Archivo no encontrado: $file" "warning"
        }
    }

    # Copiar módulos
    $modulesSource = Join-Path $ScriptDir "modules"
    $modulesDest = Join-Path $NvmDir "modules"

    if (Test-Path $modulesSource) {
        Copy-Item -Path $modulesSource -Destination $modulesDest -Recurse -Force
        Write-InstallMessage "Módulos copiados"
    }

    # Configurar alias en perfil de PowerShell
    $profilePath = $PROFILE

    # Crear directorio del perfil si no existe
    $profileDir = Split-Path -Parent $profilePath
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        Write-InstallMessage "Directorio del perfil creado: $profileDir"
    }

    $nvmAlias = "Set-Alias nvm `"$NvmDir\nvm.ps1`""
    # Agregar alias solo si no existe ya una línea igual (lógica robusta)
    $aliasExists = $false
    if (Test-Path $profilePath) {
        $aliasExists = (Get-Content $profilePath | Where-Object { $_ -match 'Set-Alias\s+nvm.*nvm\\.ps1' }).Count -gt 0
    }
    if (-not $aliasExists) {
        Add-Content -Path $profilePath -Value $nvmAlias
        Write-InstallMessage "Alias configurado en perfil de PowerShell"
        Write-InstallMessage "Reinicia PowerShell para que el alias tome efecto" "warning"
    } else {
        Write-InstallMessage "Alias ya existe en perfil de PowerShell"
    }

    # Agregar al PATH si no está
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $currentBin = "$NvmDir\current"  # Ejecutables están en el directorio raíz, no en \bin

    if ($currentPath -notlike "*$([regex]::Escape($currentBin))*") {
        $newPath = "$currentPath;$currentBin"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-InstallMessage "PATH actualizado (requiere reinicio de PowerShell)"
    }

    Write-InstallMessage "Instalación completada!" "success"
    Write-InstallMessage "Ejecuta: nvm doctor" "info"

    # Preguntar si se desea instalar Node.js LTS
    if (-not $SkipLtsInstall) {
        $defaultLts = 'n'
        try {
            $installLts = Read-Host "¿Deseas instalar Node.js LTS automáticamente? (s/n) [n]"
        } catch { $installLts = $defaultLts }
        if ([string]::IsNullOrWhiteSpace($installLts)) { $installLts = $defaultLts }
        if ($installLts -eq "s" -or $installLts -eq "S") {
            Write-InstallMessage "Instalando Node.js LTS automáticamente..."
            try {
                $nvmScript = Join-Path $NvmDir "nvm.ps1"
                & $nvmScript install lts 2>&1
                Write-InstallMessage "Node.js LTS instalado!" "success"
            }
            catch {
                Write-InstallMessage "No se pudo instalar LTS automáticamente. Instálalo manualmente con: nvm install lts" "warning"
            }
        }
        else {
            Write-InstallMessage "Instalación de Node.js LTS omitida. Puedes instalarlo manualmente con: nvm install lts" "info"
        }
    }

    # Configurar variables de entorno opcionales
    if ($NoColor) {
        Set-NvmEnvironmentVariable -Name "NVM_NO_COLOR" -Value "1" -Description "Deshabilita colores en la salida de nvm"
    }
    if ($Colors) {
        Set-NvmEnvironmentVariable -Name "NVM_COLORS" -Value $Colors -Description "Configura colores personalizados para nvm"
    }
}

function Uninstall-Nvm {
    Write-InstallMessage "Desinstalando nvm-windows..."

                # Remove-NvmEnvironmentVariable "NVM_DEFAULT_VERSION"  # Eliminado para unificar manejo
    $NvmDir = $env:NVM_DIR
    if (-not $NvmDir) {
        $NvmDir = "$env:USERPROFILE\.nvm"
    }

    # PRIMERO: Limpiar configuraciones del sistema (antes de eliminar archivos)
    Write-InstallMessage "Limpiando configuraciones del sistema..."

    # Remover del PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $currentBin = "$NvmDir\current"  # Ejecutables están en el directorio raíz, no en \bin
    if ($currentPath -like "*$currentBin*") {
        $escapedBin = [regex]::Escape($currentBin)
        $newPath = $currentPath -replace (";$escapedBin", "") -replace ("$escapedBin;", "")
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-InstallMessage "Removido del PATH"
    } else {
        Write-InstallMessage "No se encontró entrada en PATH"
    }

    # Remover variables de entorno relacionadas con NVM
    Remove-NvmEnvironmentVariable "NVM_DIR"
    Remove-NvmEnvironmentVariable "NVM_NO_COLOR"
    Remove-NvmEnvironmentVariable "NVM_COLORS"
    Remove-NvmEnvironmentVariable "NVM_DEFAULT_VERSION"

    # Remover alias del perfil usando la misma lógica que fix/remove-line.ps1
    $profilePath = $PROFILE
    if (Test-Path $profilePath) {
        $lines = Get-Content $profilePath
        $filtered = $lines | Where-Object { $_ -notmatch 'Set-Alias\s+nvm.*nvm\\.ps1' }
        Set-Content -Path $profilePath -Value $filtered
        Write-InstallMessage "Alias de nvm removido del perfil de PowerShell"
    } else {
        Write-InstallMessage "Perfil de PowerShell no encontrado"
    }

    # SEGUNDO: Preguntar si eliminar versiones instaladas (DESPUÉS de limpiar configuraciones)
    $defaultDelete = 'n'
    try {
        $deleteVersions = Read-Host "¿Eliminar todas las versiones instaladas de Node.js? (s/n) [n]"
    } catch { $deleteVersions = $defaultDelete }
    if ([string]::IsNullOrWhiteSpace($deleteVersions)) { $deleteVersions = $defaultDelete }
    $shouldDeleteVersions = ($deleteVersions -eq "s" -or $deleteVersions -eq "S")

    # Eliminar archivos/directorios según la selección del usuario
    if ($shouldDeleteVersions) {
        if (Test-Path $NvmDir) {
            Remove-Item -Path $NvmDir -Recurse -Force
            Write-InstallMessage "Directorio de nvm eliminado completamente"
        }
    } else {
        # Solo eliminar archivos principales, mantener versiones
        $filesToRemove = @("nvm.ps1", "nvm.cmd", "nvm-wrapper.cmd")
        foreach ($file in $filesToRemove) {
            $filePath = Join-Path $NvmDir $file
            if (Test-Path $filePath) {
                Remove-Item -Path $filePath -Force
            }
        }

        $modulesPath = Join-Path $NvmDir "modules"
        if (Test-Path $modulesPath) {
            Remove-Item -Path $modulesPath -Recurse -Force
        }

        Write-InstallMessage "Archivos principales eliminados, versiones conservadas"
    }

    Write-InstallMessage "Desinstalación completada!" "success"
    Write-InstallMessage "Reinicia PowerShell para que los cambios tomen efecto" "warning"
}

# Función para configurar variables de entorno de manera persistente
# Uso: Set-NvmEnvironmentVariable -Name "NVM_DIR" -Value "C:\Users\User\.nvm" -Description "Directorio de instalación de nvm-windows"
function Set-NvmEnvironmentVariable {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$Value,
        [string]$Description = ""
    )

    $currentValue = [Environment]::GetEnvironmentVariable($Name, "User")
    if ($currentValue -ne $Value) {
        [Environment]::SetEnvironmentVariable($Name, $Value, "User")
        if ($Description) {
            $message = "Variable de entorno $Name configurada: $Description"
        } else {
            $message = "Variable de entorno $Name configurada: $Value"
        }
        Write-InstallMessage $message
    } else {
        Write-InstallMessage "Variable de entorno $Name ya está configurada correctamente"
    }
}

# Función para eliminar variables de entorno de manera persistente
# Uso: Remove-NvmEnvironmentVariable "NVM_DIR"
function Remove-NvmEnvironmentVariable {
    param([string]$Name)

    $currentValue = [Environment]::GetEnvironmentVariable($Name, "User")
    if ($currentValue) {
        [Environment]::SetEnvironmentVariable($Name, $null, "User")
        Write-InstallMessage "Variable de entorno $Name eliminada"
    }
}

# Main logic
if ($Uninstall) {
    Uninstall-Nvm
} else {
    Install-Nvm
}