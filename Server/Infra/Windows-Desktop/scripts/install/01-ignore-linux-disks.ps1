<#
  ignore-linux-disks.ps1
  Bloquea completamente discos Linux en Windows 11
  Diseñado para ser llamado desde setup-windows.ps1
#>

###################################################################
# 🔗 Cómo llamarlo desde setup-windows.ps1

# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
# $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path & "$ScriptDir\ignore-linux-disks.ps1"
###################################################################

############################################
# PERMISOS
############################################

if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ Este script debe ejecutarse como Administrador" -ForegroundColor Red
    exit 1
}

############################################
# LOGS
############################################

function log_step  { param($m) Write-Host "`n➡️  $m" -ForegroundColor Yellow }
function log_ok    { param($m) Write-Host "✅ $m"  -ForegroundColor Green }
function log_warn  { param($m) Write-Host "⚠️  $m" -ForegroundColor Yellow }
function log_error { param($m) Write-Host "❌ $m"  -ForegroundColor Red }

############################################
# CONFIGURACIÓN
############################################

# Discos Linux identificados
$LinuxDisks = @(0,2)

############################################
# BLOQUEO DE DISCOS
############################################

log_step "Bloqueando discos Linux (OFFLINE + ReadOnly)"

foreach (${diskNumber} in $LinuxDisks) {

    $disk = Get-Disk -Number ${diskNumber} -ErrorAction SilentlyContinue

    if (-not $disk) {
        log_warn "Disco ${diskNumber} no encontrado, se omite"
        continue
    }

    log_step "Procesando Disco ${diskNumber} ($($disk.FriendlyName))"

    try {
        if (-not $disk.IsOffline) {
            Set-Disk -Number ${diskNumber} -IsOffline $true
            log_ok "Disco ${diskNumber} puesto OFFLINE"
        } else {
            log_ok "Disco ${diskNumber} ya estaba OFFLINE"
        }

        if (-not $disk.IsReadOnly) {
            Set-Disk -Number ${diskNumber} -IsReadOnly $true
            log_ok "Disco ${diskNumber} marcado ReadOnly"
        } else {
            log_ok "Disco ${diskNumber} ya estaba ReadOnly"
        }

    } catch {
        log_error "Error bloqueando disco ${diskNumber}: $_"
    }
}

############################################
# DESACTIVAR INDEXADO DE UNIDADES NO NTFS
############################################

log_step "Configurando Windows Search para ignorar discos no Windows"

try {
    Stop-Service WSearch -Force -ErrorAction SilentlyContinue

    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex" `
             -Force | Out-Null

    Set-ItemProperty `
      -Path "HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex" `
      -Name "PreventIndexingUnmappedDrives" `
      -Value 1 `
      -Type DWord

    Start-Service WSearch

    log_ok "Indexador configurado correctamente"
} catch {
    log_error "Error configurando Windows Search: $_"
}

############################################
# DESACTIVAR DETECCIÓN AUTOMÁTICA DE DISCOS
############################################

log_step "Desactivando detección automática de hardware"

try {
    Stop-Service ShellHWDetection -Force -ErrorAction SilentlyContinue
    Set-Service ShellHWDetection -StartupType Disabled
    log_ok "ShellHWDetection desactivado"
} catch {
    log_error "Error desactivando ShellHWDetection: $_"
}

############################################
# VERIFICACIONES FINALES
############################################

log_step "Verificación final de discos"

$failed = $false

foreach (${diskNumber} in $LinuxDisks) {
    $disk = Get-Disk -Number ${diskNumber}

    if (-not $disk.IsOffline -or -not $disk.IsReadOnly) {
        log_error "Disco ${diskNumber} NO está correctamente bloqueado"
        $failed = $true
    } else {
        log_ok "Disco ${diskNumber} correctamente OFFLINE + ReadOnly"
    }
}

if (-not $failed) {
    log_ok "Todos los discos Linux están completamente ignorados por Windows"
} else {
    log_warn "Algunos discos no quedaron correctamente bloqueados"
}

############################################
# FIN
############################################
