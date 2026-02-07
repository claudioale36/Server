# ==========================
# DEBUG INICIAL
# ==========================
Write-Host ">>> SCRIPT INICIADO"
Write-Host "Usuario: $env:USERNAME"

$esAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "Admin: $esAdmin"
Write-Host ""

# ==========================
# CONFIGURACIÓN
# ==========================
$nuevaDNS = "192.168.1.102"

# ==========================
# OBTENER ADAPTADORES ACTIVOS (FORMA CORRECTA)
# ==========================
$adaptadores = Get-NetAdapter |
    Where-Object { $_.Status -eq "Up" -and -not $_.Virtual }

Write-Host "Adaptadores encontrados: $($adaptadores.Count)"
$adaptadores | Format-Table Name, InterfaceDescription, Status
Write-Host ""

if (-not $adaptadores) {
    Write-Host "❌ No hay adaptadores activos. Abortando." -ForegroundColor Red
    Pause
    exit 1
}

# ==========================
# PROCESAR ADAPTADORES
# ==========================
foreach ($adaptador in $adaptadores) {

    Write-Host "➡ Procesando adaptador: $($adaptador.Name)"

    $ifIndex = $adaptador.ifIndex

    # DNS actuales
    $dnsActuales = (Get-DnsClientServerAddress `
        -InterfaceIndex $ifIndex `
        -AddressFamily IPv4).ServerAddresses

    Write-Host "DNS actuales: $($dnsActuales -join ', ')"

    # Construir nueva lista DNS
    if (-not $dnsActuales) {
        $nuevaListaDNS = @($nuevaDNS)
    }
    else {
        $nuevaListaDNS = @($nuevaDNS) + ($dnsActuales | Where-Object { $_ -ne $nuevaDNS })
    }

    Write-Host "Aplicando DNS: $($nuevaListaDNS -join ', ')"

    # Aplicar DNS
    Set-DnsClientServerAddress `
        -InterfaceIndex $ifIndex `
        -ServerAddresses $nuevaListaDNS

    Start-Sleep -Seconds 2

    # Verificación real
    $dnsVerificacion = (Get-DnsClientServerAddress `
        -InterfaceIndex $ifIndex `
        -AddressFamily IPv4).ServerAddresses

    Write-Host "DNS después del cambio: $($dnsVerificacion -join ', ')"

    if ($dnsVerificacion[0] -eq $nuevaDNS) {
        Write-Host "✅ DNS principal aplicada correctamente" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ La DNS principal NO coincide" -ForegroundColor Yellow
    }

    Write-Host ""
}

Write-Host ">>> SCRIPT TERMINADO"
Pause
