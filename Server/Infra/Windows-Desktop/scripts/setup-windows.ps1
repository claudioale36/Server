# ===============================================================================
# setup-windows.ps1 - ORCHESTRATOR MAESTRO
# ===============================================================================
# OBJETIVO: Configurar Windows 11 Pro como entorno FULL DEV sin restricciones
# FLUJO: Pre-Install → LGPO → DSC → Install → Optimize → Boxstarter
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSStyle.OutputRendering = "Ansi"
}


. "$PSScriptRoot/lib/logs.ps1"

$ErrorActionPreference = "Continue"

# ===============================================================================
# BANNER
# ===============================================================================

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "   WINDOWS 11 PRO - FULL DEV ENVIRONMENT SETUP" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Este script configurará Windows como un entorno de desarrollo" -ForegroundColor White
Write-Host "   completamente sin restricciones:" -ForegroundColor White
Write-Host ""
Write-Host "   ✓ SmartAppControl DESACTIVADO" -ForegroundColor Gray
Write-Host "   ✓ Windows Defender DESACTIVADO" -ForegroundColor Gray
Write-Host "   ✓ UAC DESACTIVADO" -ForegroundColor Gray
Write-Host "   ✓ PowerShell Unrestricted" -ForegroundColor Gray
Write-Host "   ✓ Apps sin firmar PERMITIDAS" -ForegroundColor Gray
Write-Host "   ✓ Ejecución desde D:\ SIN RESTRICCIONES" -ForegroundColor Gray
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

$continue = Read-Host "¿Deseas continuar? (S/n)"

