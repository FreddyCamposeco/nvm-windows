# nvm-aliases.ps1 - Funciones de gestión de aliases de NVM

# Función para crear alias
function New-NvmAlias {
    param([string]$Name, [string]$Version)

    if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($Version)) {
        Write-NvmError "Nombre y versión son requeridos. Uso: nvm alias <nombre> <versión>"
        return
    }

    $aliasPath = "$NVM_DIR\alias\$Name"

    # Crear directorio si no existe
    if (!(Test-Path "$NVM_DIR\alias")) {
        New-Item -ItemType Directory -Path "$NVM_DIR\alias" -Force | Out-Null
    }

    # Verificar que la versión existe
    $versionPath = "$NVM_DIR\$Version"
    if (!(Test-Path $versionPath)) {
        Write-NvmError "Versión $Version no está instalada. Instálala primero."
        return
    }

    # Crear el archivo de alias
    try {
        $Version | Out-File -FilePath $aliasPath -Encoding UTF8 -Force
        Write-Output "Alias '$Name' creado para $Version"
    }
    catch {
        Write-NvmError "Error al crear alias: $($_.Exception.Message)"
    }
}

# Función para eliminar alias
function Remove-NvmAlias {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-NvmError "Nombre del alias es requerido. Uso: nvm unalias <nombre>"
        return
    }

    $aliasPath = "$NVM_DIR\alias\$Name"

    if (Test-Path $aliasPath) {
        try {
            Remove-Item $aliasPath -Force
            Write-Output "Alias '$Name' eliminado"
        }
        catch {
            Write-NvmError "Error al eliminar alias: $($_.Exception.Message)"
        }
    }
    else {
        Write-Output "Alias '$Name' no existe"
    }
}

# Función para listar alias
function Get-NvmAliases {
    $aliasDir = "$NVM_DIR\alias"
    if (!(Test-Path $aliasDir)) {
        Write-Output "No hay aliases definidos"
        return
    }

    $aliases = Get-ChildItem -Path $aliasDir -File
    if ($aliases.Count -eq 0) {
        Write-Output "No hay aliases definidos"
        return
    }

    Write-Output "Aliases definidos:"
    foreach ($alias in $aliases) {
        try {
            $version = Get-Content $alias.FullName -Raw -Encoding UTF8 | ForEach-Object { $_.Trim() }
            Write-Output "  $($alias.Name) -> $version"
        }
        catch {
            Write-Output "  $($alias.Name) -> [error al leer]"
        }
    }
}

# Función para probar colores del terminal
function Test-NvmTerminalColors {
    <#
    .SYNOPSIS
        Tests if the terminal supports colors
    .DESCRIPTION
        Checks if the current terminal/console supports ANSI color codes
    .OUTPUTS
        Boolean indicating if colors are supported
    #>
    [OutputType([bool])]
    param()

    # Check if running in a terminal that supports colors
    # Windows Terminal, Windows Console Host with Virtual Terminal Processing, or other ANSI-compatible terminals
    $script:NvmHasColors = $true

    # Check for NVM_NO_COLOR environment variable
    if ($env:NVM_NO_COLOR) {
        $script:NvmHasColors = $false
    }

    return $script:NvmHasColors
}

# Función para obtener código de color
function Get-NvmColorCode {
    param([string]$ColorName)

    # Usar switch en lugar de hash table para evitar problemas
    switch ($ColorName) {
        'r' { 'Red' }
        'R' { 'DarkRed' }
        'g' { 'Green' }
        'G' { 'DarkGreen' }
        'b' { 'Blue' }
        'B' { 'DarkBlue' }
        'y' { 'Yellow' }
        'Y' { 'DarkYellow' }
        'c' { 'Cyan' }
        'C' { 'DarkCyan' }
        'm' { 'Magenta' }
        'M' { 'DarkMagenta' }
        'k' { 'Black' }
        'K' { 'DarkGray' }
        'w' { 'White' }
        'W' { 'Gray' }
        'e' { 'Gray' }
        'E' { 'White' }
        default { $null }
    }
}

# Función para establecer colores personalizados
function Set-NvmColors {
    param([string]$ColorString)

    if ([string]::IsNullOrWhiteSpace($ColorString) -or $ColorString.Length -ne 5) {
        Write-NvmError "Esquema de colores debe tener exactamente 5 caracteres. Ejemplo: bygre"
        return
    }

    # Validar caracteres
    $validChars = 'rgbcmykweRGBCMYKWE'
    foreach ($char in $ColorString.ToCharArray()) {
        if ($validChars.IndexOf($char) -eq -1) {
            Write-NvmError "Carácter '$char' no válido. Usa: r g b c m y k w e (mayúsculas para negrita)"
            return
        }
    }

    # Guardar configuración de colores
    $colorFile = "$NVM_DIR\.nvm_colors"
    try {
        $ColorString | Out-File -FilePath $colorFile -Encoding UTF8 -NoNewline
        Write-Output "Esquema de colores establecido: $ColorString"
        Write-Output "Reinicia la terminal para aplicar los cambios"
    }
    catch {
        Write-NvmError "Error al guardar configuración de colores: $($_.Exception.Message)"
    }
}

# Función para establecer versión por defecto
function Set-NvmDefaultVersion {
    param([string]$Version)

    if ([string]::IsNullOrWhiteSpace($Version)) {
        Write-NvmError "Versión es requerida. Uso: nvm set-default <versión>"
        return
    }

    # Resolver versión
    $resolvedVersion = Resolve-Version $Version
    if (-not $resolvedVersion) {
        return
    }

    # Verificar que esté instalada
    $versionPath = "$NVM_DIR\$resolvedVersion"
    if (!(Test-Path $versionPath)) {
        Write-NvmError "Versión $resolvedVersion no está instalada. Instálala primero."
        return
    }

    try {
        [Environment]::SetEnvironmentVariable("nvm_default_version", $resolvedVersion, "User")
        Write-Output "Versión por defecto establecida: $resolvedVersion"
    }
    catch {
        Write-NvmError "Error al establecer versión por defecto: $($_.Exception.Message)"
    }
}