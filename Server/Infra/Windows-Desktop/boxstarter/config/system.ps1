# D:\Windows-Desktop\boxstarter\config\system.ps1

Write-Host "==> Configurando sistema"

# Mostrar extensiones de archivo
Set-ItemProperty `
  HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
  HideFileExt 0

# Mostrar archivos ocultos
Set-ItemProperty `
  HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
  Hidden 1

# Desactivar recomendaciones y basura visual
Disable-GameBarTips
Disable-BingSearch
Disable-ConsumerFeatures

# Timezone
Set-TimeZone -Id "Argentina Standard Time"

# Explorador clásico
Set-WindowsExplorerOptions -EnableShowFileExtensions -EnableShowHiddenFiles
