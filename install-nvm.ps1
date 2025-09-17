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

    # Leer perfil actual
    $profileContent = ""
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
    }

    # Verificar si el alias ya existe
    if ($profileContent -notmatch "Set-Alias nvm.*nvm\.ps1") {
        # Agregar alias al perfil
        $profileContent += "`n# Alias for nvm-windows`n$nvmAlias`n"
        $profileContent | Out-File -FilePath $profilePath -Encoding UTF8 -Force
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
        $installLts = Read-Host "¿Deseas instalar Node.js LTS automáticamente? (s/n)"
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

    # Determinar directorio de instalación
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

    # Remover alias del perfil
    $profilePath = $PROFILE
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw


        # Remover cualquier línea de alias nvm y comentarios relacionados (robusto, línea por línea)
        $profileLines = $profileContent -split "\r?\n|\n|\r"
        $filteredLines = $profileLines | Where-Object { -not ($_ -match '(?i)Set-Alias\s+nvm\s+.*nvm\\.ps1') -and -not ($_ -match '(?i)#.*nvm') }
        # Limpiar líneas vacías consecutivas y eliminar línea final vacía
        $cleanedLines = @()
        $lastWasEmpty = $false
        foreach ($line in $filteredLines) {
            if ($line.Trim() -eq "") {
                if (-not $lastWasEmpty) { $cleanedLines += "" }
                $lastWasEmpty = $true
            } else {
                $cleanedLines += $line
                $lastWasEmpty = $false
            }
        }
        # Eliminar línea vacía final si existe
        if ($cleanedLines.Count -gt 0 -and $cleanedLines[-1].Trim() -eq "") {
            $cleanedLines = $cleanedLines[0..($cleanedLines.Count-2)]
        }
        $profileContent = $cleanedLines -join "`r`n"

        # Remover hook de auto-switch
        $hookPattern = "(?s)# NVM Auto-Switch Hook.*?Nvm-AutoSwitch.*?}\r?\n\r?\n# Ejecutar auto-switch.*?\r?\n}"
        if ($profileContent -match $hookPattern) {
            $profileContent = $profileContent -replace $hookPattern, ""
            Write-InstallMessage "Hook de auto-switch removido del perfil"
        }

        $profileContent | Out-File -FilePath $profilePath -Encoding UTF8 -Force
        Write-InstallMessage "Alias y comentarios de nvm removidos del perfil de PowerShell"
    } else {
        Write-InstallMessage "Perfil de PowerShell no encontrado"
    }

    # SEGUNDO: Preguntar si eliminar versiones instaladas (DESPUÉS de limpiar configuraciones)
    $deleteVersions = Read-Host "¿Eliminar todas las versiones instaladas de Node.js? (s/n)"
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