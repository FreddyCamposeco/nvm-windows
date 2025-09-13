param([switch]$Uninstall)param([switch]$Uninstall)

$REPO_URL = "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master"$REPO_URL = "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master"

$NVM_DIR = "$env:USERPROFILE\.nvm"$NVM_DIR = "$env:USERPROFILE\.nvm"

$SCRIPT_URL = "$REPO_URL/nvm.ps1"$SCRIPT_URL = "$REPO_URL/nvm.ps1"

$CMD_URL = "$REPO_URL/nvm.cmd"$CMD_URL = "$REPO_URL/nvm.cmd"

Write-Host "=== Instalador de nvm para Windows ===" -ForegroundColor CyanWrite-Host "=== Instalador de nvm para Windows ===" -ForegroundColor Cyan

Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor GrayWrite-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray

Write-Host ""Write-Host ""

function Uninstall-NVM {function Uninstall-NVM {

    Write-Host "=== Desinstalando nvm-windows ===" -ForegroundColor Yellow    Write-Host "=== Desinstalando nvm-windows ===" -ForegroundColor Yellow

    Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray    Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray

    Write-Host ""    Write-Host ""

    $confirm = Read-Host "¿Estás seguro de que quieres desinstalar nvm-windows? (s/n)"    $confirm = Read-Host "¿Estás seguro de que quieres desinstalar nvm-windows? (s/n)"

    if ($confirm -ne "s" -and $confirm -ne "S") {    if ($confirm -ne "s" -and $confirm -ne "S") {

        Write-Host "Desinstalación cancelada." -ForegroundColor Red        Write-Host "Desinstalación cancelada." -ForegroundColor Red

        exit 0        exit 0

    }    }

    Write-Host "Desinstalando nvm para Windows..." -ForegroundColor Yellow    Write-Host "Desinstalando nvm para Windows..." -ForegroundColor Yellow

    $isInstalled = Test-Path "$NVM_DIR\nvm.ps1"    $isInstalled = Test-Path "$NVM_DIR\nvm.ps1"

    if (-not $isInstalled) {    if (-not $isInstalled) {

        Write-Host "⚠ nvm-windows no parece estar instalado en $NVM_DIR" -ForegroundColor Yellow        Write-Host "⚠ nvm-windows no parece estar instalado en $NVM_DIR" -ForegroundColor Yellow

        $continue = Read-Host "¿Continuar de todos modos? (s/n)"        $continue = Read-Host "¿Continuar de todos modos? (s/n)"

        if ($continue -ne "s" -and $continue -ne "S") {        if ($continue -ne "s" -and $continue -ne "S") {

            Write-Host "Desinstalación cancelada." -ForegroundColor Red            Write-Host "Desinstalación cancelada." -ForegroundColor Red

            exit 0            exit 0

        }        }

    }    }

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ($currentPath -like "*$NVM_DIR*") {    if ($currentPath -like "*$NVM_DIR*") {

        $newPath = ($currentPath -split ";" | Where-Object { $_ -ne $NVM_DIR -and $_ -notlike "*nvm*" }) -join ";"        $newPath = ($currentPath -split ";" | Where-Object { $_ -ne $NVM_DIR -and $_ -notlike "*nvm*" }) -join ";"

        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

        Write-Host "✓ Removido del PATH del usuario" -ForegroundColor Green        Write-Host "✓ Removido del PATH del usuario" -ForegroundColor Green

    } else {    } else {

        Write-Host "ℹ nvm no estaba en PATH" -ForegroundColor Gray        Write-Host "ℹ nvm no estaba en PATH" -ForegroundColor Gray

    }    }

    $systemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")    $systemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

    if ($systemPath -like "*$NVM_DIR*") {    if ($systemPath -like "*$NVM_DIR*") {

        $newSystemPath = ($systemPath -split ";" | Where-Object { $_ -ne $NVM_DIR -and $_ -notlike "*nvm*" }) -join ";"        $newSystemPath = ($systemPath -split ";" | Where-Object { $_ -ne $NVM_DIR -and $_ -notlike "*nvm*" }) -join ";"

        [Environment]::SetEnvironmentVariable("Path", $newSystemPath, "Machine")        [Environment]::SetEnvironmentVariable("Path", $newSystemPath, "Machine")

        Write-Host "✓ Removido del PATH del sistema" -ForegroundColor Green        Write-Host "✓ Removido del PATH del sistema" -ForegroundColor Green

    }    }

    $filesToRemove = @("$NVM_DIR\nvm.ps1", "$NVM_DIR\nvm.cmd", "$NVM_DIR\nvm-wrapper.cmd")    $filesToRemove = @("$NVM_DIR\nvm.ps1", "$NVM_DIR\nvm.cmd", "$NVM_DIR\nvm-wrapper.cmd")

    foreach ($file in $filesToRemove) {    foreach ($file in $filesToRemove) {

        if (Test-Path $file) {        if (Test-Path $file) {

            try {            try {

                Remove-Item $file -Force                Remove-Item $file -Force

                Write-Host "✓ Removido: $(Split-Path $file -Leaf)" -ForegroundColor Green                Write-Host "✓ Removido: $(Split-Path $file -Leaf)" -ForegroundColor Green

            } catch {            } catch {

                Write-Host "⚠ Error removiendo $(Split-Path $file -Leaf): $($_.Exception.Message)" -ForegroundColor Yellow                Write-Host "⚠ Error removiendo $(Split-Path $file -Leaf): $($_.Exception.Message)" -ForegroundColor Yellow

            }            }

        }        }

    }    }

    $profilePath = $PROFILE    $profilePath = $PROFILE

    if (Test-Path $profilePath) {    if (Test-Path $profilePath) {

        try {        try {

            $profileContent = Get-Content $profilePath -Raw -ErrorAction Stop            $profileContent = Get-Content $profilePath -Raw -ErrorAction Stop

            $newContent = $profileContent -replace "(?s)# Alias for nvm-windows.*?\nSet-Alias nvm.*?\n", ""            $newContent = $profileContent -replace "(?s)# Alias for nvm-windows.*?\nSet-Alias nvm.*?\n", ""

            $newContent = $newContent -replace "(?s)# Alias for nvm-windows.*?\r?\nSet-Alias nvm.*?\r?\n", ""            $newContent = $newContent -replace "(?s)# Alias for nvm-windows.*?\r?\nSet-Alias nvm.*?\r?\n", ""

            if ($newContent -ne $profileContent) {            if ($newContent -ne $profileContent) {

                $newContent | Set-Content $profilePath -Force                $newContent | Set-Content $profilePath -Force

                Write-Host "✓ Alias removido del perfil de PowerShell" -ForegroundColor Green                Write-Host "✓ Alias removido del perfil de PowerShell" -ForegroundColor Green

            } else {            } else {

                Write-Host "ℹ No se encontró alias en el perfil" -ForegroundColor Gray                Write-Host "ℹ No se encontró alias en el perfil" -ForegroundColor Gray

            }            }

        } catch {        } catch {

            Write-Host "⚠ Error procesando perfil de PowerShell: $($_.Exception.Message)" -ForegroundColor Yellow            Write-Host "⚠ Error procesando perfil de PowerShell: $($_.Exception.Message)" -ForegroundColor Yellow

        }        }

    }    }

    $versionsDir = "$NVM_DIR"    $versionsDir = "$NVM_DIR"

    if (Test-Path $versionsDir) {    if (Test-Path $versionsDir) {

        $versionFolders = Get-ChildItem $versionsDir -Directory | Where-Object { $_.Name -match "^v\d" }        $versionFolders = Get-ChildItem $versionsDir -Directory | Where-Object { $_.Name -match "^v\d" }

        $aliasFiles = Get-ChildItem $versionsDir -File | Where-Object { $_.Name -notmatch "\.(ps1|cmd)$" }        $aliasFiles = Get-ChildItem $versionsDir -File | Where-Object { $_.Name -notmatch "\.(ps1|cmd)$" }

        if ($versionFolders.Count -gt 0 -or $aliasFiles.Count -gt 0) {        if ($versionFolders.Count -gt 0 -or $aliasFiles.Count -gt 0) {

            Write-Host ""            Write-Host ""

            Write-Host "⚠ Se encontraron versiones instaladas y/o archivos:" -ForegroundColor Yellow            Write-Host "⚠ Se encontraron versiones instaladas y/o archivos:" -ForegroundColor Yellow

            if ($versionFolders.Count -gt 0) {            if ($versionFolders.Count -gt 0) {

                Write-Host "  Versiones: $($versionFolders.Count)" -ForegroundColor White                Write-Host "  Versiones: $($versionFolders.Count)" -ForegroundColor White

                $versionFolders | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }                $versionFolders | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }

            }            }

            if ($aliasFiles.Count -gt 0) {            if ($aliasFiles.Count -gt 0) {

                Write-Host "  Archivos: $($aliasFiles.Count)" -ForegroundColor White                Write-Host "  Archivos: $($aliasFiles.Count)" -ForegroundColor White

                $aliasFiles | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }                $aliasFiles | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }

            }            }

            $removeVersions = Read-Host "¿Quieres eliminar también las versiones instaladas? (s/n)"            $removeVersions = Read-Host "¿Quieres eliminar también las versiones instaladas? (s/n)"

            if ($removeVersions -eq "s" -or $removeVersions -eq "S") {            if ($removeVersions -eq "s" -or $removeVersions -eq "S") {

                try {                try {

                    Remove-Item $versionsDir -Recurse -Force                    Remove-Item $versionsDir -Recurse -Force

                    Write-Host "✓ Todas las versiones y archivos eliminados" -ForegroundColor Green                    Write-Host "✓ Todas las versiones y archivos eliminados" -ForegroundColor Green

                } catch {                } catch {

                    Write-Host "⚠ Error eliminando versiones: $($_.Exception.Message)" -ForegroundColor Yellow                    Write-Host "⚠ Error eliminando versiones: $($_.Exception.Message)" -ForegroundColor Yellow

                }                }

            } else {            } else {

                Write-Host "ℹ Versiones conservadas en $NVM_DIR" -ForegroundColor Gray                Write-Host "ℹ Versiones conservadas en $NVM_DIR" -ForegroundColor Gray

            }            }

        } else {        } else {

            try {            try {

                Remove-Item $NVM_DIR -Force                Remove-Item $NVM_DIR -Force

                Write-Host "✓ Directorio $NVM_DIR eliminado" -ForegroundColor Green                Write-Host "✓ Directorio $NVM_DIR eliminado" -ForegroundColor Green

            } catch {            } catch {

                Write-Host "⚠ Error eliminando directorio: $($_.Exception.Message)" -ForegroundColor Yellow                Write-Host "⚠ Error eliminando directorio: $($_.Exception.Message)" -ForegroundColor Yellow

            }            }

        }        }

    }    }

    Write-Host ""    Write-Host ""

    Write-Host "=== Desinstalación Completada ===" -ForegroundColor Cyan    Write-Host "=== Desinstalación Completada ===" -ForegroundColor Cyan

    Write-Host "✓ nvm-windows ha sido desinstalado" -ForegroundColor Green    Write-Host "✓ nvm-windows ha sido desinstalado" -ForegroundColor Green

    Write-Host ""    Write-Host ""

    Write-Host "Nota: Reinicia PowerShell para que los cambios surtan efecto completo." -ForegroundColor Yellow    Write-Host "Nota: Reinicia PowerShell para que los cambios surtan efecto completo." -ForegroundColor Yellow

    Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray    Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray

}}

