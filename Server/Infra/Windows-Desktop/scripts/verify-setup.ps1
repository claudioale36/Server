# ===============================================================================
# verify-setup.ps1
# ===============================================================================
# OBJETIVO: Verificar que todas las configuraciones están aplicadas correctamente
# USO: Ejecutar DESPUÉS de setup-windows.ps1 y reiniciar
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "VERIFICACIÓN DE CONFIGURACIÓN - FULL DEV ENVIRONMENT" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

# ===============================================================================
# FUNCIÓN DE VERIFICACIÓN
# ===============================================================================

function Test-Configuration {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Expected
    )
    
    Write-Host "  [$Name]" -NoNewline
    
    $result = & $Test
    
    if ($result) {
        Write-Host " ✅ $Expected" -ForegroundColor Green
        return $true
    } else {
        Write-Host " ❌ NO configurado" -ForegroundColor Red
        return $false
    }
}

# ===============================================================================
# VERIFICACIONES DE SEGURIDAD (DESACTIVADAS)
# ===============================================================================

Write-Host "SEGURIDAD (debe estar TODO desactivado):" -ForegroundColor Yellow
Write-Host ""

$securityScore = 0
$securityTotal = 0

# UAC
$securityTotal++
$uac = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA").EnableLUA
if (Test-Configuration "UAC" { $uac -eq 0 } "Desactivado") { $securityScore++ }

# Defender
$securityTotal++
$defender = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue).DisableAntiSpyware
if (Test-Configuration "Defender" { $defender -eq 1 } "Desactivado") { $securityScore++ }

# SmartScreen
$securityTotal++
$smartScreen = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -ErrorAction SilentlyContinue).SmartScreenEnabled
if (Test-Configuration "SmartScreen" { $smartScreen -eq "Off" } "Desactivado") { $securityScore++ }

# Execution Policy
$securityTotal++
$execPolicy = Get-ExecutionPolicy -Scope LocalMachine
if (Test-Configuration "PowerShell" { $execPolicy -eq "Unrestricted" -or $execPolicy -eq "Bypass" } "Unrestricted") { $securityScore++ }

# Tamper Protection
$securityTotal++
$tamper = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -ErrorAction SilentlyContinue).TamperProtection
if (Test-Configuration "Tamper Protection" { $tamper -eq 0 } "Desactivado") { $securityScore++ }

Write-Host ""

# ===============================================================================
# VERIFICACIONES DE SERVICIOS
# ===============================================================================

Write-Host "SERVICIOS:" -ForegroundColor Yellow
Write-Host ""

$servicesScore = 0
$servicesTotal = 0

# Defender Service
$securityTotal++
$defenderSvc = (Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue).Status
if (Test-Configuration "WinDefend Service" { $defenderSvc -eq "Stopped" } "Detenido") { $servicesScore++ }

# Telemetry
$servicesTotal++
$diagTrack = (Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue).Status
if (Test-Configuration "DiagTrack (Telemetry)" { $diagTrack -eq "Stopped" } "Detenido") { $servicesScore++ }

# Bluetooth (debe estar ACTIVO)
$servicesTotal++
$bluetooth = (Get-Service -Name "bthserv" -ErrorAction SilentlyContinue).Status
if (Test-Configuration "Bluetooth" { $bluetooth -eq "Running" } "Activo") { $servicesScore++ }

# Windows Search (debe estar ACTIVO)
$servicesTotal++
$search = (Get-Service -Name "WSearch" -ErrorAction SilentlyContinue).Status
if (Test-Configuration "Windows Search" { $search -eq "Running" } "Activo") { $servicesScore++ }

Write-Host ""

# ===============================================================================
# VERIFICACIONES DE WINDOWS FEATURES
# ===============================================================================

Write-Host "WINDOWS FEATURES:" -ForegroundColor Yellow
Write-Host ""

$featuresScore = 0
$featuresTotal = 0

# WSL
$featuresTotal++
$wsl = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -ErrorAction SilentlyContinue
if (Test-Configuration "WSL" { $wsl.State -eq "Enabled" } "Habilitado") { $featuresScore++ }

