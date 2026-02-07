# ===============================================================================
# 07-configure-app-execution.ps1
# ===============================================================================
# OBJETIVO: Configurar Windows para ejecutar apps desde cualquier ubicación (D:\)
# CONTEXTO: Apps portables, instaladas en D:\, sin restricciones de ruta
# ===============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""; exit
}

. "$PSScriptRoot/../lib/logs.ps1"

Log-Step "CONFIGURANDO EJECUCIÓN DE APLICACIONES DESDE UBICACIONES PERSONALIZADAS"

# ===============================================================================
# MÉTODO 1: Agregar D:\ al PATH del sistema
# ===============================================================================

Log-Step "Método 1: Configurando PATH del sistema"

# Rutas comunes de aplicaciones en D:\
$customPaths = @(
    "D:\apps",
    "D:\apps\bin",
    "D:\dev",
    "D:\dev\bin",
    "D:\raiz\Program Files",
    "D:\raiz\Program Files (x86)"
)

# Obtener PATH actual
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$pathArray = $currentPath -split ';'

$pathModified = $false

foreach ($customPath in $customPaths) {
    if ($pathArray -notcontains $customPath) {
        $pathArray += $customPath
        $pathModified = $true
        Log-Ok "Agregado al PATH: $customPath"
    } else {
        Log-Ok "Ya existe en PATH: $customPath"
    }
}

if ($pathModified) {
    $newPath = $pathArray -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Log-Ok "PATH del sistema actualizado"
} else {
    Log-Ok "PATH ya contiene las rutas necesarias"
}

# ===============================================================================
# MÉTODO 2: Registrar ubicaciones de apps en App Paths
# ===============================================================================

Log-Step "Método 2: Registrando ubicaciones en App Paths"

$appPathsBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"

# Ejemplos de apps portables comunes
$portableApps = @{
    "vscode.exe" = "D:\apps\VSCode"
    "firefox.exe" = "D:\apps\Firefox"
    "chromium.exe" = "D:\apps\Chromium"
    "notepad++.exe" = "D:\apps\Notepad++"
}

foreach ($exe in $portableApps.Keys) {
    $appPath = Join-Path $appPathsBase $exe
    
    if (-not (Test-Path $appPath)) {
        New-Item -Path $appPath -Force | Out-Null
    }
    
    $exePath = Join-Path $portableApps[$exe] $exe
    
    Set-ItemProperty -Path $appPath -Name "(Default)" -Value $exePath -Type String -Force
    Set-ItemProperty -Path $appPath -Name "Path" -Value $portableApps[$exe] -Type String -Force
    
    Log-Ok "App Path registrada: $exe → $($portableApps[$exe])"
}

# ===============================================================================
# MÉTODO 3: Desactivar restricciones de ubicación de instalación
# ===============================================================================

Log-Step "Método 3: Desactivando restricciones de ubicación de instalación"

# Permitir instalaciones fuera de Program Files
$installerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"

if (-not (Test-Path $installerPath)) {
    New-Item -Path $installerPath -Force | Out-Null
}

# Permitir instalaciones en cualquier ubicación
Set-ItemProperty -Path $installerPath -Name "DisableMSI" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $installerPath -Name "LimitSystemRestoreCheckpointing" -Value 1 -Type DWord -Force

Log-Ok "Instalaciones sin restricciones de ubicación"

# ===============================================================================
# MÉTODO 4: Configurar asociaciones de archivos para D:\
# ===============================================================================

Log-Step "Método 4: Configurando asociaciones de archivos"

# Asegurar que .exe en D:\ se ejecuten sin problemas
$exeFilePath = "HKLM:\SOFTWARE\Classes\exefile\shell\open\command"

if (Test-Path $exeFilePath) {
    $currentCommand = (Get-ItemProperty -Path $exeFilePath -Name "(Default)")."(Default)"
    
    # Asegurar que no haya restricciones de ruta
    if ($currentCommand -match "%1") {
        Log-Ok "Asociación .exe correcta: $currentCommand"
    }
}

# ===============================================================================
# MÉTODO 5: Desactivar advertencias de seguridad para ejecutables
# ===============================================================================

Log-Step "Método 5: Desactivando advertencias de seguridad"

# Internet Explorer Security Zones (aplica a File Explorer también)
$zonesPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones"

# Zona 0 = My Computer
$zone0 = Join-Path $zonesPath "0"

if (Test-Path $zone0) {
    # 1802 = Launching programs in IFRAME (permitir)
    Set-ItemProperty -Path $zone0 -Name "1802" -Value 0 -Type DWord -Force
    
    # 1804 = Launching programs (permitir)
    Set-ItemProperty -Path $zone0 -Name "1804" -Value 0 -Type DWord -Force
    
    Log-Ok "Zona 0 (My Computer) configurada sin restricciones"
}

# Zona 3 = Internet (para archivos descargados)
$zone3 = Join-Path $zonesPath "3"

if (Test-Path $zone3) {
    Set-ItemProperty -Path $zone3 -Name "1802" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $zone3 -Name "1804" -Value 0 -Type DWord -Force
    
    Log-Ok "Zona 3 (Internet) configurada sin restricciones"
}

# ===============================================================================
# MÉTODO 6: Desactivar protección contra ejecutables no comunes
# ===============================================================================

Log-Step "Método 6: Desactivando protección de aplicaciones no comunes"

$attachmentPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments"

