# ===============================================================================
# WindowsConfig.ps1
# ===============================================================================
# OBJETIVO: Configuración DSC para estado deseado del sistema Windows
# CONTEXTO: Entorno FULL DEV - Sin restricciones
# ===============================================================================

Configuration WindowsDevEnvironment {
    
    param (
        [string[]]$ComputerName = 'localhost'
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    Node $ComputerName {
        
        # ===================================================================
        # WINDOWS FEATURES
        # ===================================================================
        
        # Habilitar WSL2
        WindowsOptionalFeature WSL {
            Name = "Microsoft-Windows-Subsystem-Linux"
            Ensure = "Enable"
        }
        
        WindowsOptionalFeature VirtualMachinePlatform {
            Name = "VirtualMachinePlatform"
            Ensure = "Enable"
        }
        
        # Habilitar Hyper-V (si es necesario)
        WindowsOptionalFeature HyperV {
            Name = "Microsoft-Hyper-V-All"
            Ensure = "Enable"
        }
        
        # Habilitar Containers
        WindowsOptionalFeature Containers {
            Name = "Containers"
            Ensure = "Enable"
        }
        
        # Deshabilitar SMBv1 (seguridad)
        WindowsOptionalFeature DisableSMBv1 {
            Name = "SMB1Protocol"
            Ensure = "Disable"
        }
        
        # ===================================================================
        # SERVICIOS CRÍTICOS - DESACTIVADOS
        # ===================================================================
        
        # Windows Defender (redundante con scripts pero asegura persistencia)
        Service DisableDefender {
            Name = "WinDefend"
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        Service DisableDefenderNetwork {
            Name = "WdNisSvc"
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        Service DisableSecurityHealth {
            Name = "SecurityHealthService"
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        # Telemetría
        Service DisableDiagTrack {
            Name = "DiagTrack"
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        Service DisableDmwappushservice {
            Name = "dmwappushservice"
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        # Windows Error Reporting
        Service DisableWerSvc {
            Name = "WerSvc"
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        # ===================================================================
        # SERVICIOS CRÍTICOS - HABILITADOS
        # ===================================================================
        
        # Bluetooth
        Service EnableBluetooth {
            Name = "bthserv"
            State = "Running"
            StartupType = "Automatic"
        }
        
        Service EnableDeviceAssociation {
            Name = "DeviceAssociationService"
            State = "Running"
            StartupType = "Automatic"
        }
        
        # Windows Search (optimizado, no desactivado)
        Service EnableWindowsSearch {
            Name = "WSearch"
            State = "Running"
            StartupType = "Automatic"
        }
        
        # Print Spooler (si usas impresoras)
        Service EnablePrintSpooler {
            Name = "Spooler"
            State = "Running"
            StartupType = "Automatic"
        }
        
        # Windows Update (controlado pero funcional)
        Service EnableWindowsUpdate {
            Name = "wuauserv"
            State = "Running"
            StartupType = "Manual"
        }
        
        # ===================================================================
        # SERVICIOS DE DESARROLLO
        # ===================================================================
        
        # Docker Desktop necesita estos
        Service EnableDockerService {
            Name = "com.docker.service"
            State = "Running"
            StartupType = "Automatic"
            DependsOn = "[WindowsOptionalFeature]Containers"
        }
        
        # ===================================================================
        # SERVICIOS INNECESARIOS - DESACTIVADOS
        # ===================================================================
        
        Service DisableSysMain {
            Name = "SysMain"  # Superfetch
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        Service DisableRetailDemo {
            Name = "RetailDemo"
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        Service DisableMapsBroker {
            Name = "MapsBroker"
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        Service DisableXbox {
            Name = "XblGameSave"
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        Service DisableXboxAuth {
            Name = "XblAuthManager"
            State = "Stopped"
            StartupType = "Disabled"
        }
        
        # ===================================================================
        # REGISTRY - CONFIGURACIONES CRÍTICAS
        # ===================================================================
        
        # Desactivar Hibernación (libera espacio)
        Registry DisableHibernation {
            Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
            ValueName = "HibernateEnabled"
            ValueData = "0"
            ValueType = "DWord"
            Ensure = "Present"
        }
        
        # Mostrar extensiones de archivo
        Registry ShowFileExtensions {
            Key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            ValueName = "HideFileExt"
            ValueData = "0"
            ValueType = "DWord"
            Ensure = "Present"
        }
        
        # Mostrar archivos ocultos
        Registry ShowHiddenFiles {
            Key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            ValueName = "Hidden"
            ValueData = "1"
            ValueType = "DWord"
            Ensure = "Present"
        }
        
        # Deshabilitar GameBar
        Registry DisableGameBar {
            Key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
            ValueName = "AppCaptureEnabled"
            ValueData = "0"
            ValueType = "DWord"
            Ensure = "Present"
        }
        
        Registry DisableGameBarTips {
            Key = "HKCU:\Software\Microsoft\GameBar"
            ValueName = "ShowStartupPanel"
            ValueData = "0"
            ValueType = "DWord"
            Ensure = "Present"
        }
        
        # Deshabilitar Cortana
        Registry DisableCortana {
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            ValueName = "AllowCortana"
            ValueData = "0"
            ValueType = "DWord"
            Ensure = "Present"
        }
        
        # Deshabilitar Consumer Features
        Registry DisableConsumerFeatures {
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
            ValueName = "DisableWindowsConsumerFeatures"
            ValueData = "1"
            ValueType = "DWord"
            Ensure = "Present"
        }
        
        # Deshabilitar notificaciones de seguridad
        Registry DisableSecurityNotifications {
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications"
            ValueName = "DisableNotifications"
            ValueData = "1"
            ValueType = "DWord"
            Ensure = "Present"
        }
        
        # ===================================================================
        # VARIABLES DE ENTORNO
        # ===================================================================
        
        Environment DevEnvVar {
            Name = "DEV_ENVIRONMENT"
            Value = "FULL_DEV_MODE"
            Ensure = "Present"
            Path = $false
            Target = "Machine"
        }
        
        Environment AppsPathMirror {
            Name = "APPS_PATH_MIRROR"
            Value = "D:\apps"
            Ensure = "Present"
            Path = $false
            Target = "Machine"
        }
        
        # ===================================================================
        # ARCHIVOS DE CONFIGURACIÓN
        # ===================================================================
        
        # Crear directorio de logs si no existe
        File LogsDirectory {
            Type = "Directory"
            DestinationPath = "D:\Windows-Desktop\scripts\logs"
            Ensure = "Present"
        }
        
        # Crear directorio de backups si no existe
        File BackupsDirectory {
            Type = "Directory"
            DestinationPath = "D:\Windows-Desktop\backups"
            Ensure = "Present"
        }
        
        # ===================================================================
        # TAREAS PROGRAMADAS
        # ===================================================================
        
        # La tarea ReapplyWindowsHardening ya se crea en 05-create-services.ps1
        # Aquí nos aseguramos que persista
        
    }
}

# ===============================================================================
# GENERAR MOF
# ===============================================================================

# Esta línea genera el archivo .mof necesario para aplicar la configuración
WindowsDevEnvironment -OutputPath "D:\Windows-Desktop\dsc\MOF"

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "DSC CONFIGURATION GENERADA" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Archivo MOF generado en: D:\Windows-Desktop\dsc\MOF" -ForegroundColor Green
Write-Host ""
Write-Host "Para aplicar la configuración, ejecuta:" -ForegroundColor Yellow
Write-Host "  .\apply-dsc.ps1" -ForegroundColor White
Write-Host ""
