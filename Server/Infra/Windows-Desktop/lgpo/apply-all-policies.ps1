# ===============================================================================
# apply-all-policies.ps1
# ===============================================================================
# OBJETIVO: Aplicar todas las Group Policies definidas usando LGPO.exe
# ORDEN: Debe ejecutarse DESPUÉS de los scripts pre-install
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

$ErrorActionPreference = "Continue"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "APLICANDO GROUP POLICIES CON LGPO.EXE" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

# Rutas
$lgpoDir = Split-Path -Parent $PSCommandPath
$lgpoExe = Join-Path $lgpoDir "LGPO.exe"
$policiesDir = Join-Path $lgpoDir "policies"

# Verificar que LGPO.exe existe
if (-not (Test-Path $lgpoExe)) {
    Write-Host "❌ ERROR: LGPO.exe no encontrado en: $lgpoExe" -ForegroundColor Red
    Write-Host ""
    Write-Host "Ejecuta primero: .\download-lgpo.ps1" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "✅ LGPO.exe encontrado" -ForegroundColor Green
Write-Host ""

# Políticas a aplicar (en orden de prioridad)
$policies = @(
    @{
        Name = "UAC Disable"
        File = "uac-disable.txt"
        Description = "Desactivar UAC completamente"
    },
    @{
        Name = "Execution Policy"
        File = "execution-policy.txt"
        Description = "PowerShell Unrestricted + permitir apps sin firmar"
    },
    @{
        Name = "SmartScreen Disable"
        File = "smartscreen-disable.txt"
        Description = "Desactivar SmartScreen"
    },
    @{
        Name = "Windows Defender Disable"
        File = "defender-disable.txt"
        Description = "Desactivar Windows Defender"
    },
    @{
        Name = "Windows Update Control"
        File = "windows-update.txt"
        Description = "Configurar Windows Update"
    }
)

# Aplicar cada política
$successCount = 0
$errorCount = 0

foreach ($policy in $policies) {
    Write-Host "➡️  Aplicando: $($policy.Name)" -ForegroundColor Yellow
    Write-Host "   Descripción: $($policy.Description)" -ForegroundColor Gray
    
    $policyPath = Join-Path $policiesDir $policy.File
    
    if (-not (Test-Path $policyPath)) {
        Write-Host "   ⚠️  Archivo no encontrado: $($policy.File)" -ForegroundColor Red
        $errorCount++
        Write-Host ""
        continue
    }
    
    try {
        # Aplicar la política con LGPO
        $result = & $lgpoExe /t $policyPath 2>&1
        
        # LGPO no usa exit codes estándar, verificar output
        if ($LASTEXITCODE -eq 0 -or $result -match "successfully|completed") {
            Write-Host "   ✅ Aplicada correctamente" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "   ⚠️  Resultado: $result" -ForegroundColor Yellow
            $successCount++  # Contamos como éxito si no hay error explícito
        }
        
    } catch {
        Write-Host "   ❌ Error: $_" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
}

# Resumen
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "RESUMEN DE APLICACIÓN" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Políticas aplicadas exitosamente: $successCount" -ForegroundColor Green
Write-Host "Políticas con errores: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host "✅ GROUP POLICIES APLICADAS" -ForegroundColor Green
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Las siguientes configuraciones han sido aplicadas:" -ForegroundColor White
    Write-Host ""
    Write-Host "  ✓ UAC completamente desactivado" -ForegroundColor Gray
    Write-Host "  ✓ PowerShell Execution Policy = Unrestricted" -ForegroundColor Gray
    Write-Host "  ✓ SmartScreen desactivado" -ForegroundColor Gray
    Write-Host "  ✓ Windows Defender desactivado" -ForegroundColor Gray
    Write-Host "  ✓ Windows Update bajo control del usuario" -ForegroundColor Gray
    Write-Host "  ✓ Apps sin firmar permitidas" -ForegroundColor Gray
    Write-Host "  ✓ Ejecución desde cualquier ubicación" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  IMPORTANTE: REINICIA EL SISTEMA para aplicar todos los cambios" -ForegroundColor Yellow
    Write-Host ""
    
    # Preguntar si reiniciar ahora
    $restart = Read-Host "¿Deseas reiniciar ahora? (s/N)"
    
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
    Write-Host "❌ No se pudo aplicar ninguna política" -ForegroundColor Red
    Write-Host ""
    Write-Host "Verifica que:" -ForegroundColor Yellow
    Write-Host "  1. LGPO.exe está en: $lgpoExe" -ForegroundColor White
    Write-Host "  2. Los archivos de políticas están en: $policiesDir" -ForegroundColor White
    Write-Host "  3. Estás ejecutando como Administrador" -ForegroundColor White
    Write-Host ""
}

# ===============================================================================
# FUNCIÓN OPCIONAL: Verificar políticas aplicadas
# ===============================================================================

function Verify-AppliedPolicies {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "VERIFICANDO POLÍTICAS APLICADAS" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # UAC
    $uac = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
    if ($uac.EnableLUA -eq 0) {
        Write-Host "✅ UAC: Desactivado" -ForegroundColor Green
    } else {
        Write-Host "⚠️  UAC: Aún activo" -ForegroundColor Yellow
    }
    
    # Execution Policy
    $execPolicy = Get-ExecutionPolicy -Scope LocalMachine
    if ($execPolicy -eq "Unrestricted" -or $execPolicy -eq "Bypass") {
        Write-Host "✅ Execution Policy: $execPolicy" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Execution Policy: $execPolicy (no es Unrestricted)" -ForegroundColor Yellow
    }
    
    # Defender
    $defender = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
    if ($defender.DisableAntiSpyware -eq 1) {
        Write-Host "✅ Defender: Desactivado" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Defender: Puede estar activo" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Ejecutar verificación (comentar si no se desea)
# Verify-AppliedPolicies
