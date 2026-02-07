# ===============================================================================
# 00-disable-smartappcontrol.ps1
# ===============================================================================
# OBJETIVO: Desactivar completamente Smart App Control en Windows 11
# PRIORIDAD: CRÍTICA - Debe ejecutarse ANTES que cualquier otra configuración
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

. "$PSScriptRoot/../lib/logs.ps1"

Log-Step "DESACTIVANDO SMART APP CONTROL COMPLETAMENTE"

# ===============================================================================
# MÉTODO 1: Registro (Primary)
# ===============================================================================

Log-Step "Método 1: Configuración de registro"

$regPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy",
    "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
)

foreach ($path in $regPaths) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
        Log-Ok "Ruta de registro creada: $path"
    }
}

# Desactivar Smart App Control
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -Value 0 -Type DWord -Force
    Log-Ok "Smart App Control: VerifiedAndReputablePolicyState = 0"
    
    # Asegurar que está completamente OFF
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "PolicyState" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Log-Ok "Smart App Control: PolicyState = 0"
    
} catch {
    Log-Warn "Error configurando Smart App Control en registro: $_"
}

# ===============================================================================
# MÉTODO 2: Windows Defender SmartScreen (relacionado)
# ===============================================================================

Log-Step "Método 2: Desactivando SmartScreen"

$smartScreenPaths = @{
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" = @{
        "EnableSmartScreen" = 0
        "ShellSmartScreenLevel" = "Off"
    }
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" = @{
        "SmartScreenEnabled" = "Off"
    }
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" = @{
        "EnableWebContentEvaluation" = 0
        "PreventOverride" = 0
    }
    "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" = @{
        "SmartScreenEnabled" = 0
    }
}

foreach ($path in $smartScreenPaths.Keys) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    
    foreach ($key in $smartScreenPaths[$path].Keys) {
        $value = $smartScreenPaths[$path][$key]
        
        if ($value -is [string]) {
            Set-ItemProperty -Path $path -Name $key -Value $value -Type String -Force
        } else {
            Set-ItemProperty -Path $path -Name $key -Value $value -Type DWord -Force
        }
        
        Log-Ok "SmartScreen: $key configurado en $path"
    }
}

# ===============================================================================
# MÉTODO 3: Microsoft Edge SmartScreen
# ===============================================================================

Log-Step "Método 3: Desactivando Edge SmartScreen"

$edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (-not (Test-Path $edgePath)) {
    New-Item -Path $edgePath -Force | Out-Null
}

Set-ItemProperty -Path $edgePath -Name "SmartScreenEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $edgePath -Name "SmartScreenPuaEnabled" -Value 0 -Type DWord -Force

Log-Ok "Edge SmartScreen desactivado"

# ===============================================================================
# MÉTODO 4: Verificación del estado
# ===============================================================================

Log-Step "Verificando estado de Smart App Control"

try {
    $currentState = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -ErrorAction SilentlyContinue
    
    if ($currentState.VerifiedAndReputablePolicyState -eq 0) {
        Log-Ok "✅ Smart App Control está DESACTIVADO (estado = 0)"
    } else {
        Log-Warn "⚠️ Smart App Control puede seguir activo (estado = $($currentState.VerifiedAndReputablePolicyState))"
        Log-Warn "⚠️ Si Smart App Control fue activado durante la instalación de Windows,"
        Log-Warn "⚠️ puede requerir reinstalación de Windows para desactivarlo completamente."
    }
} catch {
    Log-Warn "No se pudo verificar el estado de Smart App Control"
}

# ===============================================================================
# MÉTODO 5: Desactivar protección en tiempo real relacionada
# ===============================================================================

Log-Step "Método 5: Desactivando protecciones en tiempo real asociadas"

$protectionPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
if (-not (Test-Path $protectionPath)) {
    New-Item -Path $protectionPath -Force | Out-Null
}

$protections = @{
    "DisableBehaviorMonitoring" = 1
    "DisableIOAVProtection" = 1
    "DisableOnAccessProtection" = 1
    "DisableRealtimeMonitoring" = 1
    "DisableScanOnRealtimeEnable" = 1
}

foreach ($key in $protections.Keys) {
    Set-ItemProperty -Path $protectionPath -Name $key -Value $protections[$key] -Type DWord -Force
    Log-Ok "Protección desactivada: $key"
}

# ===============================================================================
# NOTAS FINALES
# ===============================================================================

Log-Ok "Smart App Control y SmartScreen completamente desactivados"
Log-Warn ""
Log-Warn "⚠️ IMPORTANTE: Si este es un Windows 11 nuevo donde activaste Smart App Control"
Log-Warn "⚠️ durante la instalación inicial (OOBE), puede que necesites:"
Log-Warn "⚠️ 1. Reinstalar Windows SIN activar Smart App Control"
Log-Warn "⚠️ 2. O usar una imagen de Windows donde esté desactivado por defecto"
Log-Warn ""
Log-Ok "Configuración completada. Se recomienda reiniciar el sistema."