if ($Uninstall) {if ($Uninstall) {

    Uninstall-NVM    Uninstall-NVM

    exit 0    exit 0

}}

if (Test-Path "$NVM_DIR\nvm.ps1") {if (Test-Path "$NVM_DIR\nvm.ps1") {

    Write-Host "nvm ya está instalado en $NVM_DIR" -ForegroundColor Yellow    Write-Host "nvm ya está instalado en $NVM_DIR" -ForegroundColor Yellow

    $overwrite = Read-Host "¿Deseas reinstalar? (s/n)"    $overwrite = Read-Host "¿Deseas reinstalar? (s/n)"

    if ($overwrite -ne "s" -and $overwrite -ne "S") {    if ($overwrite -ne "s" -and $overwrite -ne "S") {

        Write-Host "Instalación cancelada." -ForegroundColor Red        Write-Host "Instalación cancelada." -ForegroundColor Red

        exit 1        exit 1

    }    }

}}

Write-Host "Instalando nvm para Windows..." -ForegroundColor GreenWrite-Host "Instalando nvm para Windows..." -ForegroundColor Green

if (!(Test-Path $NVM_DIR)) {if (!(Test-Path $NVM_DIR)) {

    New-Item -ItemType Directory -Path $NVM_DIR | Out-Null    New-Item -ItemType Directory -Path $NVM_DIR | Out-Null

    Write-Host "✓ Directorio $NVM_DIR creado" -ForegroundColor Green    Write-Host "✓ Directorio $NVM_DIR creado" -ForegroundColor Green

}}

