# ===============================================================================
# export-all.ps1
# ===============================================================================
# OBJETIVO: Exportar configuraciones críticas del registro para backup
# USAR EN: Sistema configurado que quieres respaldar
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

$ErrorActionPreference = "Continue"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "EXPORTANDO CONFIGURACIONES DEL REGISTRO" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

# Ruta de backups
$backupDir = Join-Path (Split-Path -Parent $PSCommandPath) "backups"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupSession = Join-Path $backupDir $timestamp

# Crear directorio de backup
if (-not (Test-Path $backupSession)) {
    New-Item -ItemType Directory -Path $backupSession -Force | Out-Null
    Write-Host "✅ Directorio de backup creado: $backupSession" -ForegroundColor Green
    Write-Host ""
}

# ===============================================================================
# DEFINIR CLAVES A EXPORTAR
# ===============================================================================

$registryExports = @(
    @{
        Name = "UAC"
        Path = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Description = "Configuración de User Account Control"
    },
    @{
        Name = "Defender"
        Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender"
        Description = "Políticas de Windows Defender"
    },
    @{
        Name = "SmartScreen"
        Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\System"
        Description = "Configuración de SmartScreen"
    },
    @{
        Name = "PowerShell-ExecutionPolicy"
        Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell"
        Description = "Políticas de ejecución de PowerShell"
    },
    @{
        Name = "Explorer-Options"
        Path = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Description = "Opciones del Explorador de archivos"
    },
    @{
        Name = "Privacy"
        Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
        Description = "Configuración de privacidad"
    },
    @{
        Name = "Telemetry"
        Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        Description = "Configuración de telemetría"
    },
    @{
        Name = "WindowsUpdate"
        Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        Description = "Configuración de Windows Update"
    },
    @{
        Name = "AppExecution"
        Path = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments"
        Description = "Políticas de ejecución de aplicaciones"
    },
    @{
        Name = "InternetZones"
        Path = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones"
        Description = "Zonas de seguridad de Internet"
    },
    @{
        Name = "GameBar"
        Path = "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR"
        Description = "Configuración de GameBar"
    },
    @{
        Name = "Cortana"
        Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        Description = "Configuración de Cortana"
    },
    @{
        Name = "SmartAppControl"
        Path = "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy"
        Description = "Smart App Control"
    }
)

# ===============================================================================
# EXPORTAR CADA CLAVE
# ===============================================================================

$successCount = 0
$errorCount = 0

foreach ($export in $registryExports) {
    Write-Host "➡️  Exportando: $($export.Name)" -ForegroundColor Yellow
    Write-Host "   Descripción: $($export.Description)" -ForegroundColor Gray
    Write-Host "   Ruta: $($export.Path)" -ForegroundColor Gray
    
    $outputFile = Join-Path $backupSession "$($export.Name).reg"
    
    try {
        # Exportar usando reg.exe (más confiable que Export-Registry)
        $result = reg export "$($export.Path)" "$outputFile" /y 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Exportado a: $outputFile" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "   ⚠️  Clave no existe o no se pudo exportar" -ForegroundColor Yellow
            $errorCount++
        }
        
    } catch {
        Write-Host "   ❌ Error: $_" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
}

# ===============================================================================
# EXPORTAR CONFIGURACIÓN COMPLETA (opcional)
# ===============================================================================

Write-Host "➡️  ¿Deseas exportar una copia completa del registro? (ADVERTENCIA: archivo grande)" -ForegroundColor Yellow
$fullExport = Read-Host "   (s/N)"

if ($fullExport -eq "s" -or $fullExport -eq "S") {
    Write-Host ""
    Write-Host "   Exportando registro completo... (esto puede tardar varios minutos)" -ForegroundColor Gray
    
    $fullBackup = Join-Path $backupSession "FULL-REGISTRY-BACKUP.reg"
    
    try {
        reg export HKLM "$fullBackup" /y | Out-Null
        Write-Host "   ✅ Backup completo creado: $fullBackup" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  No se pudo crear backup completo: $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ===============================================================================
# CREAR ARCHIVO DE INFORMACIÓN
# ===============================================================================

$infoFile = Join-Path $backupSession "README.txt"

$infoContent = @"
===============================================================================
BACKUP DE REGISTRO - WINDOWS DEV ENVIRONMENT
===============================================================================

Fecha de creación: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Usuario: $env:USERNAME
Computadora: $env:COMPUTERNAME
Sistema: $(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption)

===============================================================================
ARCHIVOS INCLUIDOS
===============================================================================

$($registryExports | ForEach-Object { "- $($_.Name).reg : $($_.Description)" } | Out-String)

===============================================================================
CÓMO RESTAURAR
===============================================================================

1. Ejecuta el script: import-all.ps1
2. O importa archivos individuales haciendo doble clic en ellos
3. O usa: reg import <archivo.reg>

===============================================================================
ADVERTENCIAS
===============================================================================

⚠️  Importar configuraciones de registro puede afectar el sistema
⚠️  Asegúrate de estar importando en un sistema compatible
⚠️  Se recomienda crear un punto de restauración antes de importar
⚠️  Algunas configuraciones requieren reinicio

===============================================================================
"@

$infoContent | Out-File -FilePath $infoFile -Encoding UTF8

# ===============================================================================
# RESUMEN
# ===============================================================================

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "RESUMEN DE EXPORTACIÓN" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Archivos exportados exitosamente: $successCount" -ForegroundColor Green
Write-Host "Archivos con errores: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Yellow" } else { "Green" })
Write-Host ""
Write-Host "Ubicación del backup: $backupSession" -ForegroundColor White
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host "✅ EXPORTACIÓN COMPLETADA" -ForegroundColor Green
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Tus configuraciones han sido respaldadas" -ForegroundColor White
    Write-Host ""
    Write-Host "Para restaurar estas configuraciones en otro sistema:" -ForegroundColor Yellow
    Write-Host "  1. Copia la carpeta: $backupSession" -ForegroundColor White
    Write-Host "  2. Ejecuta: import-all.ps1 desde esa carpeta" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "❌ No se pudo exportar ninguna configuración" -ForegroundColor Red
    Write-Host ""
}

# Abrir carpeta de backup
$openFolder = Read-Host "¿Deseas abrir la carpeta de backup? (s/N)"

if ($openFolder -eq "s" -or $openFolder -eq "S") {
    Start-Process explorer.exe -ArgumentList $backupSession
}

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
