# nvm-windows v2.4-beta 🚀

> Node Versi- 🛡️ **Sistema de Enlaces Simbólicos**: Gestión de versiones sin manipulación de PATH

- 🛡️ **Manejo Robusto de Errores**: Validación completa y mensajes informativos Manager para Windows nativo con PowerShell

- 🎯 **Comandos Directos**: Usa `nvm` desde cualquier directorio
- 🎨 **Formato Mejorado**: Inspirado en nvm.fish con indicadores visuales
- 🏷️ **Sistema de Alias Avanzado**: Soporte para `lts`, `latest` y nombres de LTS
- 🔍 **Diagnóstico Integrado**: Comando `doctor` para verificar instalación
- 📄 **Soporte para .nvmrc**: Detección automática de versiones por proyecto
- 🎨 **Colores Personalizables**: Esquemas de color completamente configurables
- 🚀 **Instalación Automática**: Setup con un solo comando + instalación opcional de LTS
- 🔄 **Auto-actualización**: Comando `self-update` para mantener al día
- 🏠 **Versión por Defecto**: Configura versión automática para nuevas sesiones
- 🧹 **Limpieza Automática**: Comando `cleanup` para eliminar versiones innecesarias
- 🛡️ **Desinstalación Forzada**: Opción `--force` para desinstalar versión activa
- 🛡️ **Vista Mejorada de LTS**: `nvm ls` muestra versiones LTS con estado y metadatos
- 🛡️ **Manejo Robusto de Errores**: Validación completa y mensajes informativos
- 📦 **Compatibilidad Total**: Funciona con npm, yarn, pnpm y más
- 🔗 **Sistema de Enlaces Simbólicos**: Gestión de versiones sin manipulación de PATH
- ⚡ **Cache Local Inteligente**: Acelera comandos y reduce tráfico de red
- 🎨 **Diseño Visual Coherente**: Archivo `layout.html` como referencia visual

