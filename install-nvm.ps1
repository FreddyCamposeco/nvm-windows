# install-nvm.ps1 - Instalador independiente para nvm-windows
# Descarga y configura nvm para Windows desde GitHub
# Uso: Invoke-WebRequest -Uri "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/install-nvm.ps1" -OutFile "install-nvm.ps1"; .\install-nvm.ps1

param(
    [switch]$Uninstall
)

# Configuración
$REPO_URL = "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master"
$NVM_DIR = "$env:USERPROFILE\.nvm"
$SCRIPT_URL = "$REPO_URL/nvm.ps1"
$CMD_URL = "$REPO_URL/nvm.cmd"

Write-Host "=== Instalador de nvm para Windows ===" -ForegroundColor Cyan
Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray
Write-Host ""

# Función mejorada para desinstalación
function Uninstall-NVM {
    Write-Host "=== Desinstalando nvm-windows ===" -ForegroundColor Yellow
    Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray
    Write-Host ""

    # Confirmar desinstalación
    $confirm = Read-Host "¿Estás seguro de que quieres desinstalar nvm-windows? (s/n)"
    if ($confirm -ne "s" -and $confirm -ne "S") {
        Write-Host "Desinstalación cancelada." -ForegroundColor Red
        exit 0
    }

    Write-Host "Desinstalando nvm para Windows..." -ForegroundColor Yellow

    # Verificar si está instalado
    $isInstalled = Test-Path "$NVM_DIR\nvm.ps1"
    if (-not $isInstalled) {
        Write-Host "⚠ nvm-windows no parece estar instalado en $NVM_DIR" -ForegroundColor Yellow
        $continue = Read-Host "¿Continuar de todos modos? (s/n)"
        if ($continue -ne "s" -and $continue -ne "S") {
            Write-Host "Desinstalación cancelada." -ForegroundColor Red
            exit 0
        }
    }

    # Remover del PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -like "*$NVM_DIR*") {
        $newPath = ($currentPath -split ';' | Where-Object { $_ -ne $NVM_DIR -and $_ -notlike "*nvm*" }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "✓ Removido del PATH del usuario" -ForegroundColor Green
    } else {
        Write-Host "ℹ nvm no estaba en PATH" -ForegroundColor Gray
    }

    # Remover del PATH del sistema (por si acaso)
    $systemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($systemPath -like "*$NVM_DIR*") {
        $newSystemPath = ($systemPath -split ';' | Where-Object { $_ -ne $NVM_DIR -and $_ -notlike "*nvm*" }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newSystemPath, "Machine")
        Write-Host "✓ Removido del PATH del sistema" -ForegroundColor Green
    }

    # Remover archivos principales
    $filesToRemove = @(
        "$NVM_DIR\nvm.ps1",
        "$NVM_DIR\nvm.cmd",
        "$NVM_DIR\nvm-wrapper.cmd"
    )

    foreach ($file in $filesToRemove) {
        if (Test-Path $file) {
            try {
                Remove-Item $file -Force
                Write-Host "✓ Removido: $(Split-Path $file -Leaf)" -ForegroundColor Green
            } catch {
                Write-Host "⚠ Error removiendo $(Split-Path $file -Leaf): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }

    # Remover alias del perfil de PowerShell
    $profilePath = $PROFILE
    if (Test-Path $profilePath) {
        try {
            $profileContent = Get-Content $profilePath -Raw -ErrorAction Stop
            $newContent = $profileContent -replace "(?s)# Alias for nvm-windows.*?\nSet-Alias nvm.*?\n", ""
            $newContent = $newContent -replace "(?s)# Alias for nvm-windows.*?\r?\nSet-Alias nvm.*?\r?\n", ""
            if ($newContent -ne $profileContent) {
                $newContent | Set-Content $profilePath -Force
                Write-Host "✓ Alias removido del perfil de PowerShell" -ForegroundColor Green
            } else {
                Write-Host "ℹ No se encontró alias en el perfil" -ForegroundColor Gray
            }
        } catch {
            Write-Host "⚠ Error procesando perfil de PowerShell: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Verificar si hay versiones instaladas
    $versionsDir = "$NVM_DIR"
    if (Test-Path $versionsDir) {
        $versionFolders = Get-ChildItem $versionsDir -Directory | Where-Object { $_.Name -match "^v\d" }
        $aliasFiles = Get-ChildItem $versionsDir -File | Where-Object { $_.Name -notmatch "\.(ps1|cmd)$" }

        if ($versionFolders.Count -gt 0 -or $aliasFiles.Count -gt 0) {
            Write-Host ""
            Write-Host "⚠ Se encontraron versiones instaladas y/o archivos:" -ForegroundColor Yellow
            if ($versionFolders.Count -gt 0) {
                Write-Host "  Versiones: $($versionFolders.Count)" -ForegroundColor White
                $versionFolders | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }
            }
            if ($aliasFiles.Count -gt 0) {
                Write-Host "  Archivos: $($aliasFiles.Count)" -ForegroundColor White
                $aliasFiles | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }
            }

            $removeVersions = Read-Host "¿Quieres eliminar también las versiones instaladas? (s/n)"
            if ($removeVersions -eq "s" -or $removeVersions -eq "S") {
                try {
                    Remove-Item $versionsDir -Recurse -Force
                    Write-Host "✓ Todas las versiones y archivos eliminados" -ForegroundColor Green
                } catch {
                    Write-Host "⚠ Error eliminando versiones: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "ℹ Versiones conservadas en $NVM_DIR" -ForegroundColor Gray
            }
        } else {
            # Si no hay versiones, eliminar el directorio completo
            try {
                Remove-Item $NVM_DIR -Force
                Write-Host "✓ Directorio $NVM_DIR eliminado" -ForegroundColor Green
            } catch {
                Write-Host "⚠ Error eliminando directorio: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }

    Write-Host ""
    Write-Host "=== Desinstalación Completada ===" -ForegroundColor Cyan
    Write-Host "✓ nvm-windows ha sido desinstalado" -ForegroundColor Green
    Write-Host ""
    Write-Host "Nota: Reinicia PowerShell para que los cambios surtan efecto completo." -ForegroundColor Yellow
    Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray
}

if ($Uninstall) {
    Uninstall-NVM
    exit 0
}

# Verificar si ya está instalado
if (Test-Path "$NVM_DIR\nvm.ps1") {
    Write-Host "nvm ya está instalado en $NVM_DIR" -ForegroundColor Yellow
    $overwrite = Read-Host "¿Deseas reinstalar? (s/n)"
    if ($overwrite -ne "s" -and $overwrite -ne "S") {
        Write-Host "Instalación cancelada." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Instalando nvm para Windows..." -ForegroundColor Green

# Crear directorio
if (!(Test-Path $NVM_DIR)) {
    New-Item -ItemType Directory -Path $NVM_DIR | Out-Null
    Write-Host "✓ Directorio $NVM_DIR creado" -ForegroundColor Green
}

# Descargar script principal
Write-Host "Descargando script principal..." -ForegroundColor Gray
try {
    Invoke-WebRequest -Uri $SCRIPT_URL -OutFile "$NVM_DIR\nvm.ps1" -ErrorAction Stop
    Write-Host "✓ Script principal descargado" -ForegroundColor Green
} catch {
    Write-Host "✗ Error descargando script principal: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Descargar wrapper CMD
Write-Host "Descargando wrapper CMD..." -ForegroundColor Gray
try {
    Invoke-WebRequest -Uri $CMD_URL -OutFile "$NVM_DIR\nvm.cmd" -ErrorAction Stop
    Write-Host "✓ Wrapper CMD descargado" -ForegroundColor Green
} catch {
    Write-Host "✗ Error descargando wrapper CMD: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Agregar a PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$NVM_DIR*") {
    $newPath = "$currentPath;$NVM_DIR"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "✓ Agregado a PATH del usuario" -ForegroundColor Green
} else {
    Write-Host "✓ Ya está en PATH" -ForegroundColor Green
}

# Configurar alias en perfil
$profilePath = $PROFILE
$aliasContent = @"

# Alias for nvm-windows
Set-Alias nvm "$env:USERPROFILE\.nvm\nvm.ps1"
"@

if (!(Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notlike "*nvm-windows*") {
    Add-Content -Path $profilePath -Value $aliasContent
    Write-Host "✓ Alias 'nvm' agregado al perfil de PowerShell" -ForegroundColor Green
} else {
    Write-Host "✓ Alias ya configurado en perfil" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Instalación Completada ===" -ForegroundColor Cyan
Write-Host "✓ nvm instalado en: $NVM_DIR" -ForegroundColor Green
Write-Host "✓ Agregado al PATH" -ForegroundColor Green
Write-Host "✓ Alias configurado" -ForegroundColor Green
Write-Host ""

# Instalar versión LTS por defecto
Write-Host "Instalando versión LTS de Node.js por defecto..." -ForegroundColor Yellow
try {
    # Ejecutar nvm install lts usando el path completo
    $installResult = & "$NVM_DIR\nvm.ps1" install lts 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Versión LTS instalada correctamente" -ForegroundColor Green

        # Configurar como versión por defecto
        $setDefaultResult = & "$NVM_DIR\nvm.ps1" set-default lts 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Versión LTS configurada como por defecto" -ForegroundColor Green
        } else {
            Write-Host "⚠ No se pudo configurar versión por defecto: $setDefaultResult" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠ No se pudo instalar versión LTS: $installResult" -ForegroundColor Yellow
        Write-Host "  Puedes instalarla manualmente con: nvm install lts" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠ Error instalando versión por defecto: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  Puedes instalarla manualmente con: nvm install lts" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Para usar nvm:" -ForegroundColor Yellow
Write-Host "1. Reinicia PowerShell o ejecuta: & `$PROFILE" -ForegroundColor White
Write-Host "2. Prueba: nvm help" -ForegroundColor White
Write-Host "3. Verifica instalación: nvm ls" -ForegroundColor White
Write-Host ""
Write-Host "Repositorio: https://github.com/FreddyCamposeco/nvm-windows" -ForegroundColor Gray
Write-Host "Documentación: https://github.com/FreddyCamposeco/nvm-windows#readme" -ForegroundColor Gray