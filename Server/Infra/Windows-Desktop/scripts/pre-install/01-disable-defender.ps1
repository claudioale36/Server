# ===============================================================================
# 01-disable-defender.ps1
# ===============================================================================
# OBJETIVO: Desactivar COMPLETAMENTE Windows Defender y todas sus protecciones
# PRIORIDAD: CRÍTICA - Entorno FULL DEV sin restricciones
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

. "$PSScriptRoot/../lib/logs.ps1"

Log-Step "DESACTIVANDO WINDOWS DEFENDER COMPLETAMENTE"

# ===============================================================================
# MÉTODO 1: Group Policy via Registro
# ===============================================================================

Log-Step "Método 1: Desactivando Defender via Group Policy"

$defenderPolicies = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"

if (-not (Test-Path $defenderPolicies)) {
    New-Item -Path $defenderPolicies -Force | Out-Null
}

# Desactivar Defender completamente
Set-ItemProperty -Path $defenderPolicies -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $defenderPolicies -Name "DisableAntiVirus" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $defenderPolicies -Name "ServiceKeepAlive" -Value 0 -Type DWord -Force

Log-Ok "Defender desactivado via Group Policy"

# ===============================================================================
# MÉTODO 2: Real-Time Protection
# ===============================================================================

Log-Step "Método 2: Desactivando protección en tiempo real"

$rtProtection = "$defenderPolicies\Real-Time Protection"

if (-not (Test-Path $rtProtection)) {
    New-Item -Path $rtProtection -Force | Out-Null
}

$rtSettings = @{
    "DisableBehaviorMonitoring" = 1
    "DisableIOAVProtection" = 1
    "DisableOnAccessProtection" = 1
    "DisableRealtimeMonitoring" = 1
    "DisableScanOnRealtimeEnable" = 1
    "DisableRawWriteNotification" = 1
}

foreach ($key in $rtSettings.Keys) {
    Set-ItemProperty -Path $rtProtection -Name $key -Value $rtSettings[$key] -Type DWord -Force
    Log-Ok "Real-Time Protection: $key desactivado"
}

# ===============================================================================
# MÉTODO 3: Spynet (Telemetría de Defender)
# ===============================================================================

Log-Step "Método 3: Desactivando SpyNet"

$spynet = "$defenderPolicies\Spynet"

if (-not (Test-Path $spynet)) {
    New-Item -Path $spynet -Force | Out-Null
}

Set-ItemProperty -Path $spynet -Name "SpyNetReporting" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $spynet -Name "SubmitSamplesConsent" -Value 2 -Type DWord -Force

Log-Ok "SpyNet desactivado"

# ===============================================================================
# MÉTODO 4: Exclusiones (toda la unidad D:)
# ===============================================================================

Log-Step "Método 4: Agregando exclusiones globales"

$exclusions = "$defenderPolicies\Exclusions"

# Rutas excluidas
$pathsKey = "$exclusions\Paths"
if (-not (Test-Path $pathsKey)) {
    New-Item -Path $pathsKey -Force | Out-Null
}

# Excluir toda la unidad D:
Set-ItemProperty -Path $pathsKey -Name "D:\" -Value 0 -Type String -Force
Set-ItemProperty -Path $pathsKey -Name "D:\*" -Value 0 -Type String -Force

# Excluir directorios comunes de desarrollo
$devPaths = @("C:\dev", "C:\code", "C:\projects", "D:\dev", "D:\apps", "D:\raiz")
foreach ($path in $devPaths) {
    Set-ItemProperty -Path $pathsKey -Name $path -Value 0 -Type String -Force
}

Log-Ok "Exclusiones de rutas configuradas"

# Extensiones excluidas
$extensionsKey = "$exclusions\Extensions"
if (-not (Test-Path $extensionsKey)) {
    New-Item -Path $extensionsKey -Force | Out-Null
}

$devExtensions = @("exe", "dll", "ps1", "bat", "cmd", "vbs", "js", "py", "sh", "msi")
foreach ($ext in $devExtensions) {
    Set-ItemProperty -Path $extensionsKey -Name $ext -Value 0 -Type String -Force
}

Log-Ok "Exclusiones de extensiones configuradas"

# ===============================================================================
# MÉTODO 5: Desactivar servicios de Defender
# ===============================================================================

Log-Step "Método 5: Desactivando servicios de Defender"

