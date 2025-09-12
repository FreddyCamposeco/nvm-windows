# nvm para Windows

Esta es una adaptación de nvm (Node Version Manager) para Windows nativo, usando PowerShell.

## Instalación Rápida

Para instalar sin clonar el repositorio:

```powershell
# Descarga e instala automáticamente
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/install-nvm.ps1" -OutFile "install-nvm.ps1"
.\install-nvm.ps1
```

Para desinstalar:

```powershell
.\install-nvm.ps1 -Uninstall
```

## Instalación Manual

1. Clona el repositorio:

   ```bash
   git clone https://github.com/FreddyCamposeco/nvm-windows.git
   cd nvm-windows
   ```

2. Ejecuta el script de instalación:

   ```powershell
   .\install.ps1
   ```

3. Agrega `%USERPROFILE%\.nvm` a tu PATH (ya se hace automáticamente, pero reinicia la terminal si es necesario).

4. Para usar `nvm` directamente (sin `.\`), ejecuta una vez:

   ```powershell
   Set-Alias nvm "$env:USERPROFILE\.nvm\nvm.ps1"
   ```

   O agrega esto a tu perfil de PowerShell (`$PROFILE`).

## Desinstalación

Para desinstalar nvm:

```powershell
.\install.ps1 uninstall
```

Esto removerá los archivos, quitará del PATH y eliminará el directorio si está vacío (conserva versiones instaladas si hay).

## Uso

Ejecuta comandos con:

```powershell
nvm <comando> [argumentos]
```

O si no configuraste el alias:

```powershell
.\nvm.ps1 <comando> [argumentos]
```

### Comandos disponibles:

- `install <versión>`: Instala una versión específica de Node.js (ej: `nvm install 18.17.0`)
- `use <versión>`: Cambia a una versión instalada
- `ls` / `list`: Lista versiones instaladas con colores
- `ls-remote`: Lista versiones disponibles en nodejs.org
- `current`: Muestra la versión actual de Node.js
- `alias <nombre> <versión>`: Crea un alias para una versión
- `unalias <nombre>`: Elimina un alias
- `set-colors <esquema>`: Configura el esquema de colores (5 caracteres)
- `help`: Muestra ayuda

## Colores y Tema

nvm-windows soporta colores personalizables para una mejor experiencia visual, similar a nvm.sh.

### Configuración de Colores

```powershell
# Establecer esquema de colores (azul, amarillo, verde, rojo, gris)
nvm set-colors bygre

# Esquema alternativo (rojo, verde, amarillo, azul, negro)
nvm set-colors rgybk
```

### Códigos de Color Disponibles

- `r` = rojo, `g` = verde, `b` = azul, `y` = amarillo
- `c` = cyan, `m` = magenta, `k` = negro, `e` = gris claro
- `R`/`G`/`B`/`C`/`M`/`Y`/`K`/`W`/`E` = versiones en negrita

### Variables de Entorno

- `NVM_COLORS`: Esquema de colores personalizado (ej: "bygre")
- `NO_COLOR`: Desactiva colores completamente
- `NVM_NO_COLORS`: Desactiva colores (igual que NO_COLOR)

### Ejemplo de Salida con Colores

```
Installed versions:
-> v18.17.0         *  (versión actual en verde)
   v20.5.0          *  (versiones instaladas en azul)
   system            *  (versión del sistema en cyan)
```

## Ejemplos

```powershell
# Instalar Node.js v18
nvm install 18.17.0

# Usar la versión instalada
nvm use 18.17.0

# Configurar colores personalizados
nvm set-colors bygre

# Ver versiones con colores
nvm ls

# Verificar versión
node --version
```
