# ===============================================================================
# import-all.ps1
# ===============================================================================
# OBJETIVO: Importar configuraciones del registro desde backup
# USAR EN: Sistema nuevo que quieres configurar con el backup
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

$ErrorActionPreference = "Continue"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "IMPORTANDO CONFIGURACIONES DEL REGISTRO" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

# ===============================================================================
# SELECCIONAR CARPETA DE BACKUP
# ===============================================================================

$backupDir = Join-Path (Split-Path -Parent $PSCommandPath) "backups"

if (-not (Test-Path $backupDir)) {
    Write-Host "❌ ERROR: No se encontró el directorio de backups: $backupDir" -ForegroundColor Red
    exit 1
}

# Listar backups disponibles
$backups = Get-ChildItem -Path $backupDir -Directory | Sort-Object Name -Descending

if ($backups.Count -eq 0) {
    Write-Host "❌ ERROR: No hay backups disponibles en: $backupDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "Primero ejecuta: export-all.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "Backups disponibles:" -ForegroundColor Yellow
Write-Host ""

for ($i = 0; $i -lt $backups.Count; $i++) {
    $backup = $backups[$i]
    $readmeFile = Join-Path $backup.FullName "README.txt"
    
    if (Test-Path $readmeFile) {
        $dateInfo = Get-Content $readmeFile | Select-String "Fecha de creación" | Select-Object -First 1
        Write-Host "  [$($i + 1)] $($backup.Name) - $dateInfo" -ForegroundColor White
    } else {
        Write-Host "  [$($i + 1)] $($backup.Name)" -ForegroundColor White
    }
}

Write-Host ""
$selection = Read-Host "Selecciona el número de backup a importar (o Enter para el más reciente)"

if ([string]::IsNullOrWhiteSpace($selection)) {
    $selectedBackup = $backups[0]
    Write-Host "Seleccionado: $($selectedBackup.Name) (más reciente)" -ForegroundColor Green
} else {
    $index = [int]$selection - 1
    
    if ($index -lt 0 -or $index -ge $backups.Count) {
        Write-Host "❌ ERROR: Selección inválida" -ForegroundColor Red
        exit 1
    }
    
    $selectedBackup = $backups[$index]
    Write-Host "Seleccionado: $($selectedBackup.Name)" -ForegroundColor Green
}

Write-Host ""

# ===============================================================================
# ADVERTENCIA
# ===============================================================================

Write-Host "===============================================================================" -ForegroundColor Yellow
Write-Host "⚠️  ADVERTENCIA" -ForegroundColor Yellow
Write-Host "===============================================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Estás a punto de importar configuraciones de registro." -ForegroundColor White
Write-Host "Esto MODIFICARÁ el registro del sistema y puede afectar su comportamiento." -ForegroundColor White
Write-Host ""
Write-Host "Se recomienda:" -ForegroundColor Yellow
Write-Host "  1. Crear un punto de restauración del sistema" -ForegroundColor Gray
Write-Host "  2. Asegurarte de que el backup es compatible con este sistema" -ForegroundColor Gray
Write-Host "  3. Reiniciar después de la importación" -ForegroundColor Gray
Write-Host ""

$continue = Read-Host "¿Deseas continuar? (s/N)"

if ($continue -ne "s" -and $continue -ne "S") {
    Write-Host ""
    Write-Host "Operación cancelada" -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# ===============================================================================
# CREAR PUNTO DE RESTAURACIÓN (opcional)
# ===============================================================================

Write-Host "➡️  ¿Deseas crear un punto de restauración del sistema?" -ForegroundColor Yellow
$createRestore = Read-Host "   (S/n)"

if ($createRestore -ne "n" -and $createRestore -ne "N") {
    Write-Host ""
    Write-Host "   Creando punto de restauración..." -ForegroundColor Gray
    
    try {
        # Habilitar System Restore si no está habilitado
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        
        # Crear punto de restauración
        Checkpoint-Computer -Description "Antes de importar configuraciones de registro" -RestorePointType "MODIFY_SETTINGS"
        
        Write-Host "   ✅ Punto de restauración creado" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  No se pudo crear punto de restauración: $_" -ForegroundColor Yellow
        Write-Host "   Continuando de todas formas..." -ForegroundColor Gray
    }
    
    Write-Host ""
}

# ===============================================================================
# IMPORTAR ARCHIVOS .REG
# ===============================================================================

Write-Host "➡️  Importando archivos de registro..." -ForegroundColor Yellow
Write-Host ""

$regFiles = Get-ChildItem -Path $selectedBackup.FullName -Filter "*.reg" | 
    Where-Object { $_.Name -ne "FULL-REGISTRY-BACKUP.reg" }

$successCount = 0
$errorCount = 0
$skippedCount = 0

foreach ($regFile in $regFiles) {
    $baseName = $regFile.BaseName
    
    Write-Host "   Procesando: $baseName" -ForegroundColor Cyan
    
    # Preguntar confirmación individual (opcional)
    # $importThis = Read-Host "     ¿Importar este archivo? (S/n)"
    # if ($importThis -eq "n" -or $importThis -eq "N") {
    #     Write-Host "     ⊘ Omitido" -ForegroundColor Gray
    #     $skippedCount++
    #     continue
    # }
    
    try {
        # Importar usando reg.exe
        $result = reg import "$($regFile.FullName)" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "     ✅ Importado correctamente" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "     ⚠️  Error en importación: $result" -ForegroundColor Yellow
            $errorCount++
        }
        
    } catch {
        Write-Host "     ❌ Error: $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""

# ===============================================================================
# RESUMEN
# ===============================================================================

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "RESUMEN DE IMPORTACIÓN" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Archivos importados exitosamente: $successCount" -ForegroundColor Green
Write-Host "Archivos con errores: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "Archivos omitidos: $skippedCount" -ForegroundColor Gray
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host "✅ IMPORTACIÓN COMPLETADA" -ForegroundColor Green
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Configuraciones importadas desde: $($selectedBackup.Name)" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  IMPORTANTE: Se recomienda REINICIAR el sistema" -ForegroundColor Yellow
    Write-Host "   para que todos los cambios surtan efecto" -ForegroundColor Gray
    Write-Host ""
    
    # Preguntar si reiniciar
    $restart = Read-Host "¿Deseas reiniciar el sistema ahora? (s/N)"
    
    if ($restart -eq "s" -or $restart -eq "S") {
        Write-Host ""
        Write-Host "Reiniciando en 10 segundos..." -ForegroundColor Yellow
        Write-Host "Presiona Ctrl+C para cancelar" -ForegroundColor Gray
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-Host ""
        Write-Host "Reinicia manualmente cuando estés listo" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "❌ No se pudo importar ninguna configuración" -ForegroundColor Red
}

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
