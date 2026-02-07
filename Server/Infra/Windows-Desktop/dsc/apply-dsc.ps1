# ===============================================================================
# apply-dsc.ps1
# ===============================================================================
# OBJETIVO: Aplicar la configuración DSC (Desired State Configuration)
# ORDEN: Ejecutar DESPUÉS de scripts pre-install y LGPO
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

$ErrorActionPreference = "Continue"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "APLICANDO DSC (DESIRED STATE CONFIGURATION)" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

# Rutas
$dscDir = Split-Path -Parent $PSCommandPath
$configScript = Join-Path $dscDir "WindowsConfig.ps1"
$mofDir = Join-Path $dscDir "MOF"

# ===============================================================================
# PASO 1: Generar configuración MOF
# ===============================================================================

Write-Host "➡️  Paso 1: Generando configuración MOF..." -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $configScript)) {
    Write-Host "❌ ERROR: No se encontró WindowsConfig.ps1" -ForegroundColor Red
    exit 1
}

try {
    # Ejecutar el script de configuración para generar MOF
    & $configScript
    
    Write-Host "✅ Configuración MOF generada" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "❌ Error generando configuración: $_" -ForegroundColor Red
    exit 1
}

# ===============================================================================
# PASO 2: Verificar que existe el archivo MOF
# ===============================================================================

Write-Host "➡️  Paso 2: Verificando archivos MOF..." -ForegroundColor Yellow
Write-Host ""

$mofFile = Join-Path $mofDir "localhost.mof"

