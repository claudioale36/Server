# =========================================================
# Script: Desbloquear archivos PowerShell (.ps1)
# =========================================================
# HABILITAR EJECUCIÓN DE SCRIPTS (ejecutar una sola vez)
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# =========================================================
# Para desbloquear TODOS los scripts dentro de un directorio:
# Get-ChildItem "D:\Windows\" -Recurse -File | Unblock-File
# =========================================================
# Ejecución manual: .\unblock-script.ps1
# =========================================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Desbloqueo de scripts PowerShell" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pega la ruta completa del archivo .ps1" -ForegroundColor Yellow
Write-Host "(puedes arrastrar el archivo a esta ventana)" -ForegroundColor Yellow
Write-Host ""

$ScriptPath = Read-Host "Ruta del script"

# Limpiar comillas si vienen pegadas
$ScriptPath = $ScriptPath.Trim('"')

if (-not (Test-Path $ScriptPath)) {
    Write-Host ""
    Write-Host "❌ El archivo no existe:" -ForegroundColor Red
    Write-Host $ScriptPath
    exit 1
}

Write-Host ""
Write-Host "🔓 Desbloqueando archivo..." -ForegroundColor Cyan

try {
    Unblock-File -Path $ScriptPath -ErrorAction Stop
    Write-Host "✅ Script desbloqueado correctamente." -ForegroundColor Green
}
catch {
    Write-Host "❌ Error al desbloquear el script." -ForegroundColor Red
    Write-Host $_
}

Write-Host ""
Pause
