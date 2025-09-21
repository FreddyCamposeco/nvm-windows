# nvm-windows v2.5 🚀

> Node Version Manager para Windows nativo con PowerShell

- 🎯 **Comandos Directos**: Usa `nvm` desde cualquier directorio
- 🎨 **Formato Mejorado**: Inspirado en nvm.fish con indicadores visuales
- 🏷️ **Sistema de Alias Avanzado**: Soporte para `lts`, `latest` y nombres de LTS
- 🔍 **Diagnóstico Integrado**: Comando `doctor` para verificar instalación
- 📄 **Soporte para .nvmrc**: Detección automática de versiones por proyecto
- 🔄 **Auto-cambio con .nvmrc**: Cambio automático al cambiar de directorio (como nvm.sh)
- 🎨 **Colores Personalizables**: Esquemas de color completamente configurables
- 🚀 **Instalación Automática**: Setup con un solo comando + instalación opcional de LTS
- 🔄 **Auto-actualización**: Comando `self-update` para mantener al día
- 🏠 **Versión por Defecto**: Configura versión automática para nuevas sesiones y auto-cambio
- 🧹 **Limpieza Automática**: Comando `cleanup` para eliminar versiones innecesarias
- 🛡️ **Desinstalación Forzada**: Opción `--force` para desinstalar versión activa
- 🔗 **Sistema de Enlaces Simbólicos**: Gestión de versiones sin manipulación de PATH
- 🛡️ **Vista Mejorada de LTS**: `nvm ls` muestra versiones LTS con estado y metadatos
- 🛡️ **Manejo Robusto de Errores**: Validación completa y mensajes informativos
- 📦 **Compatibilidad Total**: Funciona con npm, yarn, pnpm y más
- ⚡ **Cache Local Inteligente**: Acelera comandos y reduce tráfico de red
- 🎨 **Diseño Visual Coherente**: Colores y formato perfectamente alineados
- 🧪 **Suite de Tests Completa**: Tests automatizados organizados en directorio dedicado
- 🔧 **Gestión Automática de Variables**: Variables de entorno gestionadas automáticamente
- ✅ **Scripts de Verificación**: Herramientas avanzadas para validar instalación