if (-not (Test-Path $mofFile)) {
    Write-Host "❌ ERROR: No se generó el archivo MOF en: $mofFile" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo MOF encontrado: $mofFile" -ForegroundColor Green
Write-Host ""

# ===============================================================================
# PASO 3: Aplicar la configuración DSC
# ===============================================================================

Write-Host "➡️  Paso 3: Aplicando configuración DSC..." -ForegroundColor Yellow
Write-Host ""
Write-Host "   Esto puede tardar varios minutos..." -ForegroundColor Gray
Write-Host ""

try {
    # Detener configuración existente si hay alguna
    Stop-DscConfiguration -Force -ErrorAction SilentlyContinue
    
    # Aplicar la nueva configuración
    Start-DscConfiguration -Path $mofDir -Wait -Verbose -Force
    
    Write-Host ""
    Write-Host "✅ Configuración DSC aplicada correctamente" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "⚠️  Advertencia durante la aplicación: $_" -ForegroundColor Yellow
    Write-Host "   Algunas configuraciones pueden requerir reinicio" -ForegroundColor Gray
    Write-Host ""
}

# ===============================================================================
# PASO 4: Verificar estado de la configuración
# ===============================================================================

Write-Host "➡️  Paso 4: Verificando estado de la configuración..." -ForegroundColor Yellow
Write-Host ""

try {
    $dscStatus = Get-DscConfigurationStatus -ErrorAction SilentlyContinue
    
    if ($null -ne $dscStatus) {
        Write-Host "   Estado: $($dscStatus.Status)" -ForegroundColor Cyan
        Write-Host "   Tipo: $($dscStatus.Type)" -ForegroundColor Cyan
        Write-Host "   Modo: $($dscStatus.Mode)" -ForegroundColor Cyan
        
        if ($dscStatus.Status -eq "Success") {
            Write-Host ""
            Write-Host "✅ Configuración verificada exitosamente" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "⚠️  Estado: $($dscStatus.Status)" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Host "   ⚠️  No se pudo verificar el estado" -ForegroundColor Yellow
}

Write-Host ""

# ===============================================================================
# PASO 5: Configurar DSC para mantenimiento continuo (opcional)
# ===============================================================================

Write-Host "➡️  Paso 5: Configurando modo de mantenimiento..." -ForegroundColor Yellow
Write-Host ""

$enableContinuous = Read-Host "¿Deseas habilitar monitoreo continuo de DSC? (s/N)"

if ($enableContinuous -eq "s" -or $enableContinuous -eq "S") {
    try {
        # Configurar Local Configuration Manager para aplicar configuración automáticamente
        [DSCLocalConfigurationManager()]
        Configuration LCMConfig {
            Node localhost {
                Settings {
                    RefreshMode = 'Push'
                    RefreshFrequencyMins = 30
                    ConfigurationMode = 'ApplyAndAutoCorrect'
                    RebootNodeIfNeeded = $false
                }
            }
        }
        
        # Generar meta MOF
        LCMConfig -OutputPath "$dscDir\LCM"
        
        # Aplicar configuración LCM
        Set-DscLocalConfigurationManager -Path "$dscDir\LCM" -Verbose
        
        Write-Host "✅ Monitoreo continuo habilitado" -ForegroundColor Green
        Write-Host "   DSC verificará y corregirá la configuración cada 30 minutos" -ForegroundColor Gray
        Write-Host ""
        
    } catch {
        Write-Host "⚠️  No se pudo configurar monitoreo continuo: $_" -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "ℹ️  Modo de una sola aplicación (no se monitoreará continuamente)" -ForegroundColor Cyan
    Write-Host ""
}

# ===============================================================================
# RESUMEN
# ===============================================================================

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "RESUMEN DE CONFIGURACIÓN DSC" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuraciones aplicadas:" -ForegroundColor White
Write-Host ""
Write-Host "  Windows Features:" -ForegroundColor Yellow
Write-Host "    ✓ WSL2 habilitado" -ForegroundColor Gray
Write-Host "    ✓ Hyper-V habilitado" -ForegroundColor Gray
Write-Host "    ✓ Containers habilitado" -ForegroundColor Gray
Write-Host "    ✓ SMBv1 deshabilitado" -ForegroundColor Gray
Write-Host ""
Write-Host "  Servicios Críticos:" -ForegroundColor Yellow
Write-Host "    ✓ Defender desactivado" -ForegroundColor Gray
Write-Host "    ✓ Telemetría desactivada" -ForegroundColor Gray
Write-Host "    ✓ Bluetooth habilitado" -ForegroundColor Gray
Write-Host "    ✓ Windows Search optimizado" -ForegroundColor Gray
Write-Host "    ✓ Servicios innecesarios desactivados" -ForegroundColor Gray
Write-Host ""
Write-Host "  Configuraciones del Sistema:" -ForegroundColor Yellow
Write-Host "    ✓ Hibernación desactivada" -ForegroundColor Gray
Write-Host "    ✓ Extensiones de archivo visibles" -ForegroundColor Gray
Write-Host "    ✓ Archivos ocultos visibles" -ForegroundColor Gray
Write-Host "    ✓ GameBar desactivado" -ForegroundColor Gray
Write-Host "    ✓ Cortana desactivado" -ForegroundColor Gray
Write-Host ""
Write-Host "  Variables de Entorno:" -ForegroundColor Yellow
Write-Host "    ✓ DEV_ENVIRONMENT creada" -ForegroundColor Gray
Write-Host "    ✓ APPS_PATH_MIRROR creada" -ForegroundColor Gray
Write-Host ""

# ===============================================================================
# COMANDOS ÚTILES
# ===============================================================================

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "COMANDOS ÚTILES DSC" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ver estado actual:" -ForegroundColor Yellow
Write-Host "  Get-DscConfigurationStatus" -ForegroundColor White
Write-Host ""
Write-Host "Ver configuración aplicada:" -ForegroundColor Yellow
Write-Host "  Get-DscConfiguration" -ForegroundColor White
Write-Host ""
Write-Host "Forzar nueva aplicación:" -ForegroundColor Yellow
Write-Host "  Start-DscConfiguration -Path $mofDir -Wait -Verbose -Force" -ForegroundColor White
Write-Host ""
Write-Host "Verificar recursos:" -ForegroundColor Yellow
Write-Host "  Test-DscConfiguration -Path $mofDir -Verbose" -ForegroundColor White
Write-Host ""

# ===============================================================================
# ADVERTENCIA FINAL
# ===============================================================================

Write-Host "===============================================================================" -ForegroundColor Yellow
Write-Host "⚠️  IMPORTANTE" -ForegroundColor Yellow
Write-Host "===============================================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Algunas configuraciones requieren REINICIO del sistema:" -ForegroundColor White
Write-Host "  • Windows Features (WSL2, Hyper-V, Containers)" -ForegroundColor Gray
Write-Host "  • Cambios en servicios del sistema" -ForegroundColor Gray
Write-Host "  • Variables de entorno" -ForegroundColor Gray
Write-Host ""

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
    Write-Host ""
}
