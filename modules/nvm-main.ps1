# nvm-main.ps1 - Lógica principal y funciones de diagnóstico de NVM

# Función para verificar la instalación de NVM
function Test-NvmInstallation {
    Write-Output "Verificando instalación de nvm-windows..."

    # Verificar directorio NVM
    if (!(Test-Path $NVM_DIR)) {
        Write-NvmError "Directorio NVM no existe: $NVM_DIR"
        return
    }
    Write-Output "✓ NVM_DIR existe: $NVM_DIR"

    # Verificar versiones instaladas
    $installedVersions = Get-InstalledVersionsFromCache
    if ($installedVersions.Count -gt 0) {
        Write-Output "✓ Versiones instaladas: $($installedVersions -join ', ')"
    }
    else {
        Write-Output "! No hay versiones instaladas"
    }

    # Verificar versión actual
    $currentVersion = Get-NvmCurrentVersion
    if ($currentVersion) {
        Write-Output "✓ Versión actual: $currentVersion"
    }
    else {
        Write-Output "! No hay versión activa"
    }

    # Verificar enlaces simbólicos
    $currentDir = "$NVM_DIR\current"
    if (Test-Path $currentDir) {
        $symlinks = Get-ChildItem -Path $currentDir | Where-Object { $_.LinkType -eq "SymbolicLink" }
        if ($symlinks.Count -gt 0) {
            Write-Output "✓ Enlaces simbólicos creados: $($symlinks.Count) archivos"
        }
        else {
            Write-Output "! No hay enlaces simbólicos en $currentDir"
        }
    }
    else {
        Write-Output "! Directorio current no existe"
    }

    # Verificar conectividad
    try {
        $testResponse = Invoke-WebRequest -Uri "https://nodejs.org" -Method Head -TimeoutSec 5 -ErrorAction Stop
        Write-Output "✓ Conectividad a nodejs.org: OK"
    }
    catch {
        Write-Output "! No se puede conectar a nodejs.org"
    }

    Write-Output "Verificación completada"
}

# Función para migrar instalación
function Migrate-NvmInstallation {
    Write-Output "Migrando instalación de NVM..."

    # Verificar versión actual
    $currentVersion = Get-NvmCurrentVersion
    if ($currentVersion) {
        Write-Output "Versión actual detectada: $currentVersion"

        # Crear enlaces simbólicos
        try {
            Set-NvmSymlinks $currentVersion
            Write-Output "✓ Enlaces simbólicos creados"
        }
        catch {
            Write-NvmError "Error al crear enlaces simbólicos: $($_.Exception.Message)"
            return
        }

        # Actualizar cache
        Save-InstalledVersionsCache
        Write-Output "✓ Cache actualizado"

        Write-Output "Migración completada exitosamente"
    }
    else {
        Write-NvmError "No se pudo determinar la versión actual"
    }
}

# Función para auto-actualizar NVM
function Update-NvmSelf {
    Write-Output "Actualizando nvm-windows..."

    $repoUrl = "https://api.github.com/repos/freddyCamposeco/nvm-windows/releases/latest"

    try {
        $release = Invoke-WebRequest -Uri $repoUrl -ErrorAction Stop | ConvertFrom-Json
        $latestVersion = $release.tag_name
        $currentVersion = "v2.4-beta"  # Versión actual hardcodeada

        if ($latestVersion -ne $currentVersion) {
            Write-Output "Nueva versión disponible: $latestVersion"
            Write-Output "Descargando actualización..."

            $asset = $release.assets | Where-Object { $_.name -like "*nvm-windows*.zip" } | Select-Object -First 1
            if ($asset) {
                $downloadUrl = $asset.browser_download_url
                $tempZip = "$env:TEMP\nvm-windows-update.zip"
                $tempDir = "$env:TEMP\nvm-windows-update"

                Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -ErrorAction Stop
                Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

                # Copiar archivos actualizados (excepto directorios de versiones)
                $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
                Get-ChildItem -Path $tempDir -File | ForEach-Object {
                    Copy-Item $_.FullName -Destination $scriptDir -Force
                }

                # Limpiar
                Remove-Item $tempZip -Force
                Remove-Item $tempDir -Recurse -Force

                Write-Output "✓ nvm-windows actualizado a $latestVersion"
                Write-Output "Reinicia la terminal para aplicar los cambios"
            }
            else {
                Write-NvmError "No se encontró archivo de actualización"
            }
        }
        else {
            Write-Output "nvm-windows ya está actualizado ($currentVersion)"
        }
    }
    catch {
        Write-NvmError "Error al actualizar: $($_.Exception.Message)"
    }
}