$services = @(
    "WinDefend",           # Windows Defender Antivirus Service
    "WdNisSvc",            # Windows Defender Network Inspection Service
    "WdNisDrv",            # Windows Defender Network Inspection Driver
    "WdBoot",              # Windows Defender Boot Driver
    "WdFilter",            # Windows Defender Mini-Filter Driver
    "Sense",               # Windows Defender Advanced Threat Protection
    "SecurityHealthService" # Windows Security Service
)

foreach ($svc in $services) {
    try {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        
        if ($null -ne $service) {
            if ($service.Status -ne "Stopped") {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Log-Ok "Servicio detenido: $svc"
            }
            
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Log-Ok "Servicio desactivado: $svc"
        }
    } catch {
        Log-Warn "No se pudo modificar servicio: $svc - $_"
    }
}

# ===============================================================================
# MÉTODO 6: Desactivar Tamper Protection via registro
# ===============================================================================

Log-Step "Método 6: Desactivando Tamper Protection"

$features = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"

if (-not (Test-Path $features)) {
    New-Item -Path $features -Force | Out-Null
}

Set-ItemProperty -Path $features -Name "TamperProtection" -Value 0 -Type DWord -Force

Log-Ok "Tamper Protection desactivado"

# ===============================================================================
# MÉTODO 7: Desactivar Windows Security Center
# ===============================================================================

Log-Step "Método 7: Desactivando Security Center"

$securityCenter = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications"

if (-not (Test-Path $securityCenter)) {
    New-Item -Path $securityCenter -Force | Out-Null
}

Set-ItemProperty -Path $securityCenter -Name "DisableNotifications" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $securityCenter -Name "DisableEnhancedNotifications" -Value 1 -Type DWord -Force

Log-Ok "Security Center notifications desactivadas"

# ===============================================================================
# MÉTODO 8: Desactivar Exploit Protection
# ===============================================================================

Log-Step "Método 8: Desactivando Exploit Protection"

$exploitProtection = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Exploit Protection"

if (-not (Test-Path $exploitProtection)) {
    New-Item -Path $exploitProtection -Force | Out-Null
}

Set-ItemProperty -Path $exploitProtection -Name "ExploitProtectionSettings" -Value 0 -Type DWord -Force

Log-Ok "Exploit Protection desactivado"

# ===============================================================================
# MÉTODO 9: Desactivar mediante PowerShell cmdlets (si disponibles)
# ===============================================================================

Log-Step "Método 9: Desactivando via PowerShell cmdlets"

try {
    # Intentar usar Set-MpPreference si está disponible
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
    Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
    Set-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue
    
    Log-Ok "Defender configurado via cmdlets PowerShell"
} catch {
    Log-Warn "Cmdlets de Defender no disponibles (normal si ya está desactivado)"
}

# ===============================================================================
# MÉTODO 10: Desactivar tareas programadas de Defender
# ===============================================================================

Log-Step "Método 10: Desactivando tareas programadas de Defender"

$defenderTasks = @(
    "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance",
    "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup",
    "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan",
    "\Microsoft\Windows\Windows Defender\Windows Defender Verification"
)

foreach ($task in $defenderTasks) {
    try {
        $scheduledTask = Get-ScheduledTask -TaskPath (Split-Path $task -Parent) -TaskName (Split-Path $task -Leaf) -ErrorAction SilentlyContinue
        
        if ($null -ne $scheduledTask) {
            Disable-ScheduledTask -TaskPath (Split-Path $task -Parent) -TaskName (Split-Path $task -Leaf) -ErrorAction SilentlyContinue
            Log-Ok "Tarea desactivada: $task"
        }
    } catch {
        Log-Warn "No se pudo desactivar tarea: $task"
    }
}

# ===============================================================================
# VERIFICACIÓN FINAL
# ===============================================================================

Log-Step "Verificando configuración de Defender"

try {
    $defenderStatus = Get-ItemProperty -Path $defenderPolicies -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
    
    if ($defenderStatus.DisableAntiSpyware -eq 1) {
        Log-Ok "✅ Windows Defender está DESACTIVADO"
    } else {
        Log-Warn "⚠️ Windows Defender puede seguir parcialmente activo"
    }
} catch {
    Log-Warn "No se pudo verificar el estado de Defender"
}

Log-Ok "Configuración de Defender completada"
Log-Warn ""
Log-Warn "⚠️ IMPORTANTE:"
Log-Warn "⚠️ 1. Se recomienda REINICIAR el sistema para aplicar todos los cambios"
Log-Warn "⚠️ 2. Algunas configuraciones pueden requerir LGPO.exe para persistir"
Log-Warn "⚠️ 3. En Windows 11 Home, Tamper Protection puede requerir desactivación manual"
Log-Warn ""
