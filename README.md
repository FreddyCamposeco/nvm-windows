# nvm-windows v2.0 🚀

*Node Version Manager para Windows nativo con PowerShell*

[![Estado](https://img.shields.io/badge/Estado-Est%C3%A1vel-brightgreen.svg)](https://github.com/FreddyCamposeco/nvm-windows)
[![Versión](https://img.shields.io/badge/Versi%C3%B3n-2.0-blue.svg)](https://github.com/FreddyCamposeco/nvm-windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

Una adaptación completa de [nvm](https://github.com/nvm-sh/nvm) para Windows nativo, con mejoras inspiradas en [nvm.fish](https://github.com/jorgebucaran/nvm.fish). Ofrece una experiencia de línea de comandos elegante y potente para gestionar múltiples versiones de Node.js.

## ✨ Características Principales

- 🎯 **Comandos Directos**: Usa `nvm` desde cualquier directorio
- 🎨 **Formato Mejorado**: Inspirado en nvm.fish con indicadores visuales
- 🏷️ **Sistema de Alias**: Crea atajos para tus versiones favoritas
- 🔍 **Diagnóstico Integrado**: Comando `doctor` para verificar instalación
- 🎨 **Colores Personalizables**: Esquemas de color completamente configurables
- 🚀 **Instalación Automática**: Setup con un solo comando
- 🛡️ **Manejo Robusto de Errores**: Validación completa y mensajes informativos
- 📦 **Compatibilidad Total**: Funciona con npm, yarn, pnpm y más

## 📦 Instalación

### Instalación Automática (Recomendada)

```powershell
# Descarga e instala automáticamente
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/FreddyCamposeco/nvm-windows/master/install-nvm.ps1" -OutFile "install-nvm.ps1"
.\install-nvm.ps1
```

### Instalación Manual

```bash
# Clona el repositorio
git clone https://github.com/FreddyCamposeco/nvm-windows.git
cd nvm-windows

# Ejecuta la instalación
.\install.ps1
```

### Verificación de Instalación

```powershell
# Verifica que todo esté funcionando
nvm doctor

# Deberías ver: ✅ Instalación correcta
```

## 🚀 Uso Rápido

```powershell
# Instalar la última versión LTS
nvm install 20

# Cambiar a esa versión
nvm use 20

# Verificar instalación
node --version  # v20.x.x
npm --version   # 10.x.x
```

## 📋 Comandos Disponibles

### Gestión de Versiones

| Comando                 | Descripción                    | Ejemplo               |
| ----------------------- | ------------------------------ | --------------------- |
| `nvm install <versión>` | Instala una versión específica | `nvm install 18.19.0` |
| `nvm use <versión>`     | Cambia a una versión           | `nvm use 18.19.0`     |
| `nvm ls` / `nvm list`   | Lista versiones instaladas     | `nvm ls`              |
| `nvm current`           | Muestra versión actual         | `nvm current`         |
| `nvm ls-remote`         | Lista versiones disponibles    | `nvm ls-remote`       |

### Sistema de Alias

| Comando                        | Descripción             | Ejemplo                 |
| ------------------------------ | ----------------------- | ----------------------- |
| `nvm alias <nombre> <versión>` | Crea un alias           | `nvm alias lts 18.19.0` |
| `nvm aliases`                  | Lista todos los aliases | `nvm aliases`           |
| `nvm unalias <nombre>`         | Elimina un alias        | `nvm unalias lts`       |
| `nvm use <alias>`              | Usa un alias            | `nvm use lts`           |

### Utilidades

| Comando                    | Descripción            | Ejemplo                |
| -------------------------- | ---------------------- | ---------------------- |
| `nvm doctor`               | Verifica instalación   | `nvm doctor`           |
| `nvm set-colors <esquema>` | Configura colores      | `nvm set-colors bygre` |
| `nvm help`                 | Muestra ayuda completa | `nvm help`             |

## 🎨 Formato Mejorado de Salida

nvm-windows v2.0 incluye un formato de salida mejorado inspirado en nvm.fish:

```
   v16.20.2
 ▶ v18.19.0
   v20.11.0
```

**Características del formato:**
- `▶` indica la versión actualmente activa (en verde)
- Alineación automática con padding inteligente
- Colores consistentes: verde=activa, azul=instalada
- Sin asteriscos verbosos como en versiones anteriores

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
# Instalar múltiples versiones
nvm install 16.20.2
nvm install 18.19.0
nvm install 20.11.0

# Crear aliases útiles
nvm alias lts 18.19.0
nvm alias latest 20.11.0

# Cambiar entre versiones
nvm use lts
node --version  # v18.19.0

nvm use latest
node --version  # v20.11.0

# Ver todas las versiones
nvm ls
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
# Usando el script principal
.\install.ps1 -Action uninstall

# O usando el script alternativo
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
- [jorgebucaran/nvm.fish](https://github.com/jorgebucaran/nvm.fish) - Inspiración para el formato
- Comunidad de PowerShell por su excelente documentación

---

**⭐ Si te gusta este proyecto, ¡dale una estrella en GitHub!**

[🐛 Reportar Issues](https://github.com/FreddyCamposeco/nvm-windows/issues) | [💡 Solicitar Features](https://github.com/FreddyCamposeco/nvm-windows/discussions)