# Función para limpiar versiones innecesarias
function Clean-NvmVersions {
    Write-Host "🧹 Analizando versiones instaladas..." -ForegroundColor Cyan

    # Obtener versiones instaladas
    $installedVersions = Get-InstalledVersionsFromCache
    if ($installedVersions.Count -eq 0) {
        Write-Host "ℹ️ No hay versiones instaladas para limpiar" -ForegroundColor Yellow
        return
    }

    # Obtener versión actualmente activa
    $currentVersion = Get-NvmCurrentVersion
    $versionsToKeep = @()

    if ($currentVersion) {
        $versionsToKeep += $currentVersion
        Write-Host "✓ Manteniendo versión actual: $currentVersion" -ForegroundColor Green
    }

    # Obtener versiones LTS instaladas
    $remoteVersions = Get-NvmVersionsWithCache
    $installedLtsVersions = @()

    foreach ($installed in $installedVersions) {
        $remoteVersion = $remoteVersions | Where-Object { $_.version -eq $installed }
        if ($remoteVersion -and $remoteVersion.lts) {
            $installedLtsVersions += $installed
            $versionsToKeep += $installed
        }
    }

    if ($installedLtsVersions.Count -gt 0) {
        Write-Host "✓ Manteniendo versiones LTS: $($installedLtsVersions -join ', ')" -ForegroundColor Green
    }

    # Identificar versiones a eliminar
    $versionsToRemove = $installedVersions | Where-Object { $_ -notin $versionsToKeep }

    if ($versionsToRemove.Count -eq 0) {
        Write-Host "ℹ️ No hay versiones innecesarias para eliminar" -ForegroundColor Yellow
        return
    }

    Write-Host "`n🗑️ Versiones que serán eliminadas:" -ForegroundColor Red
    foreach ($version in $versionsToRemove) {
        Write-Host "  - $version" -ForegroundColor Red
    }

    # Pedir confirmación
    $confirmation = Read-Host "`n¿Desea continuar con la eliminación? (y/N)"
    if ($confirmation -notmatch "^[yY]([eE][sS])?$") {
        Write-Host "Operación cancelada" -ForegroundColor Yellow
        return
    }

    # Eliminar versiones
    $removedCount = 0
    foreach ($version in $versionsToRemove) {
        $versionPath = "$NVM_DIR\$version"
        try {
            Remove-Item -Path $versionPath -Recurse -Force -ErrorAction Stop
            Write-Host "✓ Eliminada: $version" -ForegroundColor Green
            $removedCount++
        }
        catch {
            Write-NvmError "Error eliminando $version`: $($_.Exception.Message)"
        }
    }

    # Limpiar cache
    Update-NvmVersionCache

    Write-Host "`n✅ Limpieza completada: $removedCount versiones eliminadas" -ForegroundColor Green
}

# Función principal que maneja los comandos
function Invoke-NvmMain {
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Args = @()
    )

    # Parsear argumentos usando la función del módulo utils
    $parsedArgs = Parse-NvmArguments $Args
    $Command = $parsedArgs.Command
    $Version = $parsedArgs.Version
    $RemainingArgs = $parsedArgs.RemainingArgs

    # Procesar comando
    if ($Command) {
        switch ($Command.ToLower()) {
            "help" {
                Show-Help
            }
            "install" {
                Install-Node $Version
            }
            "uninstall" {
                $force = $RemainingArgs -contains "--force"
                Uninstall-Node $Version -Force:$force
            }
            "use" {
                Use-Node $Version
            }
            "ls" {
                Show-NvmVersions
            }
            "lsu" {
                Update-NvmVersionCache
            }
            "list" {
                Show-NvmVersions
            }
            "ls-remote" {
                Show-RemoteVersions
            }
            "current" {
                Show-CurrentVersion
            }
            "alias" {
                if ($Version -and $RemainingArgs) {
                    New-NvmAlias $Version $RemainingArgs[0]
                }
                elseif ($Version) {
                    # Get specific alias
                    $aliasPath = "$NVM_DIR\alias\$Version"
                    if (Test-Path $aliasPath) {
                        try {
                            $version = Get-Content $aliasPath -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
                            Write-Host "$Version -> $version"
                        }
                        catch {
                            Write-NvmError "Error reading alias '$Version'"
                        }
                    }
                    else {
                        Write-NvmError "Alias '$Version' not found"
                    }
                }
                else {
                    Get-NvmAliases
                }
            }
            "unalias" {
                if ($Version) {
                    Remove-NvmAlias $Version
                }
                else {
                    Write-NvmError "Alias name is required"
                }
            }
            "aliases" {
                Get-NvmAliases
            }
            "doctor" {
                Test-NvmInstallation
            }
            "migrate" {
                Migrate-ToSymlinks
            }
            "self-update" {
                Update-NvmSelf
            }
            "cleanup" {
                Clean-NvmVersions
            }
            "set-colors" {
                if ($Version) {
                    Set-NvmColors $Version
                }
                else {
                    Write-NvmError "Color string is required"
                }
            }
            "set-default" {
                if ($Version) {
                    Set-NvmDefaultVersion $Version
                }
                else {
                    Write-NvmError "Version is required"
                }
            }
            default {
                Write-NvmError "Unknown command: $Command"
                Write-Host "Use 'nvm help' to see available commands"
            }
        }
    }
    else {
        Show-Help
    }
}