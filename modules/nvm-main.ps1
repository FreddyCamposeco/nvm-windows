# nvm-main.ps1 - Lógica principal y funciones de diagnóstico de NVM

# Función para verificar la instalación de NVM
function Test-NvmInstallation {
    Format-NvmSectionHeader -Title "Verificando instalación de nvm-windows" -Level 1

    # Verificar directorio NVM
    if (!(Test-Path $NVM_DIR)) {
        Write-NvmError "Directorio NVM no existe: $NVM_DIR"
        return
    }
    Format-NvmInfoMessage -Message "NVM_DIR existe: $NVM_DIR" -Type "success"

    # Verificar versiones instaladas
    $installedVersions = Get-InstalledVersionsFromCache
    if ($installedVersions.Count -gt 0) {
        Format-NvmInfoMessage -Message "Versiones instaladas: $($installedVersions -join ', ')" -Type "success"
    }
    else {
        Format-NvmInfoMessage -Message "No hay versiones instaladas" -Type "warning"
    }

    # Verificar versión actual
    $currentVersion = Get-NvmCurrentVersion
    if ($currentVersion) {
        Format-NvmInfoMessage -Message "Versión actual: $currentVersion" -Type "success"
    }
    else {
        Format-NvmInfoMessage -Message "No hay versión activa" -Type "warning"
    }

    # Verificar enlaces simbólicos
    $currentDir = "$NVM_DIR\current"
    if (Test-Path $currentDir) {
        $symlinks = Get-ChildItem -Path $currentDir | Where-Object { $_.LinkType -eq "SymbolicLink" }
        if ($symlinks.Count -gt 0) {
            Format-NvmInfoMessage -Message "Enlaces simbólicos creados: $($symlinks.Count) archivos" -Type "success"
        }
        else {
            Format-NvmInfoMessage -Message "No hay enlaces simbólicos en $currentDir" -Type "warning"
        }
    }
    else {
        Format-NvmInfoMessage -Message "Directorio current no existe" -Type "warning"
    }

    # Verificar conectividad
    try {
        $testResponse = Invoke-WebRequest -Uri "https://nodejs.org" -Method Head -TimeoutSec 5 -ErrorAction Stop
        Format-NvmInfoMessage -Message "Conectividad a nodejs.org: OK" -Type "success"
    }
    catch {
        Format-NvmInfoMessage -Message "No se puede conectar a nodejs.org" -Type "error"
    }

    Format-NvmInfoMessage -Message "Verificación completada" -Type "success"
}