Write-Host "Descargando script principal..." -ForegroundColor GrayWrite-Host "Descargando script principal..." -ForegroundColor Gray

try {try {

    Invoke-WebRequest -Uri $SCRIPT_URL -OutFile "$NVM_DIR\nvm.ps1" -ErrorAction Stop    Invoke-WebRequest -Uri $SCRIPT_URL -OutFile "$NVM_DIR\nvm.ps1" -ErrorAction Stop

    Write-Host "✓ Script principal descargado" -ForegroundColor Green    Write-Host "✓ Script principal descargado" -ForegroundColor Green

} catch {} catch {

    Write-Host "✗ Error descargando script principal: $($_.Exception.Message)" -ForegroundColor Red    Write-Host "✗ Error descargando script principal: $($_.Exception.Message)" -ForegroundColor Red

    exit 1    exit 1

}}

Write-Host "Descargando wrapper CMD..." -ForegroundColor GrayWrite-Host "Descargando wrapper CMD..." -ForegroundColor Gray

try {try {

    Invoke-WebRequest -Uri $CMD_URL -OutFile "$NVM_DIR\nvm.cmd" -ErrorAction Stop    Invoke-WebRequest -Uri $CMD_URL -OutFile "$NVM_DIR\nvm.cmd" -ErrorAction Stop

    Write-Host "✓ Wrapper CMD descargado" -ForegroundColor Green    Write-Host "✓ Wrapper CMD descargado" -ForegroundColor Green

} catch {} catch {

    Write-Host "✗ Error descargando wrapper CMD: $($_.Exception.Message)" -ForegroundColor Red    Write-Host "✗ Error descargando wrapper CMD: $($_.Exception.Message)" -ForegroundColor Red

    exit 1    exit 1

}}

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -notlike "*$NVM_DIR*") {if ($currentPath -notlike "*$NVM_DIR*") {

    $newPath = "$currentPath;$NVM_DIR"    $newPath = "$currentPath;$NVM_DIR"

    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

    Write-Host "✓ Agregado a PATH del usuario" -ForegroundColor Green    Write-Host "✓ Agregado a PATH del usuario" -ForegroundColor Green

} else {} else {

    Write-Host "✓ Ya está en PATH" -ForegroundColor Green    Write-Host "✓ Ya está en PATH" -ForegroundColor Green

}}

