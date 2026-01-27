. "$PSScriptRoot/../lib/logs.ps1"

Log-Step "Creando servicios y tareas programadas"

$scriptRoot = Split-Path (Resolve-Path "$PSScriptRoot/..") -Parent
$setupScript = "$scriptRoot\setup-windows.ps1"

# -----------------------------
# 1. TAREA: ReapplyWindowsHardening
# -----------------------------

$taskName = "ReapplyWindowsHardening"

# Eliminar si existe (idempotente)
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
  Log-Warn "Tarea existente eliminada: $taskName"
}

$action = New-ScheduledTaskAction `
  -Execute "powershell.exe" `
  -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$setupScript`""

$trigger = New-ScheduledTaskTrigger -AtStartup

$principal = New-ScheduledTaskPrincipal `
  -UserId "SYSTEM" `
  -LogonType ServiceAccount `
  -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

Register-ScheduledTask `
  -TaskName $taskName `
  -Action $action `
  -Trigger $trigger `
  -Principal $principal `
  -Settings $settings `
  -Force

Log-Ok "Tarea '$taskName' creada (ONSTART)"

# -----------------------------
# 2. COMANDO ON-DEMAND: reharden
# -----------------------------

$aliasPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\reharden.exe"
New-Item $aliasPath -Force | Out-Null

Set-ItemProperty $aliasPath "(Default)" "powershell.exe"
Set-ItemProperty $aliasPath "Path" $env:SystemRoot
Set-ItemProperty $aliasPath "Arguments" "-ExecutionPolicy Bypass -File `"$setupScript`""

Log-Ok "Comando 'reharden' disponible globalmente"

Log-Ok "Servicios de automatización creados correctamente"
