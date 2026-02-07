# D:\Windows-Desktop\boxstarter\config\power.ps1

Write-Host "==> Configurando energía"

# Alto rendimiento
powercfg /setactive SCHEME_MIN

# Nunca suspender
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 15
powercfg /change hibernate-timeout-ac 0

# Desactivar hibernación (libera espacio)
powercfg /hibernate off