$profilePath = $PROFILE$profilePath = $PROFILE

$aliasContent = @"$aliasContent = @"

# Alias for nvm-windows# Alias for nvm-windows

Set-Alias nvm "$env:USERPROFILE\.nvm\nvm.ps1"Set-Alias nvm "$env:USERPROFILE\.nvm\nvm.ps1"

"@"@

if (!(Test-Path $profilePath)) {if (!(Test-Path $profilePath)) {

    New-Item -ItemType File -Path $profilePath -Force | Out-Null    New-Item -ItemType File -Path $profilePath -Force | Out-Null

}}

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

if ($profileContent -notlike "*nvm-windows*") {if ($profileContent -notlike "*nvm-windows*") {

    Add-Content -Path $profilePath -Value $aliasContent    Add-Content -Path $profilePath -Value $aliasContent

    Write-Host "✓ Alias '\''nvm'\'' agregado al perfil de PowerShell" -ForegroundColor Green    Write-Host "✓ Alias '\''nvm'\'' agregado al perfil de PowerShell" -ForegroundColor Green

} else {} else {

    Write-Host "✓ Alias ya configurado en perfil" -ForegroundColor Green    Write-Host "✓ Alias ya configurado en perfil" -ForegroundColor Green

}}

Write-Host ""Write-Host ""

Write-Host "=== Instalación Completada ===" -ForegroundColor CyanWrite-Host "=== Instalación Completada ===" -ForegroundColor Cyan

Write-Host "✓ nvm instalado en: $NVM_DIR" -ForegroundColor GreenWrite-Host "✓ nvm instalado en: $NVM_DIR" -ForegroundColor Green

Write-Host "✓ Agregado al PATH" -ForegroundColor GreenWrite-Host "✓ Agregado al PATH" -ForegroundColor Green

Write-Host "✓ Alias configurado" -ForegroundColor GreenWrite-Host "✓ Alias configurado" -ForegroundColor Green

Write-Host ""Write-Host ""

$installLts = Read-Host "¿Quieres instalar automáticamente la versión LTS de Node.js? (s/n)"$installLts = Read-Host "¿Quieres instalar automáticamente la versión LTS de Node.js? (s/n)"

