# optimize-windows.ps1

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

. "$PSScriptRoot/lib/logs.ps1"

Log-Step "OPTIMIZACIÓN WINDOWS – MODO HARDCORE"

$modules = @(
 "privacy","telemetry","services",
 "search-indexing","apps-remove",
 "scheduled-tasks"
)

foreach ($m in $modules) {
  . "$PSScriptRoot/optimize/$m.ps1"
}

Log-Ok "Windows optimizado al máximo 🚀"
