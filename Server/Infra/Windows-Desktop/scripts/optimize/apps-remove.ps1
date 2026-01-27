. "$PSScriptRoot/../lib/logs.ps1"

Log-Step "Eliminando apps integradas"

$apps = @(
  "*Xbox*","*GamingApp*","*OneDrive*","*MicrosoftTeams*",
  "*MicrosoftNews*","*Weather*","*ToDo*","*Maps*",
  "*PhoneLink*","*Outlook*","*Clipchamp*","*Solitaire*",
  "*Bing*","*Copilot*","*WebExperience*"
)

foreach ($a in $apps) {

  # Apps instaladas (usuarios existentes)
  Get-AppxPackage -AllUsers -Name $a -ErrorAction SilentlyContinue |
    Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

  # Apps provisionadas (usuarios futuros)
  Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
    Where-Object DisplayName -Like $a |
    Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

Log-Ok "Apps integradas eliminadas"
