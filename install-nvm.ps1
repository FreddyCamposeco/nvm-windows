# install-nvm.ps1 - Script de instalación para nvm-windows
param(
    [switch]$Uninstall,
    [switch]$SkipLtsInstall
)

function Write-InstallMessage {
    param([string]$Message, [string]$Type = "info")

    $icon = switch ($Type) {
        "success" { "✅" }
        "error" { "❌" }
        "warning" { "⚠️" }
        default { "ℹ️" }
    }

    Write-Host "$icon $Message"
}

function Install-Nvm {
    Write-InstallMessage "Instalando nvm-windows v2.4-beta..."

    # Determinar directorio de instalación
    $NvmDir = $env:NVM_DIR
    if (-not $NvmDir) {
        $NvmDir = "$env:USERPROFILE\.nvm"
    }

    Write-InstallMessage "Directorio de instalación: $NvmDir"

    # Crear directorio si no existe
    if (-not (Test-Path $NvmDir)) {
        New-Item -ItemType Directory -Path $NvmDir -Force | Out-Null
        Write-InstallMessage "Directorio creado: $NvmDir"
    }

    # Copiar archivos principales
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (-not $ScriptDir -or $ScriptDir -eq $null) {
        $ScriptDir = Get-Location
    }

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
    $currentBin = "$NvmDir\current\bin"

    if ($currentPath -notlike "*$([regex]::Escape($currentBin))*") {
        $newPath = "$currentPath;$currentBin"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-InstallMessage "PATH actualizado (requiere reinicio de PowerShell)"
    }

    Write-InstallMessage "Instalación completada!" "success"
    Write-InstallMessage "Ejecuta: nvm doctor" "info"

    # Instalar LTS automáticamente si no se especificó lo contrario
    if (-not $SkipLtsInstall) {
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
}

function Uninstall-Nvm {
    Write-InstallMessage "Desinstalando nvm-windows..."

    # Determinar directorio de instalación
    $NvmDir = $env:NVM_DIR
    if (-not $NvmDir) {
        $NvmDir = "$env:USERPROFILE\.nvm"
    }

    # Remover alias del perfil
    $profilePath = $PROFILE
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
        $profileContent = $profileContent -replace "(?m)^# Alias for nvm-windows\r?\nSet-Alias nvm.*nvm\.ps1\r?\n", ""
        $profileContent | Out-File -FilePath $profilePath -Encoding UTF8 -Force
        Write-InstallMessage "Alias removido del perfil de PowerShell"
    }

    # Remover del PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $currentBin = "$NvmDir\current\bin"
    $escapedBin = [regex]::Escape($currentBin)
    $newPath = $currentPath -replace ";$escapedBin", "" -replace "$escapedBin;", ""
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-InstallMessage "Removido del PATH"

    # Preguntar si eliminar versiones instaladas
    $deleteVersions = Read-Host "¿Eliminar todas las versiones instaladas de Node.js? (s/n)"
    if ($deleteVersions -eq "s" -or $deleteVersions -eq "S") {
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

# Main logic
if ($Uninstall) {
    Uninstall-Nvm
} else {
    Install-Nvm
}