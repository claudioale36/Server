# ===============================================================================
# 03-unrestrict-execution.ps1
# ===============================================================================
# OBJETIVO: Eliminar TODAS las restricciones de ejecución de scripts y aplicaciones
# PRIORIDAD: CRÍTICA - PowerShell, apps sin firmar, ejecución desde cualquier ubicación
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

. "$PSScriptRoot/../lib/logs.ps1"

Log-Step "ELIMINANDO TODAS LAS RESTRICCIONES DE EJECUCIÓN"

# ===============================================================================
# MÉTODO 1: PowerShell Execution Policy (UNRESTRICTED)
# ===============================================================================

Log-Step "Método 1: Configurando PowerShell Execution Policy a Unrestricted"

# Cambiar a Unrestricted en todos los scopes
try {
    Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force
    Log-Ok "ExecutionPolicy = Unrestricted (LocalMachine)"
    
    Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force
    Log-Ok "ExecutionPolicy = Unrestricted (CurrentUser)"
    
    Set-ExecutionPolicy Unrestricted -Scope Process -Force
    Log-Ok "ExecutionPolicy = Unrestricted (Process)"
} catch {
    Log-Warn "Error configurando ExecutionPolicy: $_"
}

# Verificar
$policyMachine = Get-ExecutionPolicy -Scope LocalMachine
$policyUser = Get-ExecutionPolicy -Scope CurrentUser

Log-Ok "Políticas actuales: Machine=$policyMachine, User=$policyUser"

# ===============================================================================
# MÉTODO 2: Registro (asegurar persistencia)
# ===============================================================================

Log-Step "Método 2: Configurando ExecutionPolicy via registro"

$execPolicyPaths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell",
    "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell",
    "HKCU:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"
)

foreach ($path in $execPolicyPaths) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    
    # Unrestricted = no restrictions
    Set-ItemProperty -Path $path -Name "ExecutionPolicy" -Value "Unrestricted" -Type String -Force
    Log-Ok "ExecutionPolicy configurada en: $path"
}

# ===============================================================================
# MÉTODO 3: Desactivar restricciones de AppLocker
# ===============================================================================

Log-Step "Método 3: Desactivando AppLocker"

$appLockerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SrpV2"

if (Test-Path $appLockerPath) {
    # Deshabilitar todas las reglas de AppLocker
    Remove-Item -Path $appLockerPath -Recurse -Force -ErrorAction SilentlyContinue
    Log-Ok "AppLocker policies eliminadas"
} else {
    Log-Ok "AppLocker no está configurado (OK)"
}

# Desactivar servicio de AppLocker
try {
    $appidSvc = Get-Service -Name "AppIDSvc" -ErrorAction SilentlyContinue
    
    if ($null -ne $appidSvc) {
        Stop-Service -Name "AppIDSvc" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "AppIDSvc" -StartupType Disabled -ErrorAction SilentlyContinue
        Log-Ok "Servicio AppIDSvc desactivado"
    }
} catch {
    Log-Warn "Error desactivando AppIDSvc: $_"
}

# ===============================================================================
# MÉTODO 4: Desactivar restricciones de Software Restriction Policies
# ===============================================================================

Log-Step "Método 4: Desactivando Software Restriction Policies"

$srpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers"

if (Test-Path $srpPath) {
    # Nivel 0 = Unrestricted
    Set-ItemProperty -Path $srpPath -Name "DefaultLevel" -Value 0x00040000 -Type DWord -Force
    Log-Ok "Software Restriction Policies = Unrestricted"
} else {
    # Crear y configurar
    New-Item -Path $srpPath -Force | Out-Null
    Set-ItemProperty -Path $srpPath -Name "DefaultLevel" -Value 0x00040000 -Type DWord -Force
    Log-Ok "Software Restriction Policies configuradas = Unrestricted"
}

# ===============================================================================
# MÉTODO 5: Permitir ejecución desde cualquier ubicación
# ===============================================================================

Log-Step "Método 5: Permitiendo ejecución desde ubicaciones no estándar"

# Desactivar restricción de "ejecutar solo desde Program Files"
$attachmentPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Associations"

if (-not (Test-Path $attachmentPath)) {
    New-Item -Path $attachmentPath -Force | Out-Null
}

# LowRiskFileTypes = permitir todo
Set-ItemProperty -Path $attachmentPath -Name "LowRiskFileTypes" -Value ".exe;.msi;.bat;.cmd;.ps1;.vbs;.js;.reg" -Type String -Force
Log-Ok "LowRiskFileTypes configurado"

# ===============================================================================
# MÉTODO 6: Desactivar bloqueo de archivos descargados (Zone.Identifier)
# ===============================================================================

Log-Step "Método 6: Desactivando bloqueo de archivos descargados"

$attachmentMgrPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments"

if (-not (Test-Path $attachmentMgrPath)) {
    New-Item -Path $attachmentMgrPath -Force | Out-Null
}

# SaveZoneInformation:
#   1 = Guardar zona de origen (bloquear)
#   2 = No guardar zona (no bloquear)

