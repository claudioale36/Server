. "$PSScriptRoot/../lib/logs.ps1"

Log-Step "Buscando actualizaciones de Windows"

# Asegurar TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Instalar módulo solo si no existe
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
  Log-Step "Instalando módulo PSWindowsUpdate"
  Install-Module PSWindowsUpdate -Force -Scope AllUsers -ErrorAction Stop
  Log-Ok "Módulo PSWindowsUpdate instalado"
}

Import-Module PSWindowsUpdate -ErrorAction Stop

# Ejecutar actualizaciones
$updates = Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction Continue

if ($updates) {
  Log-Warn "Actualizaciones aplicadas. Reinicio puede ser requerido."
} else {
  Log-Ok "Sistema ya actualizado"
}
