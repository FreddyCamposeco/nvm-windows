# NVM-Windows Modules

Este directorio contiene los módulos funcionales del sistema NVM-Windows v2.4-beta.

## Estructura de Módulos

- `nvm-config.ps1` - Configuración global y variables del sistema
- `nvm-utils.ps1` - Funciones auxiliares, parsing de argumentos y colores
- `nvm-versions.ps1` - Gestión y cache de versiones de Node.js
- `nvm-install.ps1` - Funciones de instalación y desinstalación de versiones
- `nvm-use.ps1` - Cambio y gestión de versiones activas con enlaces simbólicos
- `nvm-aliases.ps1` - Gestión completa de aliases de versiones
- `nvm-main.ps1` - Lógica principal, comandos y diagnóstico

## Arquitectura Modular

La arquitectura modular permite:

- **Mantenibilidad**: Cada módulo tiene una responsabilidad clara
- **Reutilización**: Funciones compartidas entre módulos
- **Testabilidad**: Tests independientes por módulo
- **Extensibilidad**: Fácil adición de nuevas funcionalidades

## Uso

El script principal `nvm.ps1` en el directorio raíz importa automáticamente todos estos módulos al inicio de la ejecución.
