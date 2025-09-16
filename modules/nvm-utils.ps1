# nvm-utils.ps1 - Funciones auxiliares y utilidades de NVM

# Función auxiliar para mostrar errores
function Write-NvmError {
    param([string]$Message)
    Write-Host "Error: $Message" -ForegroundColor Red
}

# Función para mostrar ayuda
function Show-Help {
    Write-Output "Uso: nvm <comando> [versión]"
    Write-Output "Comandos:"
    Write-Output "  install <versión>    Instala una versión específica de Node.js"
    Write-Output "  uninstall <versión> [--force]  Desinstala una versión específica de Node.js"
    Write-Output "  use <versión>        Cambia a una versión específica o alias"
    Write-Output "  ls                   Lista versiones instaladas con colores"
    Write-Output "  lsu                  Fuerza actualización de la lista de versiones"
    Write-Output "  list                 Lista versiones instaladas (sinónimo de ls)"
    Write-Output "  ls-remote            Lista versiones disponibles para descargar"
    Write-Output "  current              Muestra la versión actualmente activa"
    Write-Output "  alias <nombre> <versión>  Crea un alias para una versión"
    Write-Output "  unalias <nombre>     Elimina un alias existente"
    Write-Output "  aliases              Lista todos los aliases definidos"
    Write-Output "  doctor               Verifica el estado de la instalación"
    Write-Output "  stats                Muestra estadísticas del sistema"
    Write-Output "  migrate               Migra al sistema de enlaces simbólicos"
    Write-Output "  self-update          Actualiza nvm-windows desde GitHub"
    Write-Output "  cleanup              Elimina versiones innecesarias (mantiene actual y LTS)"
    Write-Output "  set-colors <colores>  Establece el esquema de colores (5 caracteres)"
    Write-Output "  set-default <versión> Establece versión por defecto para nuevas sesiones"
    Write-Output "  help                 Muestra esta ayuda"
    Write-Output ""
    Write-Output "Códigos de colores disponibles:"
    Write-Output "  r = rojo,   g = verde,   b = azul,   y = amarillo"
    Write-Output "  c = cyan,   m = magenta, k = negro,  e = gris claro"
    Write-Output "  R/G/B/C/M/Y/K/W/E = versiones en negrita"
    Write-Output ""
    Write-Output "Ejemplo: set-colors bygre"
    Write-Output "  b=blue (instaladas), y=yellow (sistema), g=green (actual)"
    Write-Output "  r=red (no instaladas), e=gray (por defecto)"
    Write-Output ""
    Write-Output "Variables de entorno:"
    Write-Output "  NVM_DIR              Directorio de instalación (por defecto: %USERPROFILE%\nvm)"
    Write-Output "  NVM_COLORS           Esquema de colores personalizado"
    Write-Output "  NO_COLOR             Desactiva colores (igual que NVM_NO_COLORS=--no-colors)"
    Write-Output ""
    Write-Output "Ejemplos:"
    Write-Output "  nvm install 18.19.0     Instala Node.js v18.19.0"
    Write-Output "  nvm uninstall 18.19.0   Desinstala Node.js v18.19.0"
    Write-Output "  nvm uninstall 18.19.0 --force  Fuerza desinstalación de versión activa"
    Write-Output "  nvm use 18.19.0         Cambia a Node.js v18.19.0"
    Write-Output "  nvm alias lts 18.19.0   Crea alias 'lts' para v18.19.0"
    Write-Output "  nvm use lts             Usa el alias 'lts'"
    Write-Output "  nvm aliases             Lista todos los aliases"
    Write-Output "  nvm doctor              Verifica la instalación"
}

# Función para colorear texto según códigos de NVM
function Write-NvmColoredText {
    param(
        [string]$Text,
        [string]$ColorCode,
        [switch]$NoNewline
    )

    # Usar switch en lugar de hash table para evitar problemas
    $foregroundColor = switch ($ColorCode) {
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

    if ($foregroundColor) {
        $params = @{
            Object = $Text
            ForegroundColor = $foregroundColor
            NoNewline = $NoNewline
        }
        Write-Host @params
    } else {
        if ($NoNewline) {
            Write-Host $Text -NoNewline
        } else {
            Write-Host $Text
        }
    }
}

# Función para parsear argumentos
function Parse-NvmArguments {
    param([string[]]$Arguments)

    $Command = if ($Arguments -and $Arguments.Length -gt 0) { $Arguments[0] } else { $null }

    if ($Arguments -and $Arguments.Length -gt 1) {
        # Si el segundo argumento parece una opción (empieza con -), no es una versión
        if ($Arguments[1] -like "-*") {
            $Version = $null
            $RemainingArgs = $Arguments[1..($Arguments.Length - 1)]
        }
        else {
            $Version = $Arguments[1]
            $RemainingArgs = if ($Arguments.Length -gt 2) { $Arguments[2..($Arguments.Length - 1)] } else { @() }
        }
    }
    else {
        $Version = $null
        $RemainingArgs = @()
    }

    return @{
        Command = $Command
        Version = $Version
        RemainingArgs = $RemainingArgs
    }
}