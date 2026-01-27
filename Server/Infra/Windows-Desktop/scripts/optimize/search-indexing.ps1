. "$PSScriptRoot/../lib/logs.ps1"
Log-Step "Configurando indexación segura"

# Mantener Windows Search activo
Set-Service WSearch -StartupType Automatic
Start-Service WSearch

# Excluir todo excepto NTFS local
$reg = "HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex"
New-Item $reg -Force | Out-Null
Set-ItemProperty $reg EnableUSNJournal 1

# Evitar indexar dispositivos removibles y red
$policy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
New-Item $policy -Force | Out-Null
Set-ItemProperty $policy DisableBackoff 1
Set-ItemProperty $policy PreventIndexingRemovableDrive 1
Set-ItemProperty $policy AllowIndexingEncryptedStoresOrItems 0

Log-Ok "Indexación limitada a NTFS"