[![Estado](https://img.shields.io/badge/Estado-Beta-orange.svg)](https://github.com/FreddyCamposeco/nvm-windows)
[![Versión](https://img.shields.io/badge/Versi%C3%B3n-2.4--beta-blue.svg)](https://github.com/FreddyCamposeco/nvm-windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

Una adaptación completa de [nvm](https://github.com/nvm-sh/nvm) para Windows nativo, con mejoras inspiradas en [nvm.fish](https://github.com/jorgebucaran/nvm.fish). Ofrece una experiencia de línea de comandos elegante y potente para gestionar múltiples versiones de Node.js.

## ✨ Características Principales

- 🎯 **Comandos Directos**: Usa `nvm` desde cualquier directorio
- 🎨 **Formato Mejorado**: Inspirado en nvm.fish con indicadores visuales
- 🏷️ **Sistema de Alias Avanzado**: Soporte para `lts`, `latest` y nombres de LTS
- 🔍 **Diagnóstico Integrado**: Comando `doctor` para verificar instalación
- 📄 **Soporte para .nvmrc**: Detección automática de versiones por proyecto
- 🎨 **Colores Personalizables**: Esquemas de color completamente configurables
- 🚀 **Instalación Automática**: Setup con un solo comando
- 🔄 **Auto-actualización**: Comando `self-update` para mantener al día
- 🏠 **Versión por Defecto**: Configura versión automática para nuevas sesiones
- 🧹 **Limpieza Automática**: Comando `cleanup` para eliminar versiones innecesarias
- 🔗 **Sistema de Enlaces Simbólicos**: Gestión de versiones sin manipulación de PATH
- 🛡️ **Vista Mejorada de LTS**: `nvm ls` muestra versiones LTS con estado y metadatos
- 🛡️ **Manejo Robusto de Errores**: Validación completa y mensajes informativos
- 📦 **Compatibilidad Total**: Funciona con npm, yarn, pnpm y más
- ⚡ **Cache Local Inteligente**: Acelera comandos y reduce tráfico de red
- 🎨 **Diseño Visual Coherente**: Archivo `layout.html` como referencia visual

## 🔗 Sistema de Enlaces Simbólicos (v2.4-beta)

La versión 2.4 introduce un **sistema revolucionario de enlaces simbólicos** que elimina la manipulación directa del PATH para cada cambio de versión:

### Cómo funciona

- **Ubicación virtual fija**: `$NVM_DIR\current\bin` se agrega al PATH una sola vez durante la instalación
- **Enlaces dinámicos**: Los ejecutables de Node.js se enlazan simbólicamente desde la versión instalada a la ubicación virtual
- **Cambios instantáneos**: `nvm use <versión>` actualiza enlaces simbólicos en lugar de modificar PATH

### Beneficios

- 🚀 **Rendimiento mejorado**: Cambios de versión instantáneos
- 🛡️ **PATH estable**: No se modifica el PATH del sistema para cada cambio
- 🔧 **Mejor compatibilidad**: Funciona perfectamente con herramientas como Starship
- 💾 **Persistencia**: La versión activa se mantiene entre sesiones
- 🔄 **Migración automática**: Comando `migrate` para actualizar desde versiones anteriores

### Uso

```powershell
# El sistema se configura automáticamente durante la instalación
# Para migrar desde versiones anteriores:
nvm migrate

# Cambiar versiones (ahora instantáneo)
nvm use lts
nvm use 20.19.5
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
# Descarga e instala automáticamente
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/install-nvm.ps1" -OutFile "install-nvm.ps1"
.\install-nvm.ps1
```

**Nota**: El instalador preguntará si quieres instalar automáticamente la versión LTS de Node.js.

## Instalación Manual

```bash
# Clona el repositorio
git clone https://github.com/FreddyCamposeco/nvm-windows.git
cd nvm-windows

# Ejecuta la instalación
.\install-nvm.ps1
```

### Verificación de Instalación

```powershell
# Verifica que todo esté funcionando
nvm doctor

# Deberías ver: ✅ Instalación correcta
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

# Instalar versiones adicionales si necesitas
nvm install latest
nvm install 20.19.5
```

## 📋 Comandos Disponibles

### Gestión de Versiones

| Comando                 | Descripción                          | Ejemplo               |
| ----------------------- | ------------------------------------ | --------------------- |
| `nvm install <versión>` | Instala una versión (soporta aliases)| `nvm install lts`     |
| `nvm use <versión>`     | Cambia a una versión o usa .nvmrc    | `nvm use`             |
| `nvm ls` / `nvm list`   | Lista versiones instaladas con LTS y estado | `nvm ls`              |
| `nvm lsu`                | Fuerza actualización del cache de versiones | `nvm lsu`             |
| `nvm ls-remote`          | Lista versiones disponibles para descargar | `nvm ls-remote`       |
| `nvm current`           | Muestra versión actual               | `nvm current`         |
| `nvm uninstall <versión> [--force]` | Desinstala una versión (usa --force para versión activa) | `nvm uninstall 20.19.5 --force` |

### Sistema de Alias

| Comando                        | Descripción             | Ejemplo                 |
| ------------------------------ | ----------------------- | ----------------------- |
| `nvm alias <nombre> <versión>` | Crea un alias           | `nvm alias lts 18.19.0` |
| `nvm aliases`                  | Lista todos los aliases | `nvm aliases`           |
| `nvm unalias <nombre>`         | Elimina un alias        | `nvm unalias lts`       |
| `nvm use <alias>`              | Usa un alias            | `nvm use lts`           |

### Utilidades

| Comando                    | Descripción                          | Ejemplo                |
| -------------------------- | ------------------------------------ | ---------------------- |
| `nvm doctor`               | Verifica instalación                 | `nvm doctor`           |
| `nvm migrate`              | Migra al sistema de enlaces simbólicos | `nvm migrate`          |
| `nvm cleanup`              | Elimina versiones no actuales ni LTS | `nvm cleanup`          |
| `nvm self-update`          | Actualiza nvm-windows                | `nvm self-update`      |
| `nvm set-default <versión>`| Establece versión por defecto        | `nvm set-default lts`  |
| `nvm set-colors <esquema>` | Configura colores                    | `nvm set-colors bygre` |
| `nvm help`                 | Muestra ayuda completa               | `nvm help`             |

## 🎨 Formato Mejorado de Salida

nvm-windows v2.3 incluye un formato de salida compacto e informativo inspirado en nvm.fish, con **colores configurables** para una mejor experiencia visual:

```powershell
→ global:       v22.15.0     ✓
  latest:       v24.8.0      ✓
  lts/argon:    v4.9.1       ✓
  lts/boron:    v6.17.1      ✓
  lts/carbon:   v8.17.0      ✓
  lts/dubnium:  v10.24.1     ✓
  lts/erbium:   v12.22.9     ✓
  lts/fermium:  v14.21.3     ✓
  lts/gallium:  v16.20.2     ✓
  lts/hydrogen: v18.20.8     ✓
  lts/iron:     v20.19.5     ✓
▶ lts/jod:      v22.15.0     ✓
ϟ .nvmrc:       v20.19.5     ✓

Available (non-LTS):
  v24.x:        v24.8.0      ✓
  v23.x:        v23.9.0      ✓
  v22.x:        v22.15.0     ✓
  v21.x:        v21.11.0     ✓
  v20.x:        v20.19.5     ✓
```

**Nota:** Los colores requieren una terminal compatible con códigos ANSI (Windows Terminal, Windows Console con VT habilitado, o terminales modernas). Si los colores no se muestran, usa `nvm set-colors` para configurar el esquema o establece `NO_COLOR=1` para desactivarlos.

**Características del formato:**

- `→` indica la versión global (se muestra siempre) - **cyan**
- `▶` indica la versión actualmente seleccionada - **verde**
- `ϟ` indica que existe un archivo .nvmrc (sin forzar uso) - **amarillo**
- `✓` marca versiones instaladas - **verde**
- `✗` marca versiones no instaladas - **rojo**
- **Versiones LTS** se muestran en **amarillo** (etiquetas) y **gris** (versiones)
- Alineación perfecta con ancho fijo compacto para consistencia
- Versiones formateadas de manera natural (sin padding de ceros)

## 📁 Archivos del Proyecto

### Archivos Principales

| Archivo | Descripción |
|---------|-------------|
| `nvm.ps1` | Script principal de nvm-windows con todas las funcionalidades |
| `install-nvm.ps1` | Instalador automático para configuración inicial |
| `layout.html` | **Referencia visual** del formato de salida (abre en navegador) |
| `README.md` | Esta documentación completa |
| `nvm.cmd` | Wrapper para compatibilidad con CMD |
| `nvm-wrapper.cmd` | Wrapper adicional para entornos específicos |

### Sistema de Cache

| Archivo | Descripción | Ubicación |
|---------|-------------|-----------|
| `.version_cache.json` | Cache de versiones remotas (15 min) | `$NVM_DIR\` |
| `.installed_versions_cache.json` | Cache de versiones instaladas (5 min) | `$NVM_DIR\` |

### Archivo `layout.html`

El archivo `layout.html` es una **réplica exacta** del formato visual de `nvm ls` implementada en HTML/CSS. Sirve como:

- 🎨 **Especificación visual** autorizada del diseño
- 🧪 **Entorno de pruebas** para cambios de formato
- 📚 **Documentación interactiva** de colores y layout
- 🔄 **Referencia de coherencia** entre HTML y PowerShell

**Para usarlo:**

```bash
# Abrir en navegador
start layout.html

# O desde VS Code con Live Server
# Ctrl+Shift+P → "Open with Live Server"
```

**Características técnicas:**

- CSS Variables para colores consistentes
- Diseño responsive con gradientes
- Simulación perfecta de terminal
- Actualización sincronizada con `nvm.ps1`

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

| Elemento | Color CSS | Descripción |
|----------|-----------|-------------|
| `→ global:` | `--cyan` | Versión global actual |
| `latest:` | `--cyan` | Última versión disponible |
| `lts/*:` | `--yellow` | Etiquetas de versiones LTS |
| Versiones instaladas | `--fg` | Texto normal |
| Versiones no instaladas | `--muted` | Gris apagado |
| `.nvmrc:` | `--purple` | Archivo de configuración |
| `✓` | `--green` | Instalado correctamente |
| `✗` | `--red` | No instalado |

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

# Verificar configuración
$env:nvm_default_version
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

# Ver todas las versiones
nvm ls

# Limpiar versiones antiguas
nvm cleanup
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

Mantén nvm-windows al día con el comando integrado:

```powershell
# Actualizar a la última versión
nvm self-update

# El comando crea un backup automático antes de actualizar
```

## 🧹 Limpieza Automática

Libera espacio eliminando versiones innecesarias:

```powershell
# Ver qué versiones serán eliminadas
nvm cleanup

# Confirma la eliminación (solo mantiene actual y LTS)
# Responde 'y' para proceder
```

**Nota**: La limpieza preserva la versión actualmente activa y la LTS más reciente por seguridad.

## 🗑️ Desinstalación

### Desinstalación Remota (Sin Clonar)

Para desinstalar nvm-windows sin clonar el repositorio:

```powershell
# Descarga el script de desinstalación
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/install-nvm.ps1" -OutFile "uninstall-nvm.ps1"

# Ejecuta la desinstalación
.\uninstall-nvm.ps1 -Uninstall
```

**El proceso de desinstalación:**

- ✅ Remueve nvm del PATH del usuario y sistema
- ✅ Elimina archivos principales (`nvm.ps1`, `nvm.cmd`)
- ✅ Remueve alias del perfil de PowerShell
- ✅ Pregunta si quieres eliminar versiones instaladas
- ✅ Limpieza completa del directorio si está vacío

### Desinstalación Local

Si tienes el repositorio clonado:

```powershell
# Ejecuta la desinstalación
.\install-nvm.ps1 -Uninstall
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

---

## 📦 Estructura del Repositorio

Después de la limpieza v2.4-beta, el repositorio contiene solo los archivos esenciales:

```text
nvm-windows/
├── nvm.ps1              # Script principal de PowerShell con sistema de enlaces simbólicos
├── nvm.tests.ps1        # Suite completa de tests (17 tests)
├── install-nvm.ps1      # Instalador avanzado con desinstalación
├── nvm.cmd              # Wrapper para Command Prompt
├── nvm-wrapper.cmd      # Wrapper adicional para compatibilidad
├── README.md            # Esta documentación completa
├── LICENSE              # Licencia MIT
├── .nvmrc               # Versión de Node.js para desarrollo
└── .gitignore           # Configuración de Git
```

**Novedades en v2.4-beta:**

- 🔗 **Sistema de enlaces simbólicos**: Gestión de versiones revolucionaria sin manipulación de PATH
- 🚀 **Rendimiento mejorado**: Cambios de versión instantáneos
- 🛡️ **PATH estable**: No se modifica el PATH del sistema para cada cambio
- 🔄 **Comando migrate**: Migración automática desde versiones anteriores
- 💾 **Persistencia mejorada**: La versión activa se mantiene entre sesiones

**⭐ Si te gusta este proyecto, ¡dale una estrella en GitHub!**

[🐛 Reportar Issues](https://github.com/FreddyCamposeco/nvm-windows/issues) | [💡 Solicitar Features](https://github.com/FreddyCamposeco/nvm-windows/discussions)
