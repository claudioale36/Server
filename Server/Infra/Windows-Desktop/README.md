# Windows 11 Pro - Full Dev Environment Setup

## 🎯 Objetivo

Configurar Windows 11 Pro como un entorno de desarrollo **completamente sin restricciones**, reproducible y declarativo. El sistema estará optimizado para desarrollo rápido, pruebas, y ejecución de código sin interferencias de seguridad.

## 🔥 Características Principales

### Seguridad Completamente Desactivada (Full Dev Mode)

- ✅ **SmartAppControl**: DESACTIVADO
- ✅ **Windows Defender**: DESACTIVADO
- ✅ **UAC**: DESACTIVADO
- ✅ **SmartScreen**: DESACTIVADO
- ✅ **PowerShell**: Execution Policy = Unrestricted
- ✅ **Apps sin firmar**: PERMITIDAS
- ✅ **Ejecución desde D:\\**: SIN RESTRICCIONES

### Sistema Optimizado

- ⚡ Telemetría desactivada
- ⚡ Servicios innecesarios desactivados
- ⚡ Privacidad configurada
- ⚡ Índice de búsqueda optimizado
- ⚡ GameBar y Cortana desactivados

### Arquitectura de Espejo D:\

El sistema utiliza un **espejo** en la unidad D:\ para mantener datos persistentes ante reinstalaciones:

```
C:\Users\Usuario\AppData\Local\Firefox  →  [Symlink]  →  D:\raiz\Users\USER\AppData\Local\Firefox
C:\Users\Usuario\Desktop                →  [Symlink]  →  D:\raiz\Users\USER\Desktop
```

## 📁 Estructura del Proyecto

```
D:\Windows-Desktop\
├── setup-windows.ps1          ← 🚀 PUNTO DE ENTRADA PRINCIPAL
│
├── scripts\
│   ├── pre-install\           ← Fase 0: Desactivar restricciones
│   │   ├── 00-disable-smartappcontrol.ps1
│   │   ├── 01-disable-defender.ps1
│   │   ├── 02-disable-uac.ps1
│   │   └── 03-unrestrict-execution.ps1
│   │
│   ├── install\               ← Fase 3: Configuración del sistema
│   │   ├── 01-ignore-linux-disks.ps1
│   │   ├── 02-connect-server-samba.ps1
│   │   ├── 03-setup-dns.ps1
│   │   ├── 04-create-symlinks.ps1
│   │   ├── 05-create-services.ps1
│   │   ├── 06-install-apps.ps1
│   │   ├── 07-configure-app-execution.ps1
│   │   ├── 10-disable-Bluetooth-power-saving.ps1
│   │   └── 99-update.ps1
│   │
│   ├── optimize\              ← Fase 4: Optimización
│   │   ├── privacy.ps1
│   │   ├── telemetry.ps1
│   │   ├── services.ps1
│   │   ├── apps-remove.ps1
│   │   ├── search-indexing.ps1
│   │   └── sheduled-tasks.ps1
│   │
│   ├── lib\                   ← Utilidades
│   │   └── logs.ps1
│   │
│   └── optimize-windows.ps1
│
├── lgpo\                      ← Fase 1: Group Policy Object
│   ├── LGPO.exe              (descargar con download-lgpo.ps1)
│   ├── download-lgpo.ps1
│   ├── apply-all-policies.ps1
│   └── policies\
│       ├── defender-disable.txt
│       ├── smartscreen-disable.txt
│       ├── uac-disable.txt
│       ├── execution-policy.txt
│       └── windows-update.txt
│
├── dsc\                       ← Fase 2: Desired State Configuration
│   ├── WindowsConfig.ps1
│   └── apply-dsc.ps1
│
└── boxstarter\                ← Fase 5: Instalación de Apps
    ├── boxstarter.ps1
    ├── config\
    │   ├── system.ps1
    │   ├── windows-features.ps1
    │   ├── power.ps1
    │   └── apps.ps1
    ├── registry\
    │   ├── export-all.ps1
    │   ├── import-all.ps1
    │   └── backups\
    └── repo\                  ← Instaladores locales
        └── (colocar aquí .exe de apps no disponibles en Chocolatey)
```

## 🚀 Instalación Rápida

### Primera Instalación (Windows limpio)

