# lib/logs.ps1

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $prefix = switch ($Level) {
        "STEP"  { "➡️ " }
        "OK"    { "✅ " }
        "WARN"  { "⚠️ " }
        "ERROR" { "❌ " }
        default { "• " }
    }

    Write-Host "$prefix$Message"
}

function Log-Step  { Write-Log $args "STEP" }
function Log-Ok    { Write-Log $args "OK" }
function Log-Warn  { Write-Log $args "WARN" }
function Log-Error { Write-Log $args "ERROR" }