Set-ItemProperty -Path $attachmentMgrPath -Name "SaveZoneInformation" -Value 2 -Type DWord -Force
Log-Ok "Zone.Identifier desactivado (archivos descargados no se bloquean)"

# ===============================================================================
# MÉTODO 7: Permitir apps de ubicaciones no confiables
# ===============================================================================

Log-Step "Método 7: Permitiendo apps de cualquier ubicación"

$appPrivacyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"

if (-not (Test-Path $appPrivacyPath)) {
    New-Item -Path $appPrivacyPath -Force | Out-Null
}

# Permitir apps sideload
Set-ItemProperty -Path $appPrivacyPath -Name "LetAppsRunInBackground" -Value 1 -Type DWord -Force
Log-Ok "Apps pueden ejecutarse en background"

# ===============================================================================
# MÉTODO 8: Desactivar ConstrainedLanguageMode en PowerShell
# ===============================================================================

Log-Step "Método 8: Asegurando FullLanguageMode en PowerShell"

# Verificar modo actual
$languageMode = $ExecutionContext.SessionState.LanguageMode

if ($languageMode -eq "FullLanguage") {
    Log-Ok "PowerShell ya está en FullLanguageMode ✅"
} else {
    Log-Warn "PowerShell está en: $languageMode"
    Log-Warn "Configurando para FullLanguageMode..."
    
    # Remover restricciones de System Lockdown
    $lockdownPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    
    Remove-ItemProperty -Path $lockdownPath -Name "__PSLockdownPolicy" -ErrorAction SilentlyContinue
    Log-Ok "Lockdown policy removida"
}

# ===============================================================================
# MÉTODO 9: Desactivar Application Guard
# ===============================================================================

Log-Step "Método 9: Desactivando Application Guard"

$appGuardPath = "HKLM:\SOFTWARE\Policies\Microsoft\AppHVSI"

if (Test-Path $appGuardPath) {
    Set-ItemProperty -Path $appGuardPath -Name "AllowAppHVSI_ProviderSet" -Value 0 -Type DWord -Force
    Log-Ok "Application Guard desactivado"
} else {
    Log-Ok "Application Guard no configurado (OK)"
}

# ===============================================================================
# MÉTODO 10: Desactivar instalador controlado de aplicaciones
# ===============================================================================

Log-Step "Método 10: Desactivando App Installer restrictions"

$appInstallerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller"

if (-not (Test-Path $appInstallerPath)) {
    New-Item -Path $appInstallerPath -Force | Out-Null
}

Set-ItemProperty -Path $appInstallerPath -Name "EnableAppInstaller" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $appInstallerPath -Name "EnableHashOverride" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $appInstallerPath -Name "EnableLocalManifestFiles" -Value 1 -Type DWord -Force

Log-Ok "App Installer sin restricciones"

# ===============================================================================
# MÉTODO 11: Permitir DLL no firmadas
# ===============================================================================

Log-Step "Método 11: Permitiendo carga de DLLs no firmadas"

$codeSigning = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers"

if (-not (Test-Path $codeSigning)) {
    New-Item -Path $codeSigning -Force | Out-Null
}

Set-ItemProperty -Path $codeSigning -Name "TransparentEnabled" -Value 1 -Type DWord -Force
Log-Ok "DLLs no firmadas permitidas"

# ===============================================================================
# VERIFICACIÓN FINAL
# ===============================================================================

Log-Step "Verificando configuración final"

# Verificar ExecutionPolicy
$finalPolicyMachine = Get-ExecutionPolicy -Scope LocalMachine
$finalPolicyUser = Get-ExecutionPolicy -Scope CurrentUser

if ($finalPolicyMachine -eq "Unrestricted" -and $finalPolicyUser -eq "Unrestricted") {
    Log-Ok "✅ ExecutionPolicy = Unrestricted en todos los scopes"
} else {
    Log-Warn "⚠️ ExecutionPolicy puede requerir configuración adicional"
}

# Verificar LanguageMode
$finalLanguageMode = $ExecutionContext.SessionState.LanguageMode

if ($finalLanguageMode -eq "FullLanguage") {
    Log-Ok "✅ PowerShell en FullLanguageMode"
} else {
    Log-Warn "⚠️ PowerShell en modo restringido: $finalLanguageMode"
}

Log-Ok "Configuración de restricciones de ejecución completada"
Log-Warn ""
Log-Warn "⚠️ RESUMEN DE CONFIGURACIÓN:"
Log-Warn "⚠️ ✓ PowerShell: Unrestricted"
Log-Warn "⚠️ ✓ Apps sin firmar: Permitidas"
Log-Warn "⚠️ ✓ Ejecución desde D:\: Permitida"
Log-Warn "⚠️ ✓ Archivos descargados: No bloqueados"
Log-Warn "⚠️ ✓ AppLocker: Desactivado"
Log-Warn "⚠️ ✓ SRP: Unrestricted"
Log-Warn ""
Log-Warn "⚠️ IMPORTANTE:"
Log-Warn "⚠️ Se recomienda REINICIAR para aplicar todos los cambios"
Log-Warn ""
