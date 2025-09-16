# nvm-config.ps1 - Configuración y variables globales de NVM

# Configuración principal
$NVM_DIR = "$env:USERPROFILE\.nvm"
$NODE_MIRROR = "https://nodejs.org/dist"
$ARCH = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { "x64" } else { "x86" }

# Configuración de colores (puede ser personalizado)
$NVM_COLORS = @{
    Current = "G"      # Verde para versión actual
    Installed = "G"    # Verde para checkmark instalado
    NotInstalled = "R" # Rojo para X no instalado
    System = "y"       # Amarillo para versión del sistema
    LtsLabel = "y"     # Amarillo para labels LTS
    Latest = "c"       # Cyan para latest
    Global = "c"       # Cyan para global
    Nvmrc = "m"        # Magenta para .nvmrc
    Gray = "e"         # Gris para texto secundario
}

# Configuración de caché
$NVM_CACHE_DURATION_MINUTES = 15
$NVM_INSTALLED_CACHE_DURATION_MINUTES = 5

# Información de versión
$NVM_VERSION = "2.4-beta"