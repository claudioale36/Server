. "$PSScriptRoot/../lib/logs.ps1"
Log-Step "Desactivando opciones de privacidad"

$policies = "HKLM:\SOFTWARE\Policies\Microsoft\Windows"

New-Item "$policies\AdvertisingInfo" -Force | Out-Null
Set-ItemProperty "$policies\AdvertisingInfo" DisabledByGroupPolicy 1

New-Item "$policies\CloudContent" -Force | Out-Null
Set-ItemProperty "$policies\CloudContent" DisableWindowsConsumerFeatures 1
Set-ItemProperty "$policies\CloudContent" DisableTailoredExperiencesWithDiagnosticData 1

New-Item "$policies\System" -Force | Out-Null
Set-ItemProperty "$policies\System" EnableActivityFeed 0
Set-ItemProperty "$policies\System" PublishUserActivities 0
Set-ItemProperty "$policies\System" UploadUserActivities 0

Log-Ok "Privacidad aplicada"