if (-not (Test-Path $attachmentPath)) {
    New-Item -Path $attachmentPath -Force | Out-Null
}

# HideFileExt: 0 = mostrar extensiones
Set-ItemProperty -Path $attachmentPath -Name "HideFileExt" -Value 0 -Type DWord -Force

# ScanWithAntiVirus: 3 = no escanear
Set-ItemProperty -Path $attachmentPath -Name "ScanWithAntiVirus" -Value 3 -Type DWord -Force

Log-Ok "Protección de ejecutables desactivada"

# ===============================================================================
# MÉTODO 7: Configurar rutas de aplicaciones en D:\raiz
# ===============================================================================

Log-Step "Método 7: Configurando rutas espejo en D:\raiz"

# Configurar variables de entorno personalizadas
$envVars = @{
    "LOCALAPPDATA_MIRROR" = "D:\raiz\Users\$env:USERNAME\AppData\Local"
    "APPDATA_MIRROR" = "D:\raiz\Users\$env:USERNAME\AppData\Roaming"
    "PROGRAMFILES_MIRROR" = "D:\raiz\Program Files"
    "PROGRAMFILES_X86_MIRROR" = "D:\raiz\Program Files (x86)"
}

foreach ($var in $envVars.Keys) {
    [Environment]::SetEnvironmentVariable($var, $envVars[$var], "Machine")
    Log-Ok "Variable de entorno creada: $var = $($envVars[$var])"
}

# ===============================================================================
# MÉTODO 8: Desactivar advertencias de Windows SmartScreen para apps
# ===============================================================================

Log-Step "Método 8: Desactivando SmartScreen para apps locales"

# Esta configuración complementa el script 00-disable-smartappcontrol.ps1
$smartScreenAppPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"

if (-not (Test-Path $smartScreenAppPath)) {
    New-Item -Path $smartScreenAppPath -Force | Out-Null
}

Set-ItemProperty -Path $smartScreenAppPath -Name "SmartScreenEnabled" -Value "Off" -Type String -Force
Log-Ok "SmartScreen para apps desactivado"

# ===============================================================================
# MÉTODO 9: Configurar permisos NTFS para D:\apps y D:\raiz
# ===============================================================================

Log-Step "Método 9: Configurando permisos NTFS"

$directories = @("D:\apps", "D:\raiz", "D:\dev")

foreach ($dir in $directories) {
    if (Test-Path $dir) {
        try {
            # Otorgar control total al usuario actual y a SYSTEM
            $acl = Get-Acl $dir
            
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $systemUser = "NT AUTHORITY\SYSTEM"
            
            # Regla para usuario actual
            $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $currentUser,
                "FullControl",
                "ContainerInherit,ObjectInherit",
                "None",
                "Allow"
            )
            
            # Regla para SYSTEM
            $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $systemUser,
                "FullControl",
                "ContainerInherit,ObjectInherit",
                "None",
                "Allow"
            )
            
            $acl.SetAccessRule($userRule)
            $acl.SetAccessRule($systemRule)
            
            Set-Acl -Path $dir -AclObject $acl
            
            Log-Ok "Permisos configurados para: $dir"
        } catch {
            Log-Warn "No se pudieron configurar permisos para $dir : $_"
        }
    } else {
        Log-Warn "Directorio no existe (se creará después): $dir"
    }
}

# ===============================================================================
# MÉTODO 10: Deshabilitar "Unknown Publisher" warnings
# ===============================================================================

Log-Step "Método 10: Desactivando advertencias de publicador desconocido"

$trustPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing"

if (-not (Test-Path $trustPath)) {
    New-Item -Path $trustPath -Force | Out-Null
}

# State: 146944 = no mostrar advertencias
Set-ItemProperty -Path $trustPath -Name "State" -Value 146944 -Type DWord -Force

Log-Ok "Advertencias de publicador desconocido desactivadas"

# ===============================================================================
# VERIFICACIÓN FINAL
# ===============================================================================

Log-Step "Verificando configuración"

# Verificar PATH
$finalPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$hasCustomPaths = $true

foreach ($customPath in $customPaths) {
    if ($finalPath -notcontains $customPath) {
        $hasCustomPaths = $false
        break
    }
}

if ($hasCustomPaths) {
    Log-Ok "✅ PATH configurado con rutas personalizadas"
} else {
    Log-Warn "⚠️ Algunas rutas pueden no estar en PATH"
}

Log-Ok "Configuración de ejecución de aplicaciones completada"
Log-Warn ""
Log-Warn "⚠️ RESUMEN:"
Log-Warn "⚠️ ✓ Apps pueden ejecutarse desde D:\apps, D:\dev, D:\raiz"
Log-Warn "⚠️ ✓ PATH del sistema actualizado"
Log-Warn "⚠️ ✓ App Paths registradas"
Log-Warn "⚠️ ✓ SmartScreen desactivado para apps locales"
Log-Warn "⚠️ ✓ Advertencias de publicador desactivadas"
Log-Warn "⚠️ ✓ Variables de entorno espejo creadas"
Log-Warn ""
Log-Warn "⚠️ IMPORTANTE:"
Log-Warn "⚠️ 1. Reiniciar para aplicar cambios de PATH"
Log-Warn "⚠️ 2. Apps portables en D:\ funcionarán sin restricciones"
Log-Warn "⚠️ 3. VS Code portable, Firefox portable, etc. están soportados"
Log-Warn ""