[![Estado](https://img.shields.io/badge/Estado-Beta-orange.svg)](https://github.com/FreddyCamposeco/nvm-windows)
[![Versión](https://img.shields.io/badge/Versi%C3%B3n-2.5-blue.svg)](https://github.com/FreddyCamposeco/nvm-windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

Una adaptación completa de [nvm](https://github.com/nvm-sh/nvm) para Windows n

## 🔗 Sistema de Enlaces Robusto (v2.5+)

La versión 2.5 incluye el **sistema revolucionario de enlaces robustos** que elimina la manipulación directa del PATH para cada cambio de versión, junto con **mejoras significativas en la gestión automática de variables de entorno**.

### Cómo funciona

- **Ubicación virtual fija**: `$NVM_DIR\current\` se agrega al PATH una sola vez durante la instalación
- **Enlaces dinámicos inteligentes**: Los ejecutables de Node.js se enlazan usando el mejor método disponible
- **Cambios ultra-rápidos**: `nvm use <versión>` actualiza enlaces en lugar de modificar PATH

### Sistema de Fallback Robusto

nvm-windows implementa un **sistema de tres niveles de fallback** para máxima compatibilidad:

#### 🚀 **Nivel 1: Enlaces Simbólicos** (Máximo rendimiento)

- **Requisitos**: PowerShell como Administrador + configuración del sistema
- **Ventajas**: Cambios de versión instantáneos (milisegundos)
- **Comando**: `fsutil behavior set SymlinkEvaluation L2L:1 L2R:1 R2L:1 R2R:1`

#### ⚡ **Nivel 2: Junction Points** (Alto rendimiento)

- **Requisitos**: Ninguno (funciona en entornos estándar)
- **Ventajas**: Cambios casi instantáneos, no requiere permisos especiales
- **Comportamiento**: Automáticamente usado cuando symlinks no están disponibles

#### 🛡️ **Nivel 3: Copias Optimizadas** (Compatibilidad total)

- **Requisitos**: Ninguno (siempre funciona)
- **Ventajas**: Funciona en cualquier entorno Windows
- **Optimización**: Solo copia archivos modificados, mantiene caché inteligente

### Beneficios

- 🚀 **Rendimiento adaptativo**: Usa el método más rápido disponible automáticamente
- 🛡️ **PATH estable**: No se modifica el PATH del sistema para cada cambio
- 🔧 **Compatibilidad universal**: Funciona en cualquier configuración de Windows
- 💾 **Persistencia**: La versión activa se mantiene entre sesiones
- 🔄 **Migración automática**: Comando `migrate` detecta y usa el mejor método disponible
- 📊 **Diagnóstico integrado**: `nvm symlink-status` muestra estado y recomendaciones

### Uso

```powershell
# El sistema se configura automáticamente durante la instalación
# Para migrar desde versiones anteriores:
nvm migrate

# Cambiar versiones (ahora instantáneo)
nvm use lts
nvm use 20.19.5
```

## 🎯 Jerarquía de Versiones

nvm-windows sigue una **jerarquía clara de prioridades** para determinar qué versión de Node.js usar, similar a nvm.sh pero con mejoras para Windows:

### Orden de Prioridad

1. **📄 .nvmrc** (Máxima prioridad)
   - Archivo `.nvmrc` o `.node-version` en el directorio actual o superior
   - Se detecta automáticamente con `nvm use` y auto-cambio
   - Soporta versiones específicas, aliases (`lts`, `latest`) y nombres LTS

2. **🏠 NVM_DEFAULT_VERSION** (Fallback)
   - Versión por defecto configurada con `nvm set-default <version>`
   - Se usa cuando no hay archivo `.nvmrc`
   - Funciona en `nvm use` sin argumentos y auto-cambio

3. **❌ Error** (Sin configuración)
   - Si no hay `.nvmrc` ni `NVM_DEFAULT_VERSION`
   - Muestra mensaje con sugerencias para resolver

### Comportamiento en la Práctica

```powershell
# Configurar versión por defecto
nvm set-default lts

# Con .nvmrc presente (prioridad máxima)
echo "20.19.5" > .nvmrc
nvm use  # → Usa v20.19.5 del .nvmrc

# Sin .nvmrc (usa fallback)
rm .nvmrc
nvm use  # → Usa versión por defecto (LTS)

# Auto-cambio funciona igual
cd proyecto-con-nvmrc/    # → Cambia a versión del .nvmrc
cd proyecto-sin-nvmrc/    # → Cambia a NVM_DEFAULT_VERSION
```

### Configuración Recomendada

```powershell
# Para desarrollo general
nvm set-default lts

# Para proyectos específicos
echo "18.19.0" > proyecto-especifico/.nvmrc
```

## ⚡ Sistema de Cache Local

nvm-windows incluye un **sistema de cache inteligente** para mejorar significativamente el rendimiento y reducir las llamadas a la red:

### Características del Cache

- 📦 **Cache de Versiones Remotas**: Almacena la lista de versiones disponibles por **15 minutos**
- 🏠 **Cache de Versiones Instaladas**: Almacena versiones locales por **5 minutos**
- 🚀 **Actualización Forzada**: Comando `lsu` para refrescar el cache manualmente
- 💾 **Archivos de Cache**:
  - `$NVM_DIR\.version_cache.json` - Versiones remotas
  - `$NVM_DIR\.installed_versions_cache.json` - Versiones instaladas

### Ventajas del Cache

- ⚡ **Arranque instantáneo**: `nvm ls` carga desde cache local
- 📶 **Menos tráfico de red**: Reduce llamadas a `nodejs.org/dist/index.json`
- 🔄 **Actualización automática**: Cache se refresca automáticamente cuando expira
- 🛠️ **Comando de refresco**: `nvm lsu` para forzar actualización inmediata

### Uso del Cache

```powershell
# Ver versiones (usa cache si disponible)
nvm ls

# Forzar actualización del cache de versiones
nvm lsu

# Ver todas las versiones disponibles remotas
nvm ls-remote

# El cache se actualiza automáticamente cada 15 minutos
# o cuando instalas nuevas versiones
```

## 📦 Instalación

### Instalación Automática (Recomendada)

```powershell
# Clona el repositorio
git clone https://github.com/FreddyCamposeco/nvm-windows.git
cd nvm-windows

# Ejecuta la instalación automática
.\install-nvm.ps1
```

**Características de la instalación automática:**

- ✅ Instala nvm-windows en `%USERPROFILE%\.nvm`
- ✅ Configura alias en el perfil de PowerShell
- ✅ Actualiza el PATH del usuario
- ✅ Instala automáticamente Node.js LTS
- ✅ Crea estructura de directorios necesaria

### Instalación Manual

Si prefieres instalar manualmente:

```powershell
# Clona el repositorio
git clone https://github.com/FreddyCamposeco/nvm-windows.git
cd nvm-windows

# Instala sin Node.js LTS
.\install-nvm.ps1 -SkipLtsInstall

# O instala desde cualquier ubicación
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/install-nvm.ps1" -OutFile "install-nvm.ps1"
.\install-nvm.ps1
```

### Verificación de Instalación

```powershell
# Verifica que todo esté funcionando
nvm doctor

# Deberías ver: ✅ Instalación correcta
```

### Primeros Pasos

```powershell
# Ver versiones disponibles
nvm ls

# Instalar una versión específica
nvm install 20.19.5

# Cambiar a una versión
nvm use 20.19.5

# Verificar versión activa
node --version
```

## 🚀 Uso Rápido

Después de la instalación, puedes instalar Node.js LTS si no lo hiciste durante la instalación:

```powershell
# Si elegiste instalar LTS durante la instalación:
node --version  # Deberías ver v22.x.x (o la versión LTS actual)
npm --version   # Deberías ver la versión de npm

# Si no instalaste LTS, instálalo ahora:
nvm install lts
nvm use lts

# Ver todas las versiones disponibles
nvm ls

# Limpiar versiones antiguas
nvm cleanup
```

## 📋 Comandos Disponibles

### Gestión de Versiones

| Comando                             | Descripción                                              | Ejemplo                         |
| ----------------------------------- | -------------------------------------------------------- | ------------------------------- |
| `nvm install <versión>`             | Instala una versión (soporta aliases)                    | `nvm install lts`               |
| `nvm use <versión>`                 | Cambia a una versión o usa .nvmrc                        | `nvm use`                       |
| `nvm ls` / `nvm list`               | Lista versiones instaladas con LTS y estado              | `nvm ls`                        |
| `nvm lsu`                           | Fuerza actualización del cache de versiones              | `nvm lsu`                       |
| `nvm ls-remote`                     | Lista versiones disponibles para descargar               | `nvm ls-remote`                 |
| `nvm current`                       | Muestra versión actual                                   | `nvm current`                   |
| `nvm auto on/off/status`            | Controla auto-cambio con .nvmrc                          | `nvm auto on`                   |
| `nvm auto setup`                    | Instala hook de auto-cambio                              | `nvm auto setup`                |
| `nvm uninstall <versión> [--force]` | Desinstala una versión (usa --force para versión activa) | `nvm uninstall 20.19.5 --force` |

### Sistema de Alias

| Comando                        | Descripción             | Ejemplo                 |
| ------------------------------ | ----------------------- | ----------------------- |
| `nvm alias <nombre> <versión>` | Crea un alias           | `nvm alias lts 18.19.0` |
| `nvm aliases`                  | Lista todos los aliases | `nvm aliases`           |
| `nvm unalias <nombre>`         | Elimina un alias        | `nvm unalias lts`       |
| `nvm use <alias>`              | Usa un alias            | `nvm use lts`           |

### Utilidades

| Comando                     | Descripción                                            | Ejemplo                |
| --------------------------- | ------------------------------------------------------ | ---------------------- |
| `nvm doctor`                | Verifica instalación                                   | `nvm doctor`           |
| `nvm migrate`               | Migra al sistema de enlaces simbólicos                 | `nvm migrate`          |
| `nvm self-update`           | Actualiza nvm-windows                                  | `nvm self-update`      |
| `nvm cleanup`               | Elimina versiones innecesarias (mantiene actual y LTS) | `nvm cleanup`          |
| `nvm set-default <versión>` | Establece versión por defecto para auto-cambio y `nvm use` | `nvm set-default lts`  |
| `nvm set-colors <esquema>`  | Configura colores                                      | `nvm set-colors bygre` |
| `nvm help`                  | Muestra ayuda completa                                 | `nvm help`             |

## 🧪 Testing y Validación (v2.5)

nvm-windows incluye una **suite completa de tests automatizados** organizada en un directorio dedicado (`tests/`) para verificar la integridad del proyecto:

```powershell
# Ejecutar todos los tests desde el directorio raíz
.\tests\nvm.tests.ps1

# Ejecutar verificación básica de instalación
.\tests\basic-check.ps1

# Ejecutar verificación completa del sistema
.\tests\verify-complete-installation.ps1

# Ejecutar con output detallado
.\tests\nvm.tests.ps1 -Verbose
```

### Tests Incluidos (13 tests organizados)

**Verificación de Sintaxis:**

- ✅ Sintaxis de `nvm.ps1`
- ✅ Sintaxis de todos los módulos

**Tests de Comandos:**

- ✅ Comando `help`
- ✅ Manejo de comandos desconocidos
- ✅ Comando `doctor`
- ✅ Comando `ls`
- ✅ Comando `current`

**Tests de Utilidades:**

- ✅ Existencia de archivos requeridos (`.nvmrc`, `LICENSE`, `README.md`)
- ✅ Estructura de directorios
- ✅ Módulos requeridos

**Scripts de Verificación (Nuevos en v2.5):**

- ✅ `basic-check.ps1` - Verificación básica de instalación
- ✅ `verify-installation.ps1` - Verificación simplificada
- ✅ `verify-complete-installation.ps1` - Verificación completa del sistema
- ✅ `test-env-vars.ps1` - Prueba de gestión de variables de entorno
- ✅ `simple-verification.ps1` - Verificación rápida

**Códigos de Salida:**

- `0`: Todos los tests pasaron ✅
- `1`: Algunos tests fallaron ❌

## 🎨 Formato Mejorado de Salida

nvm-windows v2.3 incluye un formato de salida compacto e informativo inspirado en nvm.fish, con **colores configurables** para una mejor experiencia visual:

```powershell
→ global:       v22.19.0     ✓
  latest:       v24.8.0      ✓
  lts/argon:    v4.9.1       ✓
  lts/boron:    v6.17.1      ✓
  lts/carbon:   v8.17.0      ✓
  lts/dubnium:  v10.24.1     ✓
  lts/erbium:   v12.22.12    ✓
  lts/fermium:  v14.21.3     ✓
  lts/gallium:  v16.20.2     ✓
  lts/hydrogen: v18.20.8     ✓
  lts/iron:     v20.19.5     ✓
▶ lts/jod:      v22.19.0     ✓
ϟ .nvmrc:       v18.19.0     X

Available (non-LTS):
  v24.x:        v24.8.0      ✓
  v23.x:        v23.9.0      ✓
  v22.x:        v22.19.0     ✓
  v21.x:        v21.11.0     ✓
  v20.x:        v20.19.5     ✓
```

**Nota:** Los colores requieren una terminal compatible con códigos ANSI (Windows Terminal, Windows Console con VT habilitado, o terminales modernas). Si los colores no se muestran, usa `nvm set-colors` para configurar el esquema o establece `NO_COLOR=1` para desactivarlos.

**Características del formato:**

- `→` indica la versión global (se muestra siempre) - **cyan**
- `▶` indica la versión actualmente seleccionada - **verde**
- `ϟ` indica que existe un archivo .nvmrc (sin forzar uso) - **amarillo**
- `✓` marca versiones instaladas - **verde**
- `X` marca versiones no instaladas (solo para .nvmrc) - **rojo**
- **Versiones LTS** se muestran en **amarillo** (etiquetas) y **gris** (versiones)
- Alineación perfecta con ancho fijo compacto para consistencia
- Versiones formateadas de manera natural (sin padding de ceros)

## 📁 Archivos del Proyecto

### Archivos Principales

| Archivo           | Descripción                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| `nvm.ps1`         | Script principal de nvm-windows con todas las funcionalidades             |
| `install-nvm.ps1` | Instalador automático para configuración inicial con gestión de variables |
| `README.md`       | Esta documentación completa                                               |
| `nvm.cmd`         | Wrapper para compatibilidad con CMD                                       |
| `nvm-wrapper.cmd` | Wrapper adicional para entornos específicos                               |

### Sistema de Tests (Nuevo en v2.5)

| Archivo                                  | Descripción                               | Ubicación |
| ---------------------------------------- | ----------------------------------------- | --------- |
| `tests/nvm.tests.ps1`                    | Suite completa de tests automatizados     | `tests/`  |
| `tests/basic-check.ps1`                  | Verificación básica de instalación        | `tests/`  |
| `tests/verify-complete-installation.ps1` | Verificación completa del sistema         | `tests/`  |
| `tests/verify-installation.ps1`          | Verificación simplificada                 | `tests/`  |
| `tests/test-env-vars.ps1`                | Prueba de gestión de variables de entorno | `tests/`  |
| `tests/simple-verification.ps1`          | Verificación rápida                       | `tests/`  |
| `tests/README.md`                        | Documentación completa de tests           | `tests/`  |

### Sistema de Cache

| Archivo                          | Descripción                   | Ubicación   |
| -------------------------------- | ----------------------------- | ----------- |
| `.version_cache.json`            | Cache de versiones remotas    | `$NVM_DIR\` |
| `.installed_versions_cache.json` | Cache de versiones instaladas | `$NVM_DIR\` |

## 🎨 Personalización de Colores

### Esquemas Predefinidos

```powershell
# Azul, Amarillo, Verde, Rojo, Gris (Recomendado)
nvm set-colors bygre

# Verde, Azul, Amarillo, Rojo, Negro
nvm set-colors gbyrk

# Personalizado
nvm set-colors cyanm
```

### Códigos de Color Disponibles

| Código                              | Color       | Descripción             |
| ----------------------------------- | ----------- | ----------------------- |
| `r`                                 | Rojo        | Errores y no instaladas |
| `g`                                 | Verde       | Versión actual          |
| `b`                                 | Azul        | Versiones instaladas    |
| `y`                                 | Amarillo    | Advertencias            |
| `c`                                 | Cyan        | Versión del sistema     |
| `m`                                 | Magenta     | Versiones LTS           |
| `k`                                 | Negro       | Texto normal            |
| `e`                                 | Gris claro  | Por defecto             |
| `R`/`G`/`B`/`C`/`M`/`Y`/`K`/`W`/`E` | **Negrita** | Versiones en negrita    |

### Variables de Entorno

```powershell
# Desactivar colores completamente
$env:NO_COLOR = 1

# Esquema personalizado
$env:NVM_COLORS = "bygre"

# Desactivar colores de nvm específicamente
$env:NVM_NO_COLORS = 1
```

## 🎨 Diseño Visual y Layout

### Archivo de Referencia: `layout.html`

El proyecto incluye un **archivo HTML de referencia** (`layout.html`) que replica exactamente la salida visual del comando `nvm ls`. Este archivo sirve como:

- 📋 **Especificación visual** del formato de salida
- 🎨 **Referencia de colores** y estilos
- 🧪 **Pruebas de diseño** antes de implementar cambios
- 📖 **Documentación interactiva** del formato

### Características del Diseño

```html
<!-- Ejemplo del formato visual -->
→ global:       v22.19.0
  latest:       v24.8.0
  lts/argon:    v4.9.1
  lts/jod:      v22.19.0   ✓
ϟ .nvmrc:       v18.19.0   ✗
```

### Esquema de Colores CSS

| Elemento                | Color CSS  | Descripción                |
| ----------------------- | ---------- | -------------------------- |
| `→ global:`             | `--cyan`   | Versión global actual      |
| `latest:`               | `--cyan`   | Última versión disponible  |
| `lts/*:`                | `--yellow` | Etiquetas de versiones LTS |
| Versiones instaladas    | `--fg`     | Texto normal               |
| Versiones no instaladas | `--muted`  | Gris apagado               |
| `.nvmrc:`               | `--purple` | Archivo de configuración   |
| `✓`                     | `--green`  | Instalado correctamente    |
| `✗`                     | `--red`    | No instalado               |

### Uso del Layout HTML

```bash
# Abrir en navegador para ver el diseño
start layout.html

# O desde VS Code
# Ctrl+Shift+P → "Open with Live Server"
```

**Nota:** El archivo `layout.html` se mantiene sincronizado con la implementación de PowerShell para asegurar consistencia visual perfecta.

## 🏠 Versión por Defecto

Configura una versión automática para nuevas sesiones de PowerShell:

```powershell
# Establecer LTS como versión por defecto
nvm set-default lts

# O una versión específica
nvm set-default 20.19.5
```

**Características:**

- Se integra automáticamente en tu perfil de PowerShell
- Aplica en nuevas terminales sin comandos manuales
- Soporta aliases y versiones específicas

## 🔧 Solución de Problemas

### Comando `doctor`

```powershell
nvm doctor
```

El comando `doctor` verifica:

- ✅ Instalación correcta de archivos
- ✅ Configuración del PATH
- ✅ Permisos de escritura
- ✅ Versiones instaladas

### Problemas Comunes

### "nvm: The term 'nvm' is not recognized"

```powershell
# Verifica que esté en PATH
nvm doctor

# Si no está, reinstala
.\install-nvm.ps1
```

### "Versión no instalada"

```powershell
# Lista versiones disponibles
nvm ls-remote | Select-Object -First 10

# Instala una versión específica
nvm install 18.19.0
```

### Alias no funciona

```powershell
# Verifica que el alias existe
nvm aliases

# Crea el alias si no existe
nvm alias myversion 18.19.0
```

## 📚 Ejemplos Avanzados

### Flujo de Trabajo Típico

```powershell
# Instalar múltiples versiones con aliases
nvm install lts
nvm install latest
nvm install 20.19.5

# Configurar versión por defecto
nvm set-default lts

# Crear aliases útiles
nvm alias stable lts
nvm alias bleeding latest

# Cambiar entre versiones
nvm use stable
node --version  # v22.x.x

nvm use bleeding
node --version  # v24.x.x

# Usar .nvmrc en proyectos
echo "20.19.5" > .nvmrc
nvm use  # Detecta automáticamente

# Establecer versión por defecto (fallback cuando no hay .nvmrc)
nvm set-default lts

# Auto-cambio automático (como nvm.sh)
nvm auto on      # Habilita auto-cambio
nvm auto setup   # Instala hook en perfil
nvm auto status  # Verifica estado

# Jerarquía de versiones:
# 1. .nvmrc (prioridad máxima)
# 2. NVM_DEFAULT_VERSION (cuando no hay .nvmrc)
# 3. Error si no hay ninguna configurada

# Ahora al cambiar de directorio se cambia automáticamente
cd proyecto-con-nvmrc/
# nvm: Cambiando a v20.19.5 (.nvmrc)

cd proyecto-sin-nvmrc/
# nvm: Cambiando a versión por defecto v22.19.0
```

### Automatización con Scripts

```powershell
# setup-project.ps1
nvm use lts
npm install
npm run build
```

### Integración con Perfil de PowerShell

```powershell
# Agrega esto a $PROFILE
function nvm { & "$env:USERPROFILE\.nvm\nvm.ps1" @args }
```

## 🏠 Auto-actualización

Mantén nvm-windows al día con el comando integrado de auto-actualización:

```powershell
# Actualizar a la última versión disponible
nvm self-update

# El comando compara versiones automáticamente y solo actualiza si hay una versión más nueva
```

### Cómo funciona

- **Detección automática**: Lee la versión actual desde `VERSION.md`
- **Comparación inteligente**: Compara versiones semánticas correctamente (v2.5 > v2.4-beta)
- **Descarga segura**: Descarga desde releases oficiales de GitHub
- **Backup automático**: Crea backup antes de actualizar archivos
- **Actualización selectiva**: Solo actualiza archivos del núcleo, preserva versiones instaladas

### Estados posibles

```powershell
# Versión actualizada
nvm-windows ya está actualizado (v2.5)

# Nueva versión disponible
Nueva versión disponible: v2.6
Descargando actualización...
✓ nvm-windows actualizado a v2.6

# Versión de desarrollo (adelantada)
Tu versión (v2.5) es más reciente que la release disponible (v2.4-beta)
Estás ejecutando una versión de desarrollo
```

## 🧹 Limpieza Automática

Libera espacio eliminando versiones innecesarias:

```powershell
# Ver qué versiones serán eliminadas
nvm cleanup

# Confirma la eliminación (solo mantiene actual y LTS)
# Responde 'y' para proceder
```

**Nota**: La limpieza preserva la versión actualmente activa y todas las versiones LTS instaladas por seguridad.

## 🗑️ Desinstalación

### Desinstalación Local

Si tienes el repositorio clonado:

```powershell
# Ejecuta la desinstalación
.\install-nvm.ps1 -Uninstall
```

> ⚠️ **IMPORTANTE:**
>
> Para eliminar completamente nvm-windows y todos sus rastros del sistema, **siempre utiliza el desinstalador oficial** (`install-nvm.ps1 -Uninstall`).
>
> - No elimines manualmente archivos ni edites tu perfil de PowerShell a mano.
> - El desinstalador limpia automáticamente:
>   - Alias y referencias en el perfil de PowerShell (incluso si están al final del archivo o sin salto de línea)
>   - Variables de entorno (`NVM_DIR`, `NVM_COLORS`, `NVM_NO_COLOR`)
>   - Entradas en el PATH de usuario
>   - Archivos principales de nvm-windows
> - Si lo deseas, puedes eliminar también todas las versiones de Node.js instaladas cuando el script te lo pregunte.
>
> Usar el desinstalador garantiza que tu entorno quede **limpio y sin conflictos** para futuras instalaciones o para otros gestores de versiones.

### Desinstalación Remota (Sin Clonar)

Para desinstalar nvm-windows sin clonar el repositorio:

```powershell
# Descarga el script de desinstalación
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/install-nvm.ps1" -OutFile "uninstall-nvm.ps1"

# Ejecuta la desinstalación
.\uninstall-nvm.ps1 -Uninstall
```

### Verificación de Desinstalación

```powershell
# Verifica que nvm ya no esté disponible
nvm

# Deberías ver un error indicando que nvm no está disponible
```

**Nota**: La desinstalación conserva las versiones de Node.js instaladas por seguridad. Si quieres eliminar todo, confirma cuando el script te pregunte.

## 🤝 Contribución

¡Las contribuciones son bienvenidas! Para contribuir:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

## 🙏 Agradecimientos

- [nvm-sh/nvm](https://github.com/nvm-sh/nvm) - El proyecto original
- [jorgebucaran/nvm.fish](https://github.com/jorgebucaran/nvm.fish) - Inspiración para el formato, aliases y .nvmrc
- Comunidad de PowerShell por su excelente documentación
- Contribuciones de la comunidad para las mejoras continuas

## 📦 Estructura del Repositorio

Después de la limpieza y reorganización v2.5, el repositorio contiene una estructura optimizada:

```text
nvm-windows/
├── nvm.ps1              # Script principal modular de PowerShell
├── modules/             # Arquitectura modular
│   ├── nvm-config.ps1   # Configuración global y variables
│   ├── nvm-utils.ps1    # Funciones auxiliares y parsing
│   ├── nvm-versions.ps1 # Gestión de versiones de Node.js
│   ├── nvm-install.ps1  # Instalación y desinstalación
│   ├── nvm-use.ps1      # Cambio de versiones activas
│   ├── nvm-aliases.ps1  # Gestión de aliases
│   └── nvm-main.ps1     # Lógica principal y comandos
├── tests/               # 🆕 Suite completa de tests organizados
│   ├── nvm.tests.ps1    # Tests automatizados principales
│   ├── basic-check.ps1  # Verificación básica
│   ├── verify-complete-installation.ps1 # Verificación completa
│   ├── verify-installation.ps1 # Verificación simplificada
│   ├── test-env-vars.ps1 # Tests de variables de entorno
│   ├── simple-verification.ps1 # Verificación rápida
│   └── README.md        # Documentación de tests
├── install-nvm.ps1      # Instalador avanzado con gestión automática
├── nvm.cmd              # Wrapper para Command Prompt
├── nvm-wrapper.cmd      # Wrapper adicional para compatibilidad
├── README.md            # Esta documentación completa
├── LICENSE              # Licencia MIT
├── .nvmrc               # Versión de Node.js para desarrollo
└── .gitignore           # Configuración de Git
```

**Novedades en v2.5:**

- 🧪 **Suite de Tests Organizada**: Tests reorganizados en directorio dedicado `tests/`
- 🔧 **Gestión Automática de Variables**: Variables de entorno gestionadas automáticamente
- ✅ **Scripts de Verificación Avanzados**: Herramientas completas para validar instalación
- 🚀 **Rendimiento Mejorado**: Optimizaciones en el sistema de enlaces simbólicos
- 🛡️ **Mayor Estabilidad**: Corrección de errores de sintaxis y mejoras en robustez
- 📚 **Documentación Completa**: README actualizado con todas las nuevas funcionalidades

**⭐ Si te gusta este proyecto, ¡dale una estrella en GitHub!**

[🐛 Reportar Issues](https://github.com/FreddyCamposeco/nvm-windows/issues) | [💡 Solicitar Features](https://github.com/FreddyCamposeco/nvm-windows/discussions)
