# ===============================================================================
# apps.ps1 - INSTALACIÓN DE APLICACIONES VIA CHOCOLATEY
# ===============================================================================

Write-Host "==> Instalando aplicaciones" -ForegroundColor Cyan
Write-Host ""

# ===============================================================================
# DESARROLLO
# ===============================================================================

Write-Host "➡️  Instalando herramientas de desarrollo..." -ForegroundColor Yellow

# Terminal mejorada
choco install microsoft-windows-terminal -y

# WSL y distribución Ubuntu
choco install wsl2 -y
choco install wsl-ubuntu-2204 -y

# Git y herramientas relacionadas
choco install git -y
choco install git-credential-winstore -y

# Editores y IDEs
choco install vscode -y

# Lenguajes de programación
choco install python -y
#choco install nodejs -y

# Docker
choco install docker-desktop -y

Write-Host "   ✅ Herramientas de desarrollo instaladas" -ForegroundColor Green
Write-Host ""

# ===============================================================================
# NAVEGADORES
# ===============================================================================

Write-Host "➡️  Instalando navegadores..." -ForegroundColor Yellow

# Firefox
choco install firefox -y

# UnGoogled Chromium (puede no estar en repo oficial)
try {
    choco install ungoogled-chromium -y
    Write-Host "   ✅ UnGoogled Chromium instalado" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  UnGoogled Chromium no disponible en Chocolatey" -ForegroundColor Yellow
    Write-Host "   Instalar manualmente desde: D:\Windows-Desktop\boxstarter\repo\" -ForegroundColor Gray
}

Write-Host ""

# ===============================================================================
# PRODUCTIVIDAD
# ===============================================================================

Write-Host "➡️  Instalando apps de productividad..." -ForegroundColor Yellow

# Editores de texto
choco install notepadplusplus -y

# Gestión de conocimiento
try {
    choco install obsidian -y
    Write-Host "   ✅ Obsidian instalado" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Obsidian no disponible en Chocolatey" -ForegroundColor Yellow
    Write-Host "   Instalar manualmente desde: https://obsidian.md/" -ForegroundColor Gray
}

# Gestor de contraseñas
choco install bitwarden -y

# Conectividad móvil
try {
    choco install kdeconnect-kde -y
    Write-Host "   ✅ KDE Connect instalado" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  KDE Connect no disponible en Chocolatey" -ForegroundColor Yellow
    Write-Host "   Instalar manualmente desde: https://kdeconnect.kde.org/" -ForegroundColor Gray
}

Write-Host ""

# ===============================================================================
# FINANZAS E INVERSIONES
# ===============================================================================

Write-Host "➡️  Instalando apps de finanzas..." -ForegroundColor Yellow

# Portfolio Performance
try {
    choco install portfolio-performance -y
    Write-Host "   ✅ Portfolio Performance instalado" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Portfolio Performance no disponible en Chocolatey" -ForegroundColor Yellow
    Write-Host "   Instalar manualmente desde: https://www.portfolio-performance.info/" -ForegroundColor Gray
}

Write-Host ""

# ===============================================================================
# IA Y PRODUCTIVIDAD
# ===============================================================================

Write-Host "➡️  Instalando Claude Desktop..." -ForegroundColor Yellow

try {
    choco install claude-desktop -y
    Write-Host "   ✅ Claude Desktop instalado" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Claude Desktop no disponible en Chocolatey" -ForegroundColor Yellow
    Write-Host "   Instalar manualmente desde: https://claude.ai/download" -ForegroundColor Gray
}

Write-Host ""

# ===============================================================================
# MULTIMEDIA
# ===============================================================================

Write-Host "➡️  Instalando apps multimedia..." -ForegroundColor Yellow

# CapCut
try {
    choco install capcut -y
    Write-Host "   ✅ CapCut instalado" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  CapCut no disponible en Chocolatey" -ForegroundColor Yellow
    Write-Host "   Instalar manualmente desde: https://www.capcut.com/" -ForegroundColor Gray
}

