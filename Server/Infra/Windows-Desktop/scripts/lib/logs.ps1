# lib/logs.ps1

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$Global:LogUseUnicode = $true
$Global:LogToFile = $false
$Global:LogFilePath = $null

function Get-LogPrefix {
    param([string]$Level)

    if ($LogUseUnicode) {
        switch ($Level) {
            "STEP"  { "➡️ " }
            "OK"    { "✅ " }
            "WARN"  { "⚠️ " }
            "ERROR" { "❌ " }
            default { "• " }
        }
    }
    else {
        switch ($Level) {
            "STEP"  { ">> " }
            "OK"    { "[OK] " }
            "WARN"  { "[WARN] " }
            "ERROR" { "[ERROR] " }
            default { "[INFO] " }
        }
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = Get-LogPrefix $Level

    $line = "$timestamp $prefix$Message"

    # Consola (redirigible)
    Write-Output $line

    # Archivo opcional
    if ($LogToFile -and $LogFilePath) {
        Add-Content -Path $LogFilePath -Value $line -Encoding UTF8
    }
}

function Log-Step  { Write-Log ($args -join " ") "STEP" }
function Log-Ok    { Write-Log ($args -join " ") "OK" }
function Log-Warn  { Write-Log ($args -join " ") "WARN" }
function Log-Error { Write-Log ($args -join " ") "ERROR" }
