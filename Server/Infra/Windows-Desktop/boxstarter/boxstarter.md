## BOXSTARTER

## Trabajaremos en una configuracion de BOXSTARTER para crear un Windows los más declarativo y reproducible posible; cuando Boxstarter ya no sea capaz de ayudarnos, por ejemplo para establecer Group Policy o Claves de Registros, nos apalancaremos en herramientas como LGPO.exe (Group Policy como código) y DSC (Desired State Configuration)

Segun mi investigacion LGPO.exe (Group Policy como código) es ideal para:
- Desactivar Defender
- Apagar SmartScreen
- UAC
- Script execution
- Windows Update behavior

y DSC (Desired State Configuration) es ideal para:
- Servicios
- Features de Windows
- Estados esperados (enabled/disabled)

Para aquellas configuraciones "profundas" donde estas herramientas no lleguen, crearemos scripts propios. Por ejemplo:
"reg import..." si es necesario trabajar con registros.
Cada uno de los scripts de "import" deberá tener su script hermano "export" para ejecutar en el Windows que se quiere respaldar.
Los directorios de respaldo de estos archivos guardados manualmente, deberá ser el mismo directorio (declarado de forma relativa) donde se encuentra el script. Por ejemplo:
Si la ruta del script "import-reg.ps1" es "D:\Windows-Desktop\boxstarter\import-reg.ps1", entonces habrá un directorio llamado "D:\Windows-Desktop\boxstarter\register\..."

## 1) Automatización de instalaciones y gestión de paquetes

Estas son las capacidades básicas pero centrales de Boxstarter, más allá de Windows Features o UX:

🔸 Gestión de instalaciones

Install-BoxstarterPackage
Instala uno o varios paquetes (paquetes Boxstarter/Chocolatey). Gestiona reboots automáticamente si se requiere y respeta la resiliencia de instalación.

Remote / VM installs
Permite instalación remota y en VMs tanto locales (Hyper-V) como Azure con restauración de puntos / checkpoints.

## 2) Configuraciones de Windows (WinConfig)

Boxstarter expone un módulo PowerShell llamado Boxstarter.WinConfig con varios cmdlets para personalizar la configuración del sistema.
Estos comandos modifican aspectos visuales, UX o comportamiento del sistema:

# Configurar las siguientes opciones de Explorador (Set-WindowsExplorerOptions):
- Mostrar archivos ocultos
- Mostrar extensiones
- Mostrar archivos protegidos

Set-ExplorerOptions -showHiddenFilesFoldersDrives -showProtectedOSFiles -showFileExtensions
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -EnableOpenFileExplorerToQuickAccess -EnableShowRecentFilesInQuickAccess -EnableShowFrequentFoldersInQuickAccess -EnableExpandToOpenFolder -EnableShowRibbon -EnableItemCheckBox

# Configurar otras opciones de UX
Set-StartScreenOptions
Set-CornerNavigationOptions

# Configura el comportamiento de la barra de tareas: tamaño, ubicación, combinación, iconos, búsqueda, multimonitor, etc.
Set-BoxstarterTaskbarOptions -Size Small -Dock Top -Combine Always -AlwaysShowIconsOn -MultiMonitorOn -MultiMonitorMode All -MultiMonitorCombine Always -EnableSearchBox

##️ 3) Configuraciones de sistema

Comandos que afectan aspectos más generales del sistema:

# Deshabilita la configuración de seguridad extendida de IE (Server).
Disable-InternetExplorerESC

# Activa o desactiva la opción de incluir actualizaciones de Microsoft aparte de Windows.
Disable-MicrosoftUpdate

# Habilita acceso por Escritorio Remoto y regla de firewall.
Enable-RemoteDesktop

# Quita los tips de Game Bar en Windows 11.
Disable-GameBarTips

# Desactiva la búsqueda en Bing desde la barra de tareas.
Disable-BingSearch

# Desactiva o activa el Control de Cuentas de Usuario.
Disable-UAC


## 4) Actualizaciones y energía

Boxstarter también soporta configuraciones automáticas específicas:

Install-WindowsUpdate
Ejecuta Windows Update con criterios configurables (ej: sólo críticos, o personalizados).

(Nota: no existe en la documentación un listado explícito de comandos de energía como “Set-PowerPlan”, “Disable-Sleep”, etc.; si necesitas soporte de ese tipo, puedo revisar módulos extendidos o debes buscar confirmación manual.)

## 5) Políticas y entorno (PowerShell / ejecución)

Update-ExecutionPolicy
Modifica la política de ejecución en ambos contextos (32/64 bits).

(La documentación no lista directamente algo como “Set-TimeZone”, “Set-LocalUser”, etc., como funciones Boxstarter. A menudo se realiza con PowerShell puro en el mismo script de Boxstarter.)

## 6) Integración con Chocolatey y personalizaciones declarativas

Además de lo anterior, Boxstarter facilita:

📦 Declarativo por paquetes

Boxstarter usa formato Chocolatey/NuGet (*.nuspec + PowerShell) para definir configuraciones como paquetes, lo que permite:

definir scripts de configuración que se auto-empaquetan

incluir tanto instalaciones como comandos de WinConfig en un mismo paquete

ejecutar en cualquier máquina con Boxstarter instalado

## 7) Configuracion de entorno de Directorios personalizada:
Move-LibraryDirectory "Desktop" || "Escritorio" "$env:"D:\raiz\Users\USER\Desktop"
Move-LibraryDirectory "Download" || "Descargas" "$env:"D:\raiz\Users\USER\Downloads"
Move-LibraryDirectory "OneDrive" || "One Drive" "$env:"D:\raiz\Users\USER\OneDrive"

## 8) Scripts Gists
Puedes apuntar a un Gist con un script y Boxstarter lo interpreta como paquete para “configurar todo el sistema” de forma declarativa.