Write-Host ""

# ===============================================================================
# APLICACIONES ESPECIALIZADAS (INSTALADORES LOCALES)
# ===============================================================================

Write-Host "➡️  Verificando instaladores locales..." -ForegroundColor Yellow

$repoPath = Join-Path (Split-Path -Parent $PSScriptRoot) "repo"

if (Test-Path $repoPath) {
    $installers = Get-ChildItem -Path $repoPath -Filter "*.exe" -ErrorAction SilentlyContinue
    
    if ($installers.Count -gt 0) {
        Write-Host "   Instaladores encontrados:" -ForegroundColor Cyan
        
        foreach ($installer in $installers) {
            Write-Host "     • $($installer.Name)" -ForegroundColor Gray
            
            # Preguntar si instalar
            $install = Read-Host "       ¿Instalar? (S/n)"
            
            if ($install -ne "n" -and $install -ne "N") {
                try {
                    Write-Host "       Instalando..." -ForegroundColor Gray
                    Start-Process -FilePath $installer.FullName -Wait -NoNewWindow
                    Write-Host "       ✅ Instalado" -ForegroundColor Green
                } catch {
                    Write-Host "       ❌ Error: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "       ⊘ Omitido" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "   ⚠️  No se encontraron instaladores en: $repoPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  Directorio repo no encontrado: $repoPath" -ForegroundColor Yellow
}

Write-Host ""

# ===============================================================================
# OPEN DATA PLATFORM (OpenBB)
# ===============================================================================

Write-Host "➡️  Instalando Open Data Platform..." -ForegroundColor Yellow

$openbbInstaller = Join-Path $repoPath "Open-Data-Platform_latest_windows_x86_64.exe"

if (Test-Path $openbbInstaller) {
    try {
        Write-Host "   Ejecutando instalador de OpenBB..." -ForegroundColor Gray
        Start-Process -FilePath $openbbInstaller -Wait -NoNewWindow
        Write-Host "   ✅ Open Data Platform instalado" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Error instalando OpenBB: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   ⚠️  Instalador no encontrado en repo" -ForegroundColor Yellow
    Write-Host "   Descarga desde: https://github.com/OpenBB-finance/OpenBB/releases" -ForegroundColor Gray
}

Write-Host ""

# ===============================================================================
# UTILIDADES DEL SISTEMA
# ===============================================================================

Write-Host "➡️  Instalando utilidades del sistema..." -ForegroundColor Yellow

# 7-Zip
choco install 7zip -y

# VLC Media Player
choco install vlc -y

# Acrobat Reader
choco install adobereader -y

Write-Host "   ✅ Utilidades instaladas" -ForegroundColor Green
Write-Host ""

# ===============================================================================
# WINDOWS FEATURES
# ===============================================================================

Write-Host "➡️  Habilitando Windows Features..." -ForegroundColor Yellow

# Esta parte se ejecuta desde windows-features.ps1 pero la menciono aquí
Write-Host "   (Se configuran en windows-features.ps1)" -ForegroundColor Gray

Write-Host ""

# ===============================================================================
# RESUMEN
# ===============================================================================

Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "✅ INSTALACIÓN DE APLICACIONES COMPLETADA" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  IMPORTANTE:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Algunas aplicaciones que no están en Chocolatey deben instalarse manualmente:" -ForegroundColor White
Write-Host ""
Write-Host "  • UnGoogled Chromium: https://ungoogled-software.github.io/ungoogled-chromium-binaries/" -ForegroundColor Gray
Write-Host "  • Antigravity: (si aplica, agrega URL)" -ForegroundColor Gray
Write-Host "  • Open Data Platform: D:\Windows-Desktop\boxstarter\repo\" -ForegroundColor Gray
Write-Host ""
Write-Host "Verifica el directorio D:\Windows-Desktop\boxstarter\repo\ para instaladores locales" -ForegroundColor White
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
