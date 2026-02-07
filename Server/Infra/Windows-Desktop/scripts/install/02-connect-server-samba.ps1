# ================================================
# 02-connect-server-samba.ps1
# ================================================ 
# HABILITAR EJECUCIÓN DE SCRIPTS (ejecutar una vez) 
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser 
# ================================================
# Unblock:
# Unblock-File -Path .\02-connect-server-samba.ps1
# ================================================

############################
# AUTO-ELEVACIÓN (SAFE)
############################
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell `
        -Verb RunAs `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

############################
# CONFIGURACIÓN
############################
$ServerHost  = "server"
$ShareName  = "server\Server"
$SharePath  = "\\$ServerHost\$ShareName"

$ShortcutName = "Server Files"
$IconLocation = "imageres.dll,154"

############################
# RUTAS
############################
$Desktop = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = Join-Path $Desktop "$ShortcutName.lnk"

############################
# CREAR ACCESO DIRECTO (IDEMPOTENTE)
############################
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath   = $SharePath
$Shortcut.IconLocation = $IconLocation
$Shortcut.Description  = "Acceso bajo demanda al servidor de red"

$Shortcut.Save()

Write-Host "Acceso directo creado en el Escritorio." -ForegroundColor Green

############################
# INTENTO DE PIN A TASKBAR (BEST EFFORT)
############################
function Try-PinToTaskbar {
    param ([string]$LinkPath)

    try {
        $Shell  = New-Object -ComObject Shell.Application
        $Folder = $Shell.Namespace((Split-Path $LinkPath))
        $Item   = $Folder.ParseName((Split-Path $LinkPath -Leaf))

        if (-not $Item) { return $false }

        foreach ($verb in $Item.Verbs()) {
            $name = $verb.Name.Replace('&','').Trim()
            if ($name -match "Pin to taskbar|Anclar a la barra de tareas") {
                $verb.DoIt()
                return $true
            }
        }
    }
    catch {}

    return $false
}

if (Try-PinToTaskbar -LinkPath $ShortcutPath) {
    Write-Host "Acceso anclado a la barra de tareas." -ForegroundColor Green
} else {
    Write-Warning "Windows no permite anclar a la barra de tareas por script."
    Write-Warning "👉 Ancla manualmente el acceso directo del Escritorio."
}

############################
# FINAL
############################
Write-Host "La red NO se evalúa hasta hacer click." -ForegroundColor DarkGreen
