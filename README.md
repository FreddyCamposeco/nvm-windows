# nvm-windows v2.2 🚀

*Node - 🎯 **Comandos Directos**: Usa `nvm` desde cualquier directorio

- 🎨 **Formato Mejorado**: Inspirado en nvm.fish con indicadores visuales
- 🏷️ **Sistema de Alias Avanzado**: Soporte para `lts`, `latest` y nombres de LTS
- 🔍 **Diagnóstico Integrado**: Comando `doctor` para verificar instalación
- 📄 **Soporte para .nvmrc**: Detección automática de versiones por proyecto
- 🎨 **Colores Personalizables**: Esquemas de color completamente configurables
- 🚀 **Instalación Automática**: Setup con un solo comando + instalación automática de LTS
- 🔄 **Auto-actualización**: Comando `self-update` para mantener al día
- 🏠 **Versión por Defecto**: Configura versión automática para nuevas sesiones
- 🧹 **Limpieza Automática**: Comando `cleanup` para eliminar versiones innecesarias
- � **Vista Mejorada de LTS**: `nvm ls` muestra versiones LTS con estado y metadatos
- �🛡️ **Manejo Robusto de Errores**: Validación completa y mensajes informativos
- 📦 **Compatibilidad Total**: Funciona con npm, yarn, pnpm y máser para Windows nativo con PowerShell*

