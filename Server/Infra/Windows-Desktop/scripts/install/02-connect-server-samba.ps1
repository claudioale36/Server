# ================================================
# HABILITAR EJECUCIÓN DE SCRIPTS (ejecutar una vez)
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# ================================================

# --- CONFIGURACIÓN ---
$ServerIP   = "192.168.1.101"
$ShareName = "server"
$SharePath = "\\$ServerIP\$ShareName"
$DriveLetter = "Z:"
$Username = "USUARIO_SAMBA"
$Password = "PASSWORD_SAMBA"

# --- GUARDAR CREDENCIALES ---
cmdkey /add:$ServerIP /user:$Username /pass:$Password

# --- MAPEAR UNIDAD DE RED (persistente) ---
if (-not (Get-PSDrive -Name $DriveLetter.TrimEnd(':') -ErrorAction SilentlyContinue)) {
    New-PSDrive `
        -Name $DriveLetter.TrimEnd(':') `
        -PSProvider FileSystem `
        -Root $SharePath `
        -Persist
}

# --- PIN A ACCESO RÁPIDO (Quick Access) ---
$Shell = New-Object -ComObject Shell.Application
$Folder = $Shell.Namespace($SharePath)

if ($Folder -ne $null) {
    $Folder.Self.InvokeVerb("pintohome")
}

Write-Host "Conexión SMB configurada y pineada correctamente." -ForegroundColor Green
