. "$PSScriptRoot/../lib/logs.ps1"
Log-Step "Desactivando Telemetría"

$base = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
New-Item -Path $base -Force | Out-Null
Set-ItemProperty $base AllowTelemetry 0 -Type DWord
Set-ItemProperty $base DisableTelemetryOptInSettingsUx 1 -Type DWord

$services = @("DiagTrack","dmwappushservice","WerSvc")
foreach ($s in $services) {
  Stop-Service $s -ErrorAction SilentlyContinue
  Set-Service  $s -StartupType Disabled
}

Log-Ok "Telemetría desactivada"