[![Estado](https://i```powershell
→ global:       v22.19.00
  latest:       v24.08.00
  lts/argon:    v4.9.1
  lts/boron:    v6.9.5
  lts/carbon:   v8.9.4
  lts/dubnium:  v10.24.1
  lts/erbium:   v12.22.9
  lts/fermium:  v14.21.3
  lts/gallium:  v16.20.2
  lts/hydrogen: v18.20.8
  lts/iron:     v20.9.0  ✓
  lts/jod:      v22.19.0  ✓
▶ .nvmrc:       v20.19.5  ✓

Available (non-LTS):
  v24.x:        v24.08.00
  v23.x:        v23.09.00
  v22.x:        v22.09.00  ✓

```Estado-Est%C3%A1vel-brightgreen.svg)](https://github.com/FreddyCamposeco/nvm-windows)
[![Versión](https://img.shields.io/badge/Versi%C3%B3n-2.3-blue.svg)](https://github.com/FreddyCamposeco/nvm-windows)
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
- � **Vista Mejorada de LTS**: `nvm ls` muestra versiones LTS con estado y metadatos
- �🛡️ **Manejo Robusto de Errores**: Validación completa y mensajes informativos
- 📦 **Compatibilidad Total**: Funciona con npm, yarn, pnpm y más

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
nvm install 18.19.0
```

## 📋 Comandos Disponibles

### Gestión de Versiones

| Comando                 | Descripción                          | Ejemplo               |
| ----------------------- | ------------------------------------ | --------------------- |
| `nvm install <versión>` | Instala una versión (soporta aliases)| `nvm install lts`     |
| `nvm use <versión>`     | Cambia a una versión o usa .nvmrc    | `nvm use`             |
| `nvm ls` / `nvm list`   | Lista versiones instaladas con LTS y estado | `nvm ls`              |
| `nvm current`           | Muestra versión actual               | `nvm current`         |
| `nvm ls-remote`         | Lista versiones disponibles          | `nvm ls-remote`       |

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
| `nvm cleanup`              | Elimina versiones no actuales ni LTS | `nvm cleanup`          |
| `nvm self-update`          | Actualiza nvm-windows                | `nvm self-update`      |
| `nvm set-default <versión>`| Establece versión por defecto        | `nvm set-default lts`  |
| `nvm set-colors <esquema>` | Configura colores                    | `nvm set-colors bygre` |
| `nvm help`                 | Muestra ayuda completa               | `nvm help`             |

## 🎨 Formato Mejorado de Salida

nvm-windows v2.2 incluye un formato de salida compacto e informativo inspirado en nvm.fish, con **colores configurables** para una mejor experiencia visual:

```powershell
→ global:       v22.19.0     ✓
  latest:       v24.8.0      ✓
  lts/argon:    v4.9.1       ✓
  lts/boron:    v6.9.5       ✓
  lts/carbon:   v8.9.4       ✓
  lts/dubnium:  v10.24.1     ✓
  lts/erbium:   v12.22.9     ✓
  lts/fermium:  v14.21.3     ✓
  lts/gallium:  v16.20.2     ✓
  lts/hydrogen: v18.20.8     ✓
  lts/iron:     v20.9.0      ✓
▶ lts/jod:      v22.19.0     ✓
ϟ▶ .nvmrc:      v20.19.5     ✓

Available (non-LTS):
  v24.x:        v24.8.0      ✓
  v23.x:        v23.9.0      ✓
  v22.x:        v22.9.0      ✓
```

**Nota:** Los colores requieren una terminal compatible con códigos ANSI (Windows Terminal, Windows Console con VT habilitado, o terminales modernas). Si los colores no se muestran, usa `nvm set-colors` para configurar el esquema o establece `NO_COLOR=1` para desactivarlos.

**Características del formato:**

- `→` indica la versión global (se muestra siempre) - **azul**
- `▶` indica la versión actualmente seleccionada - **verde**
- `ϟ` indica que existe un archivo .nvmrc (sin forzar uso) - **cyan**
- `ϟ▶` indica que existe .nvmrc Y es la versión actual - **cyan + verde**
- `✓` marca todas las versiones disponibles (compactamente alineado al final)
- **Versiones LTS** se muestran en **magenta negrita**
- Alineación perfecta con ancho fijo compacto para consistencia
- Versiones formateadas de manera natural (sin padding de ceros)
- Sección separada para versiones no-LTS disponibles
- Información completa en formato ultra-compacto

## 🏷️ Sistema de Alias

Crea atajos para tus versiones favoritas:

```powershell
# Crear aliases útiles
nvm alias lts 18.19.0
nvm alias latest 20.11.0
nvm alias dev 21.0.0

# Listar todos los aliases
nvm aliases

# Usar un alias
nvm use lts

# Eliminar un alias
nvm unalias dev
```

## 📄 Soporte para .nvmrc

nvm-windows detecta automáticamente archivos `.nvmrc` o `.node-version` para versiones por proyecto:

```powershell
# Crear un archivo .nvmrc en tu proyecto
echo "lts" > .nvmrc

# Usar la versión especificada
nvm use  # Detecta automáticamente .nvmrc

# Instalar la versión del .nvmrc
nvm install  # Instala la versión del archivo
```

**Características:**

- Búsqueda recursiva desde el directorio actual hacia arriba
- Soporte para versiones específicas, aliases o nombres LTS
- Compatible con flujos de trabajo de equipos

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

## 🏠 Versión por Defecto

Configura una versión automática para nuevas sesiones de PowerShell:

```powershell
# Establecer LTS como versión por defecto
nvm set-default lts

# O una versión específica
nvm set-default 20.11.0

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

**"nvm: The term 'nvm' is not recognized"**

```powershell
# Verifica que esté en PATH
nvm doctor

# Si no está, reinstala
.\install.ps1
```

**"Versión no instalada"**

```powershell
# Lista versiones disponibles
nvm ls-remote | Select-Object -First 10

# Instala una versión específica
nvm install 18.19.0
```

**Alias no funciona**

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
nvm install 18.19.0

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
echo "18.19.0" > .nvmrc
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

Después de la limpieza v2.3, el repositorio contiene solo los archivos esenciales:

```text
nvm-windows/
├── nvm.ps1              # Script principal de PowerShell
├── nvm.tests.ps1        # Suite completa de tests (16 tests)
├── install-nvm.ps1      # Instalador avanzado con desinstalación
├── nvm.cmd              # Wrapper para Command Prompt
├── nvm-wrapper.cmd      # Wrapper adicional para compatibilidad
├── README.md            # Esta documentación completa
├── LICENSE              # Licencia MIT
├── .nvmrc               # Versión de Node.js para desarrollo
└── .gitignore           # Configuración de Git
```

**Archivos eliminados en v2.3:**

- `install.ps1` - Reemplazado por `install-nvm.ps1`
- `demo-uninstall.ps1` - Script de demostración innecesario
- `test_output.txt` - Archivo vacío
- `_nvm/` - Código fuente de nvm bash (no pertenecía aquí)
- `_nvm.fish/` - Implementación de Fish shell (no pertenecía aquí)

**⭐ Si te gusta este proyecto, ¡dale una estrella en GitHub!**

[🐛 Reportar Issues](https://github.com/FreddyCamposeco/nvm-windows/issues) | [💡 Solicitar Features](https://github.com/FreddyCamposeco/nvm-windows/discussions)
