# ===============================================================================
# 02-disable-uac.ps1
# ===============================================================================
# OBJETIVO: Desactivar completamente UAC (User Account Control)
# PRIORIDAD: CRÍTICA - Entorno FULL DEV sin prompts molestos
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

. "$PSScriptRoot/../lib/logs.ps1"

Log-Step "DESACTIVANDO UAC COMPLETAMENTE"

# ===============================================================================
# MÉTODO 1: Registro (Configuración estándar)
# ===============================================================================

Log-Step "Método 1: Configurando UAC via registro"

$uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

# ConsentPromptBehaviorAdmin:
#   0 = Elevar sin prompt (FULL DISABLE)
#   1 = Pedir credenciales en secure desktop
#   2 = Pedir consentimiento en secure desktop
#   5 = Pedir consentimiento (default)

Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force
Log-Ok "ConsentPromptBehaviorAdmin = 0 (sin prompts)"

# EnableLUA:
#   0 = UAC completamente desactivado
#   1 = UAC activado

Set-ItemProperty -Path $uacPath -Name "EnableLUA" -Value 0 -Type DWord -Force
Log-Ok "EnableLUA = 0 (UAC desactivado)"

# PromptOnSecureDesktop:
#   0 = No usar Secure Desktop
#   1 = Usar Secure Desktop (default)

Set-ItemProperty -Path $uacPath -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force
Log-Ok "PromptOnSecureDesktop = 0"

# ConsentPromptBehaviorUser:
#   0 = Auto-denegar requests de elevación
#   1 = Pedir credenciales en secure desktop
#   3 = Pedir credenciales (default)

Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorUser" -Value 0 -Type DWord -Force
Log-Ok "ConsentPromptBehaviorUser = 0"

# ValidateAdminCodeSignatures:
#   0 = No validar firmas (permite apps sin firmar)
#   1 = Validar firmas

Set-ItemProperty -Path $uacPath -Name "ValidateAdminCodeSignatures" -Value 0 -Type DWord -Force
Log-Ok "ValidateAdminCodeSignatures = 0 (apps sin firmar permitidas)"

# FilterAdministratorToken:
#   0 = Cuenta Admin integrada opera con full token
#   1 = Cuenta Admin opera con token filtrado

Set-ItemProperty -Path $uacPath -Name "FilterAdministratorToken" -Value 0 -Type DWord -Force
Log-Ok "FilterAdministratorToken = 0"

# ===============================================================================
# MÉTODO 2: Desactivar UAC Virtualization
# ===============================================================================

Log-Step "Método 2: Desactivando UAC Virtualization"

Set-ItemProperty -Path $uacPath -Name "EnableVirtualization" -Value 0 -Type DWord -Force
Log-Ok "EnableVirtualization = 0"

# ===============================================================================
# MÉTODO 3: Desactivar Installer Detection
# ===============================================================================

Log-Step "Método 3: Desactivando Installer Detection"

# EnableInstallerDetection:
#   0 = No detectar instaladores (sin prompts)
#   1 = Detectar instaladores (default)

Set-ItemProperty -Path $uacPath -Name "EnableInstallerDetection" -Value 0 -Type DWord -Force
Log-Ok "EnableInstallerDetection = 0"

# ===============================================================================
# MÉTODO 4: Configurar comportamiento para aplicaciones UIAccess
# ===============================================================================

Log-Step "Método 4: Configurando UIAccess"

# EnableUIADesktopToggle:
#   0 = No permitir apps UIAccess sin elevación
#   1 = Permitir apps UIAccess

Set-ItemProperty -Path $uacPath -Name "EnableUIADesktopToggle" -Value 0 -Type DWord -Force
Log-Ok "EnableUIADesktopToggle = 0"

# ===============================================================================
# MÉTODO 5: Group Policy adicional
# ===============================================================================

Log-Step "Método 5: Configurando políticas adicionales"

$policiesPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"

if (-not (Test-Path $policiesPath)) {
    New-Item -Path $policiesPath -Force | Out-Null
}

# Permitir instalaciones sin elevación
Set-ItemProperty -Path $policiesPath -Name "AlwaysInstallElevated" -Value 1 -Type DWord -Force
Log-Ok "AlwaysInstallElevated = 1 (instalaciones sin prompt)"

# ===============================================================================
# MÉTODO 6: Desactivar notificaciones de UAC
# ===============================================================================

Log-Step "Método 6: Desactivando notificaciones"

$notificationsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance"

if (-not (Test-Path $notificationsPath)) {
    New-Item -Path $notificationsPath -Force | Out-Null
}

Set-ItemProperty -Path $notificationsPath -Name "Enabled" -Value 0 -Type DWord -Force
Log-Ok "Notificaciones de seguridad desactivadas"

# ===============================================================================
# VERIFICACIÓN
# ===============================================================================

Log-Step "Verificando configuración de UAC"

$enableLUA = (Get-ItemProperty -Path $uacPath -Name "EnableLUA").EnableLUA
$consentPrompt = (Get-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin").ConsentPromptBehaviorAdmin

if ($enableLUA -eq 0 -and $consentPrompt -eq 0) {
    Log-Ok "✅ UAC está COMPLETAMENTE DESACTIVADO"
} else {
    Log-Warn "⚠️ UAC puede seguir parcialmente activo"
    Log-Warn "   EnableLUA = $enableLUA (debe ser 0)"
    Log-Warn "   ConsentPromptBehaviorAdmin = $consentPrompt (debe ser 0)"
}

Log-Ok "Configuración de UAC completada"
Log-Warn ""
Log-Warn "⚠️ IMPORTANTE:"
Log-Warn "⚠️ 1. DEBES REINICIAR el sistema para que UAC se desactive completamente"
Log-Warn "⚠️ 2. Algunos cambios pueden requerir 2 reinicios consecutivos"
Log-Warn "⚠️ 3. Después del reinicio, no deberías ver más prompts de UAC"
Log-Warn ""
Log-Warn "⚠️ SEGURIDAD:"
Log-Warn "⚠️ Con UAC desactivado, cualquier aplicación puede obtener permisos admin"
Log-Warn "⚠️ sin confirmación. Esto es adecuado SOLO para entornos de desarrollo"
Log-Warn "⚠️ controlados y NO para uso general/producción."
Log-Warn ""