# Hyper-V
$featuresTotal++
$hyperv = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All" -ErrorAction SilentlyContinue
if (Test-Configuration "Hyper-V" { $hyperv.State -eq "Enabled" } "Habilitado") { $featuresScore++ }

# Containers
$featuresTotal++
$containers = Get-WindowsOptionalFeature -Online -FeatureName "Containers" -ErrorAction SilentlyContinue
if (Test-Configuration "Containers" { $containers.State -eq "Enabled" } "Habilitado") { $featuresScore++ }

Write-Host ""

# ===============================================================================
# VERIFICACIONES DE CONFIGURACIÓN DEL SISTEMA
# ===============================================================================

Write-Host "CONFIGURACIÓN DEL SISTEMA:" -ForegroundColor Yellow
Write-Host ""

$configScore = 0
$configTotal = 0

# Mostrar extensiones de archivo
$configTotal++
$showExt = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt").HideFileExt
if (Test-Configuration "Mostrar extensiones" { $showExt -eq 0 } "Activado") { $configScore++ }

# Mostrar archivos ocultos
$configTotal++
$showHidden = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden").Hidden
if (Test-Configuration "Mostrar ocultos" { $showHidden -eq 1 } "Activado") { $configScore++ }

# GameBar desactivado
$configTotal++
$gameBar = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -ErrorAction SilentlyContinue).AppCaptureEnabled
if (Test-Configuration "GameBar" { $gameBar -eq 0 } "Desactivado") { $configScore++ }

# Cortana desactivado
$configTotal++
$cortana = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -ErrorAction SilentlyContinue).AllowCortana
if (Test-Configuration "Cortana" { $cortana -eq 0 } "Desactivado") { $configScore++ }

Write-Host ""

# ===============================================================================
# VERIFICACIONES DE SYMLINKS
# ===============================================================================

Write-Host "SYMLINKS (D:\raiz):" -ForegroundColor Yellow
Write-Host ""

$symlinksScore = 0
$symlinksTotal = 0

$USER = $env:USERNAME
$criticalSymlinks = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\AppData\Local\Mozilla"
)

foreach ($link in $criticalSymlinks) {
    $symlinksTotal++
    $name = Split-Path $link -Leaf
    
    if (Test-Path $link) {
        $item = Get-Item $link -Force
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "  [$name]" -NoNewline
            Write-Host " ✅ Symlink creado → $($item.Target)" -ForegroundColor Green
            $symlinksScore++
        } else {
            Write-Host "  [$name]" -NoNewline
            Write-Host " ⚠️  Existe pero NO es symlink" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [$name]" -NoNewline
        Write-Host " ❌ No existe" -ForegroundColor Red
    }
}

Write-Host ""

# ===============================================================================
# VERIFICACIONES DE APLICACIONES
# ===============================================================================

Write-Host "APLICACIONES INSTALADAS:" -ForegroundColor Yellow
Write-Host ""

$appsScore = 0
$appsTotal = 0

$criticalApps = @(
    @{ Name = "Git"; Command = "git" },
    @{ Name = "Node.js"; Command = "node" },
    @{ Name = "Python"; Command = "python" },
    @{ Name = "Docker"; Command = "docker" },
    @{ Name = "Chocolatey"; Command = "choco" }
)

foreach ($app in $criticalApps) {
    $appsTotal++
    
    if (Get-Command $app.Command -ErrorAction SilentlyContinue) {
        Write-Host "  [$($app.Name)]" -NoNewline
        Write-Host " ✅ Instalado" -ForegroundColor Green
        $appsScore++
    } else {
        Write-Host "  [$($app.Name)]" -NoNewline
        Write-Host " ❌ No encontrado" -ForegroundColor Red
    }
}

Write-Host ""

# ===============================================================================
# RESUMEN GENERAL
# ===============================================================================

$totalScore = $securityScore + $servicesScore + $featuresScore + $configScore + $symlinksScore + $appsScore
$totalMax = $securityTotal + $servicesTotal + $featuresTotal + $configTotal + $symlinksTotal + $appsTotal

