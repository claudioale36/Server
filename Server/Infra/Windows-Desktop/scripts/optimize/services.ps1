# optimize/services.ps1

. "$PSScriptRoot/../lib/logs.ps1"

Log-Step "Desactivando servicios innecesarios"

$services = @(
  "SysMain",        # Superfetch
  "RetailDemo",
  "MapsBroker",
  "WMPNetworkSvc",
  "RemoteRegistry",
  "SharedAccess",   # ICS
  "Fax",
  "CDPUserSvc",
  "UnistoreSvc",
  "MessagingService"
)

foreach ($s in $services) {
    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue

    if ($null -eq $svc) {
        Log-Warn "Servicio no encontrado: $s"
        continue
    }

    try {
        if ($svc.Status -ne "Stopped") {
            Stop-Service $s -Force -ErrorAction Stop
        }
        Set-Service $s -StartupType Disabled
        Log-Ok "Servicio desactivado: $s"
    } catch {
        Log-Warn "No se pudo modificar el servicio $s"
    }
}

Log-Ok "Servicios optimizados (Bluetooth e impresión intactos)"
