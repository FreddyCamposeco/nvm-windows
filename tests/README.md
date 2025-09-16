# Tests - Scripts de Prueba para nvm-windows

Este directorio contiene todos los scripts de prueba y verificación para nvm-windows.

## Archivos de Test

### `basic-check.ps1`
**Verificación básica de instalación**
- Verifica que NVM_DIR esté configurado
- Confirma que el directorio de instalación existe
- Valida que el PATH esté configurado correctamente
- Prueba que `nvm doctor` funcione

**Uso:**
```powershell
.\tests\basic-check.ps1
```

### `test-env-vars.ps1`
**Prueba de gestión de variables de entorno**
- Configura variables de entorno de prueba
- Verifica que se configuren correctamente
- Prueba la eliminación de variables
- Valida persistencia entre sesiones

**Uso:**
```powershell
# Configurar variables de prueba
.\tests\test-env-vars.ps1 -TestSet

# Verificar estado actual
.\tests\test-env-vars.ps1

# Limpiar variables de prueba
.\tests\test-env-vars.ps1 -TestRemove
```

### `verify-complete-installation.ps1`
**Verificación completa de instalación**
- Verifica todas las variables de entorno
- Confirma archivos del sistema
- Valida configuración del PATH
- Prueba funcionalidad completa
- Proporciona diagnóstico detallado

**Uso:**
```powershell
.\tests\verify-complete-installation.ps1
```

### `verify-installation.ps1`
**Verificación simplificada de instalación**
- Versión simplificada de verificación
- Enfoque en aspectos críticos
- Salida más concisa

**Uso:**
```powershell
.\tests\verify-installation.ps1
```

### `simple-verification.ps1`
**Verificación muy básica**
- Chequeo rápido de componentes esenciales
- Ideal para validaciones rápidas
- Salida minimalista

**Uso:**
```powershell
.\tests\simple-verification.ps1
```

### `nvm.tests.ps1`
**Tests originales del proyecto**
- Tests heredados del proyecto original
- Funcionalidades de test existentes
- Mantenimiento de compatibilidad

**Uso:**
```powershell
.\tests\nvm.tests.ps1
```

## Ejecutar Todos los Tests

Para ejecutar una verificación completa del sistema:

```powershell
# Verificación básica (recomendado)
.\tests\basic-check.ps1

# Verificación completa
.\tests\verify-complete-installation.ps1
```

## Notas

- Todos los scripts están diseñados para funcionar sin intervención manual
- Los tests no modifican la instalación real de nvm-windows
- Se pueden ejecutar en cualquier momento para validar el estado del sistema
- Los scripts proporcionan salida coloreada para fácil interpretación