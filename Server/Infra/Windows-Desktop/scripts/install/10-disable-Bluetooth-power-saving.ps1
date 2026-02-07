# D:\Windows-Desktop\scripts\bluetooth\10-disable-Bluetooth-power-saving.ps1
# Unblock-File -Path "D:\Windows-Desktop\scripts\bluetooth\10-disable-Bluetooth-power-saving.ps1"

############################################
# ADMIN CHECK (AUTO-ELEVATE)
############################################

if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Start-Process powershell `
        -Verb RunAs `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

############################################
# IMPORT MODULES
############################################

try {
    Import-Module "$PSScriptRoot\..\lib\Logging\Logging" -ErrorAction Stop
}
catch {
    Write-Error "No se pudo cargar el módulo Logging"
    exit 1
}

$ScriptName = Split-Path $PSCommandPath -Leaf
$LogFile = Join-Path $PSScriptRoot ($ScriptName -replace '\.ps1$', '.log')

############################################
# ENCODING / CONSOLE SAFE LOGGING
############################################

$UseUnicode = ($Host.Name -match "ConsoleHost|Windows Terminal")

Set-LogConfig `
    -UseUnicode $UseUnicode `
    -ToFile $true `
    -FilePath $LogFile

############################################
# 1. BLUETOOTH RADIO
############################################

Log-Step "Configurando radio Bluetooth"
Log-Step "Desactivando ahorro de energia Bluetooth (Desktop mode)"

$btDevices = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue

foreach ($dev in $btDevices) {
    $key = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters"
    if (Test-Path $key) {
        New-ItemProperty -Path $key -Name "SelectiveSuspendEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $key -Name "DeviceSelectiveSuspended" -Value 0 -PropertyType DWord -Force | Out-Null
    }
}

Log-Ok "Radio Bluetooth configurada"

############################################
# 2. HID BLUETOOTH
############################################

Log-Step "Configurando dispositivos HID Bluetooth"

$hidDevices = Get-PnpDevice -Class HIDClass -ErrorAction SilentlyContinue |
    Where-Object { $_.FriendlyName -match "Bluetooth" }

foreach ($dev in $hidDevices) {
    $key = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters"
    if (Test-Path $key) {
        New-ItemProperty -Path $key -Name "EnhancedPowerManagementEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
    }
}

Log-Ok "HID Bluetooth protegidos"

############################################
# 3. USB SELECTIVE SUSPEND (FIXED)
############################################

Log-Step "Desactivando USB Selective Suspend (AC)"

powercfg /setacvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVE 0
if ($LASTEXITCODE -ne 0) {
    Log-Warn "No se pudo modificar USB Selective Suspend (puede no existir en este sistema)"
} else {
    powercfg /setactive SCHEME_CURRENT | Out-Null
    Log-Ok "USB Selective Suspend desactivado"
}

############################################
# 4. BLUETOOTH SERVICES
############################################

Log-Step "Asegurando servicios Bluetooth"

Set-Service bthserv -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service bthserv -ErrorAction SilentlyContinue

Set-Service DeviceAssociationService -StartupType Automatic -ErrorAction SilentlyContinue

Log-Ok "Servicios Bluetooth activos"

############################################
# 5. POST-CHECKS
############################################

Log-Step "Verificando configuracion final"

$usbCheck = powercfg /query SCHEME_CURRENT SUB_USB USBSELECTIVE 2>$null
if ($usbCheck -and ($usbCheck -match "0x0")) {
    Log-Ok "USB Selective Suspend confirmado desactivado"
} else {
    Log-Warn "No se pudo confirmar estado de USB Selective Suspend"
}

if ($btDevices.Count -gt 0 -and $hidDevices.Count -gt 0) {
    Log-Ok "Bluetooth operativo y protegido contra suspension"
} else {
    Log-Warn "Bluetooth detectado parcialmente (revisar hardware)"
}

Log-Ok "Configuracion Bluetooth finalizada correctamente"
