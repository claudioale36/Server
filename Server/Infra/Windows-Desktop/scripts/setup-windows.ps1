# setup-windows.ps1

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$PSStyle.OutputRendering = "Ansi"

. "$PSScriptRoot/lib/logs.ps1"

Log-Step "SETUP WINDOWS – ESTADO BASE + OPTIMIZACIÓN"

# -----------------
# INSTALL
# -----------------
Log-Step "FASE 1: Configuración inicial del sistema"

Get-ChildItem "$PSScriptRoot/install" -Filter "*.ps1" |
  Where-Object { $_.Name -notmatch '^99-' } |
  Sort-Object Name |
  ForEach-Object {
    Log-Step "Ejecutando $($_.Name)"
    . $_.FullName
  }

Log-Ok "Configuración inicial completa"

# -----------------
# UPDATE
# -----------------
Log-Step "FASE 2: Actualización del sistema"

. "$PSScriptRoot/install/99-update.ps1"

Log-Ok "Sistema actualizado"

# -----------------
# OPTIMIZE
# -----------------
Log-Step "FASE 3: Optimización y hardening"

. "$PSScriptRoot/optimize-windows.ps1"

Log-Ok "Setup completo 🚀"