# Función para mostrar estadísticas del sistema NVM
function Show-NvmStats {
    $installedVersions = Get-InstalledVersionsFromCache
    $currentVersion = Get-NvmCurrentVersion
    $remoteVersions = Get-NvmVersionsWithCache

    $stats = @{
        "Versión actual" = $currentVersion ? $currentVersion : "Ninguna"
        "Versiones instaladas" = $installedVersions.Count
        "Versiones LTS disponibles" = ($remoteVersions | Where-Object { $_.lts }).Count
        "Total versiones remotas" = $remoteVersions.Count
        "Directorio NVM" = $NVM_DIR
    }

    Format-NvmStats -Stats $stats -Title "Estadísticas del Sistema NVM"
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

# Función para mostrar la versión de NVM
function Show-NvmVersion {
    Write-Output ""
    Write-Output "nvm-windows $NVM_VERSION"
    Write-Output "Node Version Manager para Windows (PowerShell)"
    Write-Output ""
    Write-Output "Repositorio: https://github.com/freddyCamposeco/nvm-windows"
    Write-Output ""
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

                # Mostrar información de descarga
                $fileSize = [math]::Round($asset.size / 1MB, 2)
                Write-Output "Tamaño: ${fileSize}MB"

                # Descargar con progreso
                Write-Progress -Activity "Actualizando nvm-windows" -Status "Descargando actualización..." -PercentComplete 0
                $ProgressPreference = 'Continue'
                Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -ErrorAction Stop
                Write-Progress -Activity "Actualizando nvm-windows" -Status "Descarga completada" -PercentComplete 50 -Completed
                
                Write-Output "Extrayendo actualización..."
                Write-Progress -Activity "Actualizando nvm-windows" -Status "Extrayendo archivos..." -PercentComplete 75
                Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
                Write-Progress -Activity "Actualizando nvm-windows" -Status "Instalando..." -PercentComplete 90
                Write-Progress -Activity "Actualizando nvm-windows" -Status "Completado" -PercentComplete 100 -Completed

                Write-Output "Instalando actualización..."

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
    Format-NvmProgress -Message "Analizando versiones instaladas..."

    # Obtener versiones instaladas
    $installedVersions = Get-InstalledVersionsFromCache
    if ($installedVersions.Count -eq 0) {
        Format-NvmInfoMessage -Message "No hay versiones instaladas para limpiar" -Type "info"
        return
    }

    # Obtener versión actualmente activa
    $currentVersion = Get-NvmCurrentVersion
    $versionsToKeep = @()

    if ($currentVersion) {
        $versionsToKeep += $currentVersion
        Format-NvmInfoMessage -Message "Manteniendo versión actual: $currentVersion" -Type "info"
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
        Format-NvmInfoMessage -Message "Manteniendo versiones LTS: $($installedLtsVersions -join ', ')" -Type "info"
    }

    # Identificar versiones a eliminar
    $versionsToRemove = $installedVersions | Where-Object { $_ -notin $versionsToKeep }

    if ($versionsToRemove.Count -eq 0) {
        Format-NvmInfoMessage -Message "No hay versiones innecesarias para eliminar" -Type "info"
        return
    }

    Format-NvmSectionHeader -Title "Versiones que serán eliminadas" -Level 2
    foreach ($version in $versionsToRemove) {
        Write-NvmColoredText "  - $version" "r"
    }

    # Pedir confirmación
    $confirmation = Read-Host "`n¿Desea continuar con la eliminación? (y/N)"
    if ($confirmation -notmatch "^[yY]([eE][sS])?$") {
        Format-NvmInfoMessage -Message "Operación cancelada" -Type "warning"
        return
    }

    # Eliminar versiones
    $removedCount = 0
    foreach ($version in $versionsToRemove) {
        $versionPath = "$NVM_DIR\$version"
        try {
            Remove-Item -Path $versionPath -Recurse -Force -ErrorAction Stop
            Format-NvmInfoMessage -Message "Eliminada: $version" -Type "success"
            $removedCount++
        }
        catch {
            Write-NvmError "Error eliminando $version`: $($_.Exception.Message)"
        }
    }

    # Limpiar cache
    Update-NvmVersionCache

    Format-NvmInfoMessage -Message "Limpieza completada: $removedCount versiones eliminadas" -Type "success"
}

# Función principal que maneja los comandos
function Invoke-NvmMain {
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Args = @()
    )

    # Manejar comando especial para el hook de auto-cambio
    if ($Args -contains "--get-nvmrc-version") {
        $version = Get-NvmrcVersionForHook
        if ($version) {
            Write-Output $version
        }
        return
    }

    # Parsear argumentos usando la función del módulo utils
    $parsedArgs = Parse-NvmArguments -Arguments $Args
    $Command = $parsedArgs.Command
    $Version = $parsedArgs.Version
    $RemainingArgs = $parsedArgs.RemainingArgs

    # Procesar comando
    if ($Command) {
        switch ($Command.ToLower()) {
            "help" {
                Show-Help
            }
            "version" {
                Show-NvmVersion
            }
            "install" {
                Install-Node $Version
            }
            "uninstall" {
                $force = $RemainingArgs -contains "--force"
                Uninstall-Node $Version -Force:$force
            }
            "use" {
                $quiet = $RemainingArgs -contains "--quiet"
                Use-Node $Version -Quiet:$quiet
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
                try {
                    $remoteVersions = Get-NvmVersionsWithCache
                    $installedVersions = Get-InstalledVersionsFromCache

                    # Crear un array de versiones instaladas para búsqueda
                    $installedArray = @()
                    foreach ($installed in $installedVersions) {
                        $installedArray += $installed
                    }

                    Write-Host "Remote versions:" -ForegroundColor Cyan
                    Write-Host "  (✓ installed, ✗ not installed, LTS name shown for LTS versions)" -ForegroundColor Gray
                    Write-Host ""

                    foreach ($version in $remoteVersions) {
                        $versionNumber = $version.version
                        $isInstalled = $installedArray -contains $versionNumber

                        # Determinar el indicador
                        $indicator = if ($isInstalled) { "✓" } else { "✗" }

                        # Determinar el nombre LTS
                        $ltsInfo = ""
                        if ($version.lts -and $version.lts -ne "false") {
                            $ltsInfo = " ($($version.lts))"
                        }

                        # Formatear la línea
                        $statusColor = if ($isInstalled) { "Green" } else { "Red" }
                        $versionColor = if ($version.lts -and $version.lts -ne "false") { "Yellow" } else { "White" }

                        Write-Host "  $indicator " -ForegroundColor $statusColor -NoNewline
                        Write-Host "$versionNumber" -ForegroundColor $versionColor -NoNewline
                        Write-Host "$ltsInfo" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-NvmError "Failed to fetch remote versions: $($_.Exception.Message)"
                }
            }
            "ls-remote-enhanced" {
                try {
                    $remoteVersions = Get-NvmVersionsWithCache
                    $installedVersions = Get-InstalledVersionsFromCache

                    # Crear un array de versiones instaladas para búsqueda
                    $installedArray = @()
                    foreach ($installed in $installedVersions) {
                        $installedArray += $installed
                    }

                    Write-Host "Remote versions:" -ForegroundColor Cyan
                    Write-Host "  (✓ installed, ✗ not installed, LTS name shown for LTS versions)" -ForegroundColor Gray
                    Write-Host ""

                    foreach ($version in $remoteVersions | Select-Object -First 20) {
                        $versionNumber = $version.version
                        $isInstalled = $installedArray -contains $versionNumber

                        # Determinar el indicador
                        $indicator = if ($isInstalled) { "✓" } else { "✗" }

                        # Determinar el nombre LTS
                        $ltsInfo = ""
                        if ($version.lts -and $version.lts -ne "false") {
                            $ltsInfo = " ($($version.lts))"
                        }

                        # Formatear la línea
                        $statusColor = if ($isInstalled) { "Green" } else { "Red" }
                        $versionColor = if ($version.lts -and $version.lts -ne "false") { "Yellow" } else { "White" }

                        Write-Host "  $indicator " -ForegroundColor $statusColor -NoNewline
                        Write-Host "$versionNumber" -ForegroundColor $versionColor -NoNewline
                        Write-Host "$ltsInfo" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-NvmError "Failed to fetch remote versions: $($_.Exception.Message)"
                }
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
            "stats" {
                Show-NvmStats
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
            "auto" {
                if ($Version -eq "on") {
                    Enable-NvmAutoSwitch
                }
                elseif ($Version -eq "off") {
                    Disable-NvmAutoSwitch
                }
                elseif ($Version -eq "status") {
                    Show-NvmAutoStatus
                }
                elseif ($Version -eq "setup") {
                    Install-NvmAutoHook
                }
                else {
                    Write-NvmError "Usage: nvm auto on|off|status|setup"
                }
            }
            default {
                Write-NvmError "Unknown command: $Command"
                Write-Host "Use 'nvm help' to see available commands"
            }
        }
    }
    elseif ($Args -and $Args.Length -gt 0) {
        # Verificar si es una opción especial no reconocida como comando
        $firstArg = $Args[0]
        if ($firstArg -eq "--version" -or $firstArg -eq "-v") {
            Show-NvmVersion
        }
        else {
            Show-Help
        }
    }
    else {
        Show-Help
    }
}

# Función para habilitar el auto-cambio de versiones con .nvmrc
function Enable-NvmAutoSwitch {
    $autoFile = "$NVM_DIR\.auto_enabled"
    try {
        "enabled" | Out-File -FilePath $autoFile -Encoding UTF8 -Force
        Write-Output "✓ Auto-cambio de versiones habilitado"
        Write-Output "Ahora se cambiará automáticamente a la versión del .nvmrc al cambiar de directorio"
        Write-Output ""
        Write-Output "Para que funcione, ejecuta:"
        Write-Output "nvm auto setup"
    }
    catch {
        Write-NvmError "Error al habilitar auto-cambio: $($_.Exception.Message)"
    }
}

# Función para deshabilitar el auto-cambio de versiones
function Disable-NvmAutoSwitch {
    $autoFile = "$NVM_DIR\.auto_enabled"
    if (Test-Path $autoFile) {
        try {
            Remove-Item $autoFile -Force
            Write-Output "✓ Auto-cambio de versiones deshabilitado"
        }
        catch {
            Write-NvmError "Error al deshabilitar auto-cambio: $($_.Exception.Message)"
        }
    }
    else {
        Write-Output "El auto-cambio ya está deshabilitado"
    }
}

# Función para mostrar el estado del auto-cambio
function Show-NvmAutoStatus {
    $autoFile = "$NVM_DIR\.auto_enabled"
    $profilePath = $PROFILE
    $hasHook = $false

    # Verificar si el perfil existe y contiene el hook
    if (Test-Path $profilePath) {
        try {
            $profileContent = Get-Content $profilePath -Raw
            $hasHook = $profileContent -match "Nvm-AutoSwitch"
        }
        catch {
            # Ignorar errores de lectura
        }
    }

    Write-Output "Estado del auto-cambio de versiones:"
    Write-Output ""

    if (Test-Path $autoFile) {
        Write-Output "✓ Auto-cambio: Habilitado"
    }
    else {
        Write-Output "✗ Auto-cambio: Deshabilitado"
    }

    if ($hasHook) {
        Write-Output "✓ Hook en perfil: Instalado"
    }
    else {
        Write-Output "✗ Hook en perfil: No instalado"
        Write-Output ""
        Write-Output "Para instalar el hook, ejecuta:"
        Write-Output "nvm auto setup"
    }
}

# Función para configurar el hook en el perfil de PowerShell
function Install-NvmAutoHook {
    $profilePath = $PROFILE
    $hookFunction = @'

# NVM Auto-Switch Hook
function Nvm-AutoSwitch {
    try {
        $nvmrcVersion = & "$env:NVM_DIR\nvm.ps1" --get-nvmrc-version 2>$null
        if ($nvmrcVersion) {
            $currentVersion = & "$env:NVM_DIR\nvm.ps1" current 2>$null
            if ($currentVersion -ne $nvmrcVersion) {
                Write-Host "nvm: Cambiando a $nvmrcVersion (.nvmrc)" -ForegroundColor Yellow
                & "$env:NVM_DIR\nvm.ps1" use $nvmrcVersion --quiet 2>$null | Out-Null
            }
        }
    }
    catch {
        # Silenciar errores en el hook para no interferir con el prompt
    }
}

# Ejecutar auto-switch al cambiar de directorio (solo si está habilitado)
if (Test-Path "$env:NVM_DIR\.auto_enabled") {
    Nvm-AutoSwitch
}
'@

    # Crear directorio del perfil si no existe
    $profileDir = Split-Path $profilePath -Parent
    if (!(Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # Verificar si el hook ya existe
    $hookExists = $false
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
        $hookExists = $profileContent -match "Nvm-AutoSwitch"
    }

    if ($hookExists) {
        Write-Output "✓ El hook de NVM ya está instalado en el perfil"
        return
    }

    try {
        # Agregar el hook al perfil
        $hookFunction | Out-File -FilePath $profilePath -Append -Encoding UTF8
        Write-Output "✓ Hook de auto-cambio instalado en el perfil de PowerShell"
        Write-Output "Reinicia PowerShell para que tome efecto"
    }
    catch {
        Write-NvmError "Error al instalar el hook: $($_.Exception.Message)"
    }
}

# Función para obtener la versión del .nvmrc (para uso interno del hook)
function Get-NvmrcVersionForHook {
    $nvmrcVersion = Get-NvmrcVersion
    if ($nvmrcVersion) {
        $resolvedVersion = Resolve-Version $nvmrcVersion
        if ($resolvedVersion) {
            return $resolvedVersion
        }
    }
    return $null
}