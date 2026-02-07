# fix-all-encoding.ps1
# Fix encoding for all PowerShell scripts in the project

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  FIXING ENCODING FOR ALL POWERSHELL SCRIPTS" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

$scriptPaths = @(
    "D:\Windows-Desktop\scripts\setup-windows.ps1",
    "D:\Windows-Desktop\scripts\pre-install\03-unrestrict-execution.ps1",
    "D:\Windows-Desktop\scripts\install\06-install-apps.ps1",
    "D:\Windows-Desktop\scripts\install\07-configure-app-execution.ps1",
    "D:\Windows-Desktop\lgpo\apply-all-policies.ps1",
    "D:\Windows-Desktop\dsc\apply-dsc.ps1",
    "D:\Windows-Desktop\boxstarter\boxstarter.ps1"
)

$utf8BOM = New-Object System.Text.UTF8Encoding $true
$successCount = 0
$errorCount = 0

foreach ($scriptPath in $scriptPaths) {
    $fileName = Split-Path $scriptPath -Leaf
    Write-Host "Processing: $fileName" -ForegroundColor Yellow
    
    if (Test-Path $scriptPath) {
        try {
            $content = Get-Content $scriptPath -Raw -Encoding UTF8
            [System.IO.File]::WriteAllText($scriptPath, $content, $utf8BOM)
            Write-Host "  [OK] Re-saved with UTF-8 BOM" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host "  [ERROR] $_" -ForegroundColor Red
            $errorCount++
        }
    }
    else {
        Write-Host "  [NOT FOUND] Skipping..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Summary: $successCount files fixed, $errorCount errors" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Yellow" })
Write-Host "==================================================================" -ForegroundColor Cyan