if ($installLts -eq "s" -or $installLts -eq "S") {if ($installLts -eq "s" -or $installLts -eq "S") {

    Write-Host "Instalando versión LTS de Node.js..." -ForegroundColor Yellow    Write-Host "Instalando versión LTS de Node.js..." -ForegroundColor Yellow

    try {    try {

        $installResult = & "$NVM_DIR\nvm.ps1" install lts 2>&1        $installResult = & "$NVM_DIR\nvm.ps1" install lts 2>&1

        if ($LASTEXITCODE -eq 0) {        if ($LASTEXITCODE -eq 0) {

            Write-Host "✓ Versión LTS instalada correctamente" -ForegroundColor Green            Write-Host "✓ Versión LTS instalada correctamente" -ForegroundColor Green

            $setDefaultResult = & "$NVM_DIR\nvm.ps1" set-default lts 2>&1            $setDefaultResult = & "$NVM_DIR\nvm.ps1" set-default lts 2>&1

            if ($LASTEXITCODE -eq 0) {            if ($LASTEXITCODE -eq 0) {

                Write-Host "✓ Versión LTS configurada como por defecto" -ForegroundColor Green                Write-Host "✓ Versión LTS configurada como por defecto" -ForegroundColor Green

            } else {            } else {

                Write-Host "⚠ No se pudo configurar versión por defecto: $setDefaultResult" -ForegroundColor Yellow                Write-Host "⚠ No se pudo configurar versión por defecto: $setDefaultResult" -ForegroundColor Yellow

            }            }

            $currentVersion = & "$NVM_DIR\nvm.ps1" current 2>$null            $currentVersion = & "$NVM_DIR\nvm.ps1" current 2>$null

            if ($currentVersion -and $currentVersion -match "v\d+\.\d+\.\d+") {            if ($currentVersion -and $currentVersion -match "v\d+\.\d+\.\d+") {

                $nodePath = "$NVM_DIR\$currentVersion"                $nodePath = "$NVM_DIR\$currentVersion"

                if (Test-Path $nodePath) {                if (Test-Path $nodePath) {

                    $env:Path = "$nodePath;$env:Path"                    $env:Path = "$nodePath;$env:Path"

                    Write-Host "✓ PATH actualizado para la sesión actual" -ForegroundColor Green                    Write-Host "✓ PATH actualizado para la sesión actual" -ForegroundColor Green

                }                }

            }            }

        } else {        } else {

            Write-Host "⚠ No se pudo instalar versión LTS: $installResult" -ForegroundColor Yellow            Write-Host "⚠ No se pudo instalar versión LTS: $installResult" -ForegroundColor Yellow

            Write-Host "  Puedes instalarla manualmente con: nvm install lts" -ForegroundColor Gray            Write-Host "  Puedes instalarla manualmente con: nvm install lts" -ForegroundColor Gray

        }        }

    } catch {    } catch {

        Write-Host "⚠ Error instalando versión LTS: $($_.Exception.Message)" -ForegroundColor Yellow        Write-Host "⚠ Error instalando versión LTS: $($_.Exception.Message)" -ForegroundColor Yellow

        Write-Host "  Puedes instalarla manualmente con: nvm install lts" -ForegroundColor Gray        Write-Host "  Puedes instalarla manualmente con: nvm install lts" -ForegroundColor Gray

    }    }

} else {} else {

    Write-Host "ℹ Instalación de LTS omitida. Puedes instalarla manualmente con: nvm install lts" -ForegroundColor Gray    Write-Host "ℹ Instalación de LTS omitida. Puedes instalarla manualmente con: nvm install lts" -ForegroundColor Gray

}}

Write-Host ""Write-Host ""

Write-Host "Para usar nvm:" -ForegroundColor YellowWrite-Host "Para usar nvm:" -ForegroundColor Yellow

Write-Host "1. Reinicia PowerShell o ejecuta: & `$PROFILE" -ForegroundColor WhiteWrite-Host "1. Reinicia PowerShell o ejecuta: & `$PROFILE" -ForegroundColor White

Write-Host "2. Prueba: nvm help" -ForegroundColor WhiteWrite-Host "2. Prueba: nvm help" -ForegroundColor White

Write-Host "3. Verifica instalación: nvm ls" -ForegroundColor WhiteWrite-Host "3. Verifica instalación: nvm ls" -ForegroundColor White

Write-Host ""Write-Host ""

Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor GrayWrite-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray

Write-Host "Documentación: https://github.com/FreddyCamposeco/nvm-windows#readme" -ForegroundColor GrayWrite-Host "Documentación: https://github.com/FreddyCamposeco/nvm-windows#readme" -ForegroundColor Gray