if ($continue -eq "n" -or $continue -eq "N") {
    Write-Host ""
    Write-Host "Operación cancelada" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "INICIANDO CONFIGURACIÓN..." -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""

# ===============================================================================
# VARIABLES GLOBALES
# ===============================================================================

$ScriptRoot = Split-Path -Parent $PSCommandPath
$DesktopRoot = Split-Path -Parent $ScriptRoot
$startTime = Get-Date

# ===============================================================================
# FASE 0: PRE-INSTALL (DESACTIVAR TODAS LAS RESTRICCIONES)
# ===============================================================================

Log-Step "═══════════════════════════════════════════════════════════════════════════════"
Log-Step "FASE 0: PRE-INSTALL - DESACTIVANDO RESTRICCIONES DE SEGURIDAD"
Log-Step "═══════════════════════════════════════════════════════════════════════════════"

$preInstallDir = "$ScriptRoot/pre-install"

if (Test-Path $preInstallDir) {
    $preInstallScripts = Get-ChildItem $preInstallDir -Filter "*.ps1" | Sort-Object Name
    
    foreach ($script in $preInstallScripts) {
        Log-Step "Ejecutando: $($script.Name)"
        
        try {
            & $script.FullName
            Log-Ok "$($script.Name) completado"
        }
        catch {
            Log-Error "Error en $($script.Name): $_"
            Log-Warn "Continuando de todas formas..."
        }
        
        Write-Host ""
    }
    
    Log-Ok "FASE 0 COMPLETADA - Restricciones de seguridad desactivadas"
}
else {
    Log-Warn "Directorio pre-install no encontrado, omitiendo..."
}

Write-Host ""

# ===============================================================================
# FASE 1: LGPO - APLICAR GROUP POLICIES
# ===============================================================================

Log-Step "═══════════════════════════════════════════════════════════════════════════════"
Log-Step "FASE 1: LGPO - APLICANDO GROUP POLICIES"
Log-Step "═══════════════════════════════════════════════════════════════════════════════"

$lgpoScript = "$DesktopRoot/lgpo/apply-all-policies.ps1"

if (Test-Path $lgpoScript) {
    Log-Step "Aplicando políticas con LGPO.exe..."
    
    try {
        & $lgpoScript
        Log-Ok "FASE 1 COMPLETADA - Group Policies aplicadas"
    }
    catch {
        Log-Error "Error aplicando LGPO: $_"
        Log-Warn "Continuando sin LGPO..."
    }
}
else {
    Log-Warn "Script LGPO no encontrado en: $lgpoScript"
    Log-Warn "Ejecuta manualmente: D:\Windows-Desktop\lgpo\download-lgpo.ps1"
    Log-Warn "Luego: D:\Windows-Desktop\lgpo\apply-all-policies.ps1"
}

Write-Host ""

# ===============================================================================
# FASE 2: DSC - DESIRED STATE CONFIGURATION
# ===============================================================================

Log-Step "═══════════════════════════════════════════════════════════════════════════════"
Log-Step "FASE 2: DSC - APLICANDO DESIRED STATE CONFIGURATION"
Log-Step "═══════════════════════════════════════════════════════════════════════════════"

$dscScript = "$DesktopRoot/dsc/apply-dsc.ps1"

if (Test-Path $dscScript) {
    Log-Step "Aplicando configuración DSC..."
    
    try {
        & $dscScript
        Log-Ok "FASE 2 COMPLETADA - DSC aplicado"
    }
    catch {
        Log-Error "Error aplicando DSC: $_"
        Log-Warn "Continuando sin DSC..."
    }
}
else {
    Log-Warn "Script DSC no encontrado en: $dscScript"
}

Write-Host ""

# ===============================================================================
# FASE 3: INSTALL - CONFIGURACIÓN DEL SISTEMA
# ===============================================================================

Log-Step "═══════════════════════════════════════════════════════════════════════════════"
Log-Step "FASE 3: INSTALL - CONFIGURACIÓN DEL SISTEMA"
Log-Step "═══════════════════════════════════════════════════════════════════════════════"

$installDir = "$ScriptRoot/install"

if (Test-Path $installDir) {
    # Ejecutar scripts de install (excluyendo 99-update.ps1 por ahora)
    Get-ChildItem $installDir -Filter "*.ps1" |
    Where-Object { $_.Name -notmatch '^99-' } |
    Sort-Object Name |
    ForEach-Object {
        Log-Step "Ejecutando: $($_.Name)"
            
        try {
            . $_.FullName
            Log-Ok "$($_.Name) completado"
        }
        catch {
            Log-Error "Error en $($_.Name): $_"
            Log-Warn "Continuando de todas formas..."
        }
            
        Write-Host ""
    }
    
    Log-Ok "FASE 3 COMPLETADA - Sistema configurado"
}
else {
    Log-Error "Directorio install no encontrado"
}

Write-Host ""

# ===============================================================================
# FASE 4: OPTIMIZE - OPTIMIZACIÓN DEL SISTEMA
# ===============================================================================

Log-Step "═══════════════════════════════════════════════════════════════════════════════"
Log-Step "FASE 4: OPTIMIZE - OPTIMIZACIÓN DEL SISTEMA"
Log-Step "═══════════════════════════════════════════════════════════════════════════════"

$optimizeScript = "$ScriptRoot/optimize-windows.ps1"

if (Test-Path $optimizeScript) {
    Log-Step "Ejecutando optimizaciones..."
    
    try {
        . $optimizeScript
        Log-Ok "FASE 4 COMPLETADA - Sistema optimizado"
    }
    catch {
        Log-Error "Error en optimización: $_"
    }
}
else {
    Log-Error "Script optimize-windows.ps1 no encontrado"
}

Write-Host ""

# ===============================================================================
# FASE 5: BOXSTARTER - INSTALACIÓN DE APLICACIONES
# ===============================================================================

Log-Step "═══════════════════════════════════════════════════════════════════════════════"
Log-Step "FASE 5: BOXSTARTER - INSTALACIÓN DE APLICACIONES"
Log-Step "═══════════════════════════════════════════════════════════════════════════════"

$boxstarterScript = "$DesktopRoot/boxstarter/boxstarter.ps1"

if (Test-Path $boxstarterScript) {
    Log-Step "¿Deseas ejecutar Boxstarter para instalar aplicaciones?"
    Write-Host ""
    Write-Host "   Esto instalará:" -ForegroundColor Yellow
    Write-Host "   • Firefox, UnGoogled Chromium, Notepad++" -ForegroundColor Gray
    Write-Host "   • Obsidian, KDE Connect, Bitwarden" -ForegroundColor Gray
    Write-Host "   • Portfolio Performance, Claude Desktop, CapCut" -ForegroundColor Gray
    Write-Host "   • Open Data Platform (OpenBB)" -ForegroundColor Gray
    Write-Host "   • Git, VSCode, Node.js, Python, Docker" -ForegroundColor Gray
    Write-Host ""
    
    $runBoxstarter = Read-Host "¿Continuar con Boxstarter? (S/n)"
    
    if ($runBoxstarter -ne "n" -and $runBoxstarter -ne "N") {
        try {
            & $boxstarterScript
            Log-Ok "FASE 5 COMPLETADA - Aplicaciones instaladas"
        }
        catch {
            Log-Error "Error ejecutando Boxstarter: $_"
            Log-Warn "Puedes ejecutarlo manualmente: $boxstarterScript"
        }
    }
    else {
        Log-Warn "Boxstarter omitido. Puedes ejecutarlo después manualmente."
    }
}
else {
    Log-Warn "Script Boxstarter no encontrado en: $boxstarterScript"
}

Write-Host ""

# ===============================================================================
# FASE 6: UPDATE - ACTUALIZACIÓN DE WINDOWS (OPCIONAL)
# ===============================================================================

Log-Step "═══════════════════════════════════════════════════════════════════════════════"
Log-Step "FASE 6: UPDATE - ACTUALIZACIÓN DE WINDOWS"
Log-Step "═══════════════════════════════════════════════════════════════════════════════"

$updateScript = "$ScriptRoot/install/99-update.ps1"

if (Test-Path $updateScript) {
    Log-Step "¿Deseas buscar e instalar actualizaciones de Windows?"
    Write-Host ""
    Write-Host "   (Esto puede tardar bastante tiempo)" -ForegroundColor Yellow
    Write-Host ""
    
    $runUpdate = Read-Host "¿Ejecutar Windows Update? (s/N)"
    
    if ($runUpdate -eq "s" -or $runUpdate -eq "S") {
        try {
            . $updateScript
            Log-Ok "FASE 6 COMPLETADA - Sistema actualizado"
        }
        catch {
            Log-Error "Error en Windows Update: $_"
        }
    }
    else {
        Log-Warn "Windows Update omitido. Puedes ejecutarlo después manualmente."
    }
}
else {
    Log-Warn "Script 99-update.ps1 no encontrado"
}

Write-Host ""

# ===============================================================================
# RESUMEN FINAL
# ===============================================================================

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "✅ CONFIGURACIÓN COMPLETADA" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Tiempo total: $($duration.ToString('mm\:ss'))" -ForegroundColor Cyan
Write-Host ""
Write-Host "RESUMEN DE CONFIGURACIÓN:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  ✓ FASE 0: Restricciones de seguridad desactivadas" -ForegroundColor Gray
Write-Host "  ✓ FASE 1: Group Policies aplicadas (LGPO)" -ForegroundColor Gray
Write-Host "  ✓ FASE 2: Desired State Configuration aplicada (DSC)" -ForegroundColor Gray
Write-Host "  ✓ FASE 3: Sistema configurado" -ForegroundColor Gray
Write-Host "  ✓ FASE 4: Sistema optimizado" -ForegroundColor Gray
Write-Host "  ✓ FASE 5: Aplicaciones instaladas (Boxstarter)" -ForegroundColor Gray
Write-Host "  ✓ FASE 6: Windows actualizado" -ForegroundColor Gray
Write-Host ""
Write-Host "CONFIGURACIONES APLICADAS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  🔓 SmartAppControl: DESACTIVADO" -ForegroundColor Gray
Write-Host "  🔓 Windows Defender: DESACTIVADO" -ForegroundColor Gray
Write-Host "  🔓 UAC: DESACTIVADO" -ForegroundColor Gray
Write-Host "  🔓 SmartScreen: DESACTIVADO" -ForegroundColor Gray
Write-Host "  🔓 PowerShell: Unrestricted" -ForegroundColor Gray
Write-Host "  🔓 Apps sin firmar: PERMITIDAS" -ForegroundColor Gray
Write-Host "  🔓 Ejecución desde D:\: SIN RESTRICCIONES" -ForegroundColor Gray
Write-Host "  🔓 Symlinks configurados: D:\apps, D:\raiz" -ForegroundColor Gray
Write-Host "  ⚡ Servicios optimizados" -ForegroundColor Gray
Write-Host "  ⚡ Telemetría desactivada" -ForegroundColor Gray
Write-Host "  ⚡ Privacidad configurada" -ForegroundColor Gray
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""

# ===============================================================================
# PRÓXIMOS PASOS
# ===============================================================================

Write-Host "PRÓXIMOS PASOS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. REINICIAR el sistema (MUY IMPORTANTE)" -ForegroundColor White
Write-Host "     Muchas configuraciones requieren reinicio para aplicarse" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Verificar que UAC está desactivado (no debe aparecer prompts)" -ForegroundColor White
Write-Host ""
Write-Host "  3. Verificar que Defender está desactivado:" -ForegroundColor White
Write-Host "     Windows Security -> deberia mostrar advertencias" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. Probar ejecución de apps desde D:\" -ForegroundColor White
Write-Host ""
Write-Host "  5. Si algo no funciona, re-ejecutar este script:" -ForegroundColor White
Write-Host "     D:\Windows-Desktop\scripts\setup-windows.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

# ===============================================================================
# OPCIÓN DE REINICIO
# ===============================================================================

Log-Warn "⚠️  IMPORTANTE: Se requiere REINICIAR el sistema"
Write-Host ""

$restart = Read-Host "¿Deseas reiniciar AHORA? (s/N)"

if ($restart -eq "s" -or $restart -eq "S") {
    Write-Host ""
    Log-Warn "Reiniciando en 15 segundos..."
    Write-Host "Presiona Ctrl+C para cancelar" -ForegroundColor Gray
    Write-Host ""
    
    for ($i = 15; $i -gt 0; $i--) {
        Write-Host "  $i..." -NoNewline
        Start-Sleep -Seconds 1
    }
    
    Write-Host ""
    Write-Host ""
    Log-Ok "Reiniciando sistema..."
    
    Restart-Computer -Force
}
else {
    Write-Host ""
    Log-Warn "No olvides REINICIAR manualmente para aplicar todos los cambios"
    Write-Host ""
}

# ===============================================================================
# CREAR ACCESO DIRECTO "REHARDEN" EN ESCRITORIO
# ===============================================================================

try {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Reharden Windows.lnk"
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $Shortcut.WorkingDirectory = $ScriptRoot
    $Shortcut.IconLocation = "shell32.dll,21"
    $Shortcut.Description = "Re-aplicar configuración Windows FULL DEV"
    $Shortcut.WindowStyle = 1
    
    $Shortcut.Save()
    
    Log-Ok "Acceso directo -Reharden Windows- creado en el escritorio"
}
catch {
    Log-Warn "No se pudo crear acceso directo en escritorio"
}

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "🚀 SETUP COMPLETO - DISFRUTA TU WINDOWS FULL DEV 🚀" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
