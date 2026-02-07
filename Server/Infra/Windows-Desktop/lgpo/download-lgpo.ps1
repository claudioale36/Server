# ===============================================================================
# download-lgpo.ps1
# ===============================================================================
# OBJETIVO: Descargar LGPO.exe (Local Group Policy Object utility)
# FUENTE: Microsoft Security Compliance Toolkit
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

$ErrorActionPreference = "Stop"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "DESCARGANDO LGPO.exe - Local Group Policy Object Utility" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

# Rutas
$lgpoDir = Split-Path -Parent $PSCommandPath
$lgpoExe = Join-Path $lgpoDir "LGPO.exe"

# Verificar si ya existe
if (Test-Path $lgpoExe) {
    Write-Host "✅ LGPO.exe ya existe en: $lgpoExe" -ForegroundColor Green
    Write-Host ""
    
    $overwrite = Read-Host "¿Deseas descargar nuevamente? (s/N)"
    
    if ($overwrite -ne "s" -and $overwrite -ne "S") {
        Write-Host "✅ Usando LGPO.exe existente" -ForegroundColor Green
        exit 0
    }
}

# URLs (actualizar si cambia la versión)
$downloadUrl = "https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip"
$zipFile = Join-Path $lgpoDir "LGPO.zip"
$extractDir = Join-Path $lgpoDir "LGPO_extracted"

Write-Host "📥 Descargando LGPO.zip..." -ForegroundColor Yellow

try {
    # Descargar
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
    Write-Host "✅ Descarga completada" -ForegroundColor Green
    
    # Extraer
    Write-Host "📦 Extrayendo archivos..." -ForegroundColor Yellow
    Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force
    
    # Buscar LGPO.exe en el zip extraído
    $lgpoInZip = Get-ChildItem -Path $extractDir -Filter "LGPO.exe" -Recurse | Select-Object -First 1
    
    if ($null -eq $lgpoInZip) {
        throw "LGPO.exe no encontrado en el archivo descargado"
    }
    
    # Copiar a la ubicación final
    Copy-Item -Path $lgpoInZip.FullName -Destination $lgpoExe -Force
    
    # Limpiar
    Remove-Item -Path $zipFile -Force
    Remove-Item -Path $extractDir -Recurse -Force
    
    Write-Host "✅ LGPO.exe instalado correctamente en: $lgpoExe" -ForegroundColor Green
    
    # Verificar
    $version = & $lgpoExe /? 2>&1 | Select-String -Pattern "version" -SimpleMatch
    
    if ($version) {
        Write-Host "✅ Versión: $version" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "✅ INSTALACIÓN COMPLETADA" -ForegroundColor Green
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "LGPO.exe está listo para aplicar Group Policies desde código" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "INSTRUCCIONES MANUALES:" -ForegroundColor Yellow
    Write-Host "1. Visita: https://www.microsoft.com/en-us/download/details.aspx?id=55319" -ForegroundColor White
    Write-Host "2. Descarga 'Microsoft Security Compliance Toolkit'" -ForegroundColor White
    Write-Host "3. Extrae LGPO.exe del zip" -ForegroundColor White
    Write-Host "4. Copia LGPO.exe a: $lgpoDir" -ForegroundColor White
    Write-Host ""
    
    exit 1
}