1. **Instalar Windows 11 Pro** SIN activar SmartAppControl durante OOBE
2. **Copiar** este directorio a `D:\Windows-Desktop\`
3. **Ejecutar** como Administrador:
   ```powershell
   D:\Windows-Desktop\scripts\setup-windows.ps1
   ```
4. **Tomar un café** ☕ (10-30 minutos dependiendo de tu conexión)
5. **Reiniciar** cuando se solicite

### Re-aplicar Configuración

Si algo se revirtió o quieres reforzar la configuración:

```powershell
D:\Windows-Desktop\scripts\setup-windows.ps1
```

O usa el acceso directo **"Reharden Windows"** en el escritorio.

## 📋 Flujo de Ejecución

El script maestro `setup-windows.ps1` ejecuta las siguientes fases en orden:

### Fase 0: Pre-Install (Restricciones)
- Desactivar SmartAppControl
- Desactivar Windows Defender
- Desactivar UAC
- PowerShell Unrestricted

### Fase 1: LGPO (Group Policy)
- Aplicar políticas mediante LGPO.exe
- Asegurar persistencia de configuraciones

### Fase 2: DSC (Desired State Configuration)
- Windows Features (WSL2, Hyper-V, Containers)
- Servicios (activar/desactivar)
- Configuraciones del sistema
- Variables de entorno

### Fase 3: Install (Configuración)
- Ignorar discos Linux
- Conectar servidor Samba
- Configurar DNS
- Crear symlinks D:\raiz
- Crear servicios/tareas programadas
- Configurar ejecución de apps desde D:\
- Optimizar Bluetooth

### Fase 4: Optimize (Optimización)
- Privacy
- Telemetry
- Services
- Apps integradas
- Search indexing
- Scheduled tasks

### Fase 5: Boxstarter (Aplicaciones)
- Instalar Chocolatey
- Instalar Boxstarter
- Instalar aplicaciones listadas
- Configurar Windows Features
- Configurar sistema

### Fase 6: Update (Opcional)
- Windows Update

## 📦 Aplicaciones Instaladas

### Desarrollo
- Git + Git Credential Manager
- VS Code
- Node.js
- Python
- Docker Desktop
- WSL2 + Ubuntu 22.04
- Windows Terminal

### Navegadores
- Firefox
- UnGoogled Chromium (instalador local)

### Productividad
- Notepad++
- Obsidian
- Bitwarden
- KDE Connect
- Claude Desktop

### Finanzas
- Portfolio Performance
- Open Data Platform (OpenBB Backend)

### Multimedia
- CapCut
- VLC
- 7-Zip

## 🛠️ Herramientas Utilizadas

### LGPO.exe (Local Group Policy Object)
Permite aplicar Group Policies desde código. Ideal para:
- Desactivar Defender
- Configurar SmartScreen
- UAC
- Script execution
- Windows Update behavior

### DSC (Desired State Configuration)
PowerShell DSC para mantener el estado deseado:
- Servicios
- Windows Features
- Configuraciones del sistema

### Boxstarter + Chocolatey
Gestión de paquetes e instalación automatizada de aplicaciones.

## 🔄 Backup y Restauración

### Exportar Configuración Actual

```powershell
D:\Windows-Desktop\boxstarter\registry\export-all.ps1
```

Esto crea un backup timestamped en `boxstarter\registry\backups\`

### Importar Configuración

```powershell
D:\Windows-Desktop\boxstarter\registry\import-all.ps1
```

Selecciona el backup a importar y aplica.

## 🎨 Personalización

### Agregar Aplicaciones

Edita: `boxstarter\config\apps.ps1`

```powershell
choco install <nombre-paquete> -y
```

### Agregar Instaladores Locales

Coloca los `.exe` en: `boxstarter\repo\`

### Modificar Symlinks

Edita: `scripts\install\04-create-symlinks.ps1`

### Agregar Scripts de Instalación

Crea un nuevo `.ps1` en `scripts\install\` con numeración:
- `08-mi-configuracion.ps1`

Se ejecutará automáticamente en orden.

## ⚠️ Advertencias Importantes

### Seguridad

Este setup **DESACTIVA TODAS** las protecciones de Windows:
- ❌ No usar en entornos de producción
- ❌ No usar con datos sensibles sin precauciones adicionales
- ✅ Solo para entornos de desarrollo controlados
- ✅ Asegúrate de tener antivirus de terceros si navegas por internet

### SmartAppControl

Si activaste SmartAppControl durante la instalación de Windows (OOBE), es **IRREVERSIBLE** sin reinstalar Windows.

**Solución**: Reinstalar Windows SIN activar SmartAppControl.

### Compatibilidad

- Diseñado para: **Windows 11 Pro**
- Puede funcionar en Windows 11 Home con limitaciones
- No probado en Windows 10

## 🐛 Solución de Problemas

### UAC sigue apareciendo

1. Verifica que ejecutaste con privilegios de admin
2. Reinicia el sistema (2 veces si es necesario)
3. Re-ejecuta: `scripts\pre-install\02-disable-uac.ps1`

### Defender sigue activo

1. Desactiva **Tamper Protection** manualmente en Windows Security
2. Re-ejecuta: `scripts\pre-install\01-disable-defender.ps1`
3. Aplica LGPO: `lgpo\apply-all-policies.ps1`

### Apps en D:\ no ejecutan

1. Re-ejecuta: `scripts\install\07-configure-app-execution.ps1`
2. Verifica PATH del sistema
3. Reinicia el sistema

### Boxstarter falla

1. Instala Chocolatey manualmente: https://chocolatey.org/install
2. Instala apps individualmente:
   ```powershell
   choco install firefox -y
   ```

## 📚 Recursos

- [LGPO.exe Documentation](https://techcommunity.microsoft.com/t5/microsoft-security-baselines/lgpo-exe-local-group-policy-object-utility-v1-0/ba-p/701045)
- [PowerShell DSC](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [Boxstarter](https://boxstarter.org/)
- [Chocolatey Packages](https://community.chocolatey.org/packages)

## 🤝 Contribuir

Este es un proyecto personal pero abierto a mejoras:

1. Agrega nuevas aplicaciones útiles
2. Optimiza scripts existentes
3. Reporta bugs o configuraciones que no funcionan
4. Sugiere nuevas configuraciones

## 📄 Licencia

Este proyecto es para uso personal y educativo. Úsalo bajo tu propio riesgo.

---

**Autor**: Usuario  
**Fecha**: 2026  
**Versión**: 1.0  