$percentage = [math]::Round(($totalScore / $totalMax) * 100, 2)

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "RESUMEN GENERAL" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Categoría                 | Puntuación" -ForegroundColor White
Write-Host "--------------------------|------------" -ForegroundColor Gray
Write-Host "Seguridad (desactivada)   | $securityScore / $securityTotal" -ForegroundColor $(if ($securityScore -eq $securityTotal) { "Green" } else { "Yellow" })
Write-Host "Servicios                 | $servicesScore / $servicesTotal" -ForegroundColor $(if ($servicesScore -eq $servicesTotal) { "Green" } else { "Yellow" })
Write-Host "Windows Features          | $featuresScore / $featuresTotal" -ForegroundColor $(if ($featuresScore -eq $featuresTotal) { "Green" } else { "Yellow" })
Write-Host "Configuración Sistema     | $configScore / $configTotal" -ForegroundColor $(if ($configScore -eq $configTotal) { "Green" } else { "Yellow" })
Write-Host "Symlinks                  | $symlinksScore / $symlinksTotal" -ForegroundColor $(if ($symlinksScore -eq $symlinksTotal) { "Green" } else { "Yellow" })
Write-Host "Aplicaciones              | $appsScore / $appsTotal" -ForegroundColor $(if ($appsScore -eq $appsTotal) { "Green" } else { "Yellow" })
Write-Host "--------------------------|------------" -ForegroundColor Gray
Write-Host "TOTAL                     | $totalScore / $totalMax ($percentage%)" -ForegroundColor $(if ($percentage -ge 90) { "Green" } elseif ($percentage -ge 70) { "Yellow" } else { "Red" })
Write-Host ""

# ===============================================================================
# RECOMENDACIONES
# ===============================================================================

if ($percentage -lt 100) {
    Write-Host "===============================================================================" -ForegroundColor Yellow
    Write-Host "RECOMENDACIONES" -ForegroundColor Yellow
    Write-Host "===============================================================================" -ForegroundColor Yellow
    Write-Host ""
    
    if ($securityScore -lt $securityTotal) {
        Write-Host "  ⚠️  Algunas restricciones de seguridad siguen activas" -ForegroundColor Yellow
        Write-Host "     Ejecuta: D:\Windows-Desktop\lgpo\apply-all-policies.ps1" -ForegroundColor White
        Write-Host "     O: D:\Windows-Desktop\scripts\pre-install\*.ps1" -ForegroundColor White
        Write-Host ""
    }
    
    if ($featuresScore -lt $featuresTotal) {
        Write-Host "  ⚠️  Algunas Windows Features no están habilitadas" -ForegroundColor Yellow
        Write-Host "     Ejecuta: D:\Windows-Desktop\dsc\apply-dsc.ps1" -ForegroundColor White
        Write-Host "     Y reinicia el sistema" -ForegroundColor White
        Write-Host ""
    }
    
    if ($symlinksScore -lt $symlinksTotal) {
        Write-Host "  ⚠️  Algunos symlinks no están creados" -ForegroundColor Yellow
        Write-Host "     Ejecuta: D:\Windows-Desktop\scripts\install\04-create-symlinks.ps1" -ForegroundColor White
        Write-Host ""
    }
    
    if ($appsScore -lt $appsTotal) {
        Write-Host "  ⚠️  Algunas aplicaciones críticas no están instaladas" -ForegroundColor Yellow
        Write-Host "     Ejecuta: D:\Windows-Desktop\boxstarter\boxstarter.ps1" -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "  💡 Para aplicar todo de nuevo:" -ForegroundColor Cyan
    Write-Host "     D:\Windows-Desktop\scripts\setup-windows.ps1" -ForegroundColor White
    Write-Host ""
    
} else {
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host "✅ CONFIGURACIÓN PERFECTA - TODO ESTÁ CORRECTAMENTE CONFIGURADO" -ForegroundColor Green
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Tu sistema está completamente configurado como entorno FULL DEV" -ForegroundColor White
    Write-Host ""
}

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
