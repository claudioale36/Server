# ===============================================================================
# helper.ps1 - UTILIDADES Y COMANDOS RÁPIDOS
# ===============================================================================
# OBJETIVO: Proveer comandos rápidos para tareas comunes del sistema
# USO: Ejecutar directamente o importar funciones
# ===============================================================================

# ===============================================================================
# MENÚ PRINCIPAL
# ===============================================================================

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "   WINDOWS FULL DEV - HELPER MENU" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Ejecutar Setup Completo" -ForegroundColor White
    Write-Host "  2. Verificar Configuración" -ForegroundColor White
    Write-Host "  3. Aplicar LGPO (Group Policies)" -ForegroundColor White
    Write-Host "  4. Aplicar DSC (State Configuration)" -ForegroundColor White
    Write-Host "  5. Ejecutar Boxstarter (Apps)" -ForegroundColor White
    Write-Host "  6. Desactivar Solo Defender" -ForegroundColor White
    Write-Host "  7. Desactivar Solo UAC" -ForegroundColor White
    Write-Host "  8. Exportar Configuración (Backup)" -ForegroundColor White
    Write-Host "  9. Importar Configuración (Restore)" -ForegroundColor White
    Write-Host " 10. Ver Estado de Servicios" -ForegroundColor White
    Write-Host " 11. Ver Execution Policy" -ForegroundColor White
    Write-Host " 12. Ver Symlinks" -ForegroundColor White
    Write-Host " 13. Crear Punto de Restauración" -ForegroundColor White
    Write-Host " 14. Reiniciar Sistema" -ForegroundColor White
    Write-Host "  0. Salir" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ===============================================================================
# FUNCIONES
# ===============================================================================

function Run-FullSetup {
    Write-Host "➡️  Ejecutando Setup Completo..." -ForegroundColor Yellow
    & "D:\Windows-Desktop\scripts\setup-windows.ps1"
}

function Verify-Configuration {
    Write-Host "➡️  Verificando Configuración..." -ForegroundColor Yellow
    & "D:\Windows-Desktop\scripts\verify-setup.ps1"
}

function Apply-LGPO {
    Write-Host "➡️  Aplicando LGPO..." -ForegroundColor Yellow
    & "D:\Windows-Desktop\lgpo\apply-all-policies.ps1"
}

function Apply-DSC {
    Write-Host "➡️  Aplicando DSC..." -ForegroundColor Yellow
    & "D:\Windows-Desktop\dsc\apply-dsc.ps1"
}

function Run-Boxstarter {
    Write-Host "➡️  Ejecutando Boxstarter..." -ForegroundColor Yellow
    & "D:\Windows-Desktop\boxstarter\boxstarter.ps1"
}

function Disable-DefenderOnly {
    Write-Host "➡️  Desactivando Windows Defender..." -ForegroundColor Yellow
    & "D:\Windows-Desktop\scripts\pre-install\01-disable-defender.ps1"
}

function Disable-UACOnly {
    Write-Host "➡️  Desactivando UAC..." -ForegroundColor Yellow
    & "D:\Windows-Desktop\scripts\pre-install\02-disable-uac.ps1"
}

function Export-Configuration {
    Write-Host "➡️  Exportando Configuración..." -ForegroundColor Yellow
    & "D:\Windows-Desktop\boxstarter\registry\export-all.ps1"
}

function Import-Configuration {
    Write-Host "➡️  Importando Configuración..." -ForegroundColor Yellow
    & "D:\Windows-Desktop\boxstarter\registry\import-all.ps1"
}

function Show-ServicesStatus {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "ESTADO DE SERVICIOS CRÍTICOS" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $services = @(
        "WinDefend",
        "WdNisSvc",
        "SecurityHealthService",
        "DiagTrack",
        "dmwappushservice",
        "bthserv",
        "WSearch",
        "Spooler"
    )
    
    foreach ($svc in $services) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        
        if ($null -eq $service) {
            Write-Host "  [$svc]" -NoNewline
            Write-Host " ⚠️  No encontrado" -ForegroundColor Yellow
        } else {
            $status = $service.Status
            $startup = $service.StartType
            
            Write-Host "  [$svc]" -NoNewline
            
            if ($status -eq "Running") {
                Write-Host " ✅ Running" -NoNewline -ForegroundColor Green
            } else {
                Write-Host " ⭕ $status" -NoNewline -ForegroundColor Gray
            }
            
            Write-Host " | $startup" -ForegroundColor Cyan
        }
    }
    
    Write-Host ""
    Pause
}

function Show-ExecutionPolicy {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "EXECUTION POLICY" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Get-ExecutionPolicy -List | Format-Table -AutoSize
    
    Write-Host ""
    Pause
}

function Show-Symlinks {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "SYMLINKS CONFIGURADOS" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $USER = $env:USERNAME
    
    $paths = @(
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\AppData\Local\Mozilla",
        "$env:USERPROFILE\AppData\Local\Chromium",
        "$env:USERPROFILE\AppData\Local\AnthropicClaude",
        "$env:USERPROFILE\AppData\Roaming\Bitwarden",
        "$env:USERPROFILE\AppData\Roaming\obsidian"
    )
    
    foreach ($path in $paths) {
        $name = Split-Path $path -Leaf
        
        if (Test-Path $path) {
            $item = Get-Item $path -Force
            
            if ($item.LinkType -eq "SymbolicLink") {
                Write-Host "  [$name]" -NoNewline
                Write-Host " ✅ → $($item.Target)" -ForegroundColor Green
            } else {
                Write-Host "  [$name]" -NoNewline
                Write-Host " ⚠️  NO es symlink" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [$name]" -NoNewline
            Write-Host " ❌ No existe" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Pause
}

function Create-RestorePoint {
    Write-Host ""
    Write-Host "➡️  Creando Punto de Restauración..." -ForegroundColor Yellow
    
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Backup Manual - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS"
        
        Write-Host "✅ Punto de restauración creado" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Pause
}

function Restart-System {
    Write-Host ""
    Write-Host "⚠️  El sistema se reiniciará en 10 segundos..." -ForegroundColor Yellow
    Write-Host "Presiona Ctrl+C para cancelar" -ForegroundColor Gray
    
    Start-Sleep -Seconds 10
    Restart-Computer -Force
}

# ===============================================================================
# LOOP PRINCIPAL
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

do {
    Show-Menu
    $choice = Read-Host "Selecciona una opción"
    
    switch ($choice) {
        "1"  { Run-FullSetup }
        "2"  { Verify-Configuration }
        "3"  { Apply-LGPO }
        "4"  { Apply-DSC }
        "5"  { Run-Boxstarter }
        "6"  { Disable-DefenderOnly }
        "7"  { Disable-UACOnly }
        "8"  { Export-Configuration }
        "9"  { Import-Configuration }
        "10" { Show-ServicesStatus }
        "11" { Show-ExecutionPolicy }
        "12" { Show-Symlinks }
        "13" { Create-RestorePoint }
        "14" { Restart-System }
        "0"  { 
            Write-Host ""
            Write-Host "¡Hasta luego! 👋" -ForegroundColor Green
            Write-Host ""
            exit 
        }
        default {
            Write-Host ""
            Write-Host "❌ Opción inválida" -ForegroundColor Red
            Write-Host ""
            Start-Sleep -Seconds 2
        }
    }
    
} while ($true)
