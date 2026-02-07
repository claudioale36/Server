# ===============================================================================
# boxstarter.ps1 - INSTALACIÓN DE APLICACIONES
# ===============================================================================
# OBJETIVO: Instalar todas las aplicaciones necesarias usando Boxstarter/Chocolatey
# CONTEXTO: Se ejecuta desde setup-windows.ps1 o manualmente
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "BOXSTARTER - INSTALACIÓN DE APLICACIONES" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

# ===============================================================================
# RUTAS
# ===============================================================================

$Path = $PSScriptRoot
$RepoPath = Join-Path $Path "repo"

# ===============================================================================
# INSTALAR CHOCOLATEY (SI NO ESTÁ INSTALADO)
# ===============================================================================

Write-Host "➡️  Verificando Chocolatey..." -ForegroundColor Yellow

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "   Chocolatey no está instalado. Instalando..." -ForegroundColor Gray
    
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        Write-Host "   ✅ Chocolatey instalado" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Error instalando Chocolatey: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "   Instala Chocolatey manualmente desde: https://chocolatey.org/install" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "   ✅ Chocolatey ya está instalado" -ForegroundColor Green
}

Write-Host ""

# ===============================================================================
# INSTALAR BOXSTARTER (SI NO ESTÁ INSTALADO)
# ===============================================================================

Write-Host "➡️  Verificando Boxstarter..." -ForegroundColor Yellow

if (-not (Get-Command Install-BoxstarterPackage -ErrorAction SilentlyContinue)) {
    Write-Host "   Boxstarter no está instalado. Instalando..." -ForegroundColor Gray
    
    try {
        choco install boxstarter -y
        
        # Recargar entorno
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Host "   ✅ Boxstarter instalado" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Error instalando Boxstarter: $_" -ForegroundColor Yellow
        Write-Host "   Continuando sin Boxstarter..." -ForegroundColor Gray
    }
} else {
    Write-Host "   ✅ Boxstarter ya está instalado" -ForegroundColor Green
}

Write-Host ""

# ===============================================================================
# IMPORTAR MÓDULO BOXSTARTER
# ===============================================================================

try {
    Import-Module Boxstarter.Chocolatey -ErrorAction SilentlyContinue
} catch {
    Write-Host "⚠️  No se pudo importar Boxstarter.Chocolatey" -ForegroundColor Yellow
    Write-Host "   Continuando con Chocolatey estándar..." -ForegroundColor Gray
}

# ===============================================================================
# CONFIGURAR BOXSTARTER
# ===============================================================================

if (Get-Command Set-BoxstarterConfig -ErrorAction SilentlyContinue) {
    # Configurar repositorio local para apps personalizadas
    Set-BoxstarterConfig -LocalRepo $RepoPath

    # Boxstarter settings
    $Boxstarter.RebootOk = $true
    $Boxstarter.NoPassword = $false
    $Boxstarter.AutoLogin = $true
    
    Write-Host "✅ Boxstarter configurado" -ForegroundColor Green
    Write-Host ""
}

# ===============================================================================
# DESHABILITAR UAC TEMPORALMENTE
# ===============================================================================

Write-Host "➡️  Deshabilitando UAC temporalmente para instalaciones..." -ForegroundColor Yellow

if (Get-Command Disable-UAC -ErrorAction SilentlyContinue) {
    Disable-UAC
    Write-Host "   ✅ UAC deshabilitado temporalmente" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Comando Disable-UAC no disponible" -ForegroundColor Yellow
}

Write-Host ""

# ===============================================================================
# EJECUTAR MÓDULOS DE CONFIGURACIÓN
# ===============================================================================

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "EJECUTANDO MÓDULOS DE CONFIGURACIÓN" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

$configModules = @(
    "system.ps1",
    "windows-features.ps1",
    "power.ps1",
    "apps.ps1"
)

foreach ($module in $configModules) {
    $modulePath = Join-Path "$PSScriptRoot\config" $module
    
    if (Test-Path $modulePath) {
        Write-Host "➡️  Ejecutando: $module" -ForegroundColor Yellow
        
        try {
            . $modulePath
            Write-Host "   ✅ $module completado" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ Error en $module : $_" -ForegroundColor Red
            Write-Host "   Continuando..." -ForegroundColor Gray
        }
        
        Write-Host ""
    } else {
        Write-Host "⚠️  No se encontró: $module" -ForegroundColor Yellow
        Write-Host ""
    }
}

# ===============================================================================
# RE-HABILITAR UAC (opcional, ya que lo desactivamos permanentemente antes)
# ===============================================================================

# Como queremos UAC permanentemente desactivado, NO lo re-habilitamos
# Si en algún momento quisieras re-habilitarlo temporalmente:
# if (Get-Command Enable-UAC -ErrorAction SilentlyContinue) {
#     Enable-UAC
# }

# ===============================================================================
# RESUMEN
# ===============================================================================

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "✅ BOXSTARTER COMPLETADO" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Aplicaciones instaladas:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Navegadores:" -ForegroundColor Cyan
Write-Host "    • Firefox" -ForegroundColor Gray
Write-Host "    • UnGoogled Chromium" -ForegroundColor Gray
Write-Host ""
Write-Host "  Desarrollo:" -ForegroundColor Cyan
Write-Host "    • Git + Git Credential Manager" -ForegroundColor Gray
Write-Host "    • VS Code" -ForegroundColor Gray
Write-Host "    • Node.js" -ForegroundColor Gray
Write-Host "    • Python" -ForegroundColor Gray
Write-Host "    • Docker Desktop" -ForegroundColor Gray
Write-Host ""
Write-Host "  Productividad:" -ForegroundColor Cyan
Write-Host "    • Notepad++" -ForegroundColor Gray
Write-Host "    • Obsidian" -ForegroundColor Gray
Write-Host "    • Bitwarden" -ForegroundColor Gray
Write-Host "    • KDE Connect" -ForegroundColor Gray
Write-Host "    • Claude Desktop" -ForegroundColor Gray
Write-Host ""
Write-Host "  Finanzas:" -ForegroundColor Cyan
Write-Host "    • Portfolio Performance" -ForegroundColor Gray
Write-Host "    • Open Data Platform (OpenBB)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Multimedia:" -ForegroundColor Cyan
Write-Host "    • CapCut" -ForegroundColor Gray
Write-Host ""
Write-Host "  Sistema:" -ForegroundColor Cyan
Write-Host "    • WSL2" -ForegroundColor Gray
Write-Host "    • Hyper-V" -ForegroundColor Gray
Write-Host "    • Containers" -ForegroundColor Gray
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  IMPORTANTE:" -ForegroundColor Yellow
Write-Host "   Algunas aplicaciones pueden requerir reinicio para funcionar correctamente" -ForegroundColor White
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
