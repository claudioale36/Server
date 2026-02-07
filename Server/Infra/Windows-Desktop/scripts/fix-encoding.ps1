# fix-encoding.ps1
# Re-save setup-windows.ps1 with UTF-8 BOM encoding

$scriptPath = "D:\Windows-Desktop\scripts\setup-windows.ps1"

Write-Host "Reading file..." -ForegroundColor Cyan
$content = Get-Content $scriptPath -Raw -Encoding UTF8

Write-Host "Saving with UTF-8 BOM..." -ForegroundColor Cyan
$utf8BOM = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($scriptPath, $content, $utf8BOM)

Write-Host "File re-saved with UTF-8 BOM" -ForegroundColor Green
Write-Host ""
Write-Host "Now you can run:" -ForegroundColor Yellow
Write-Host "  D:\Windows-Desktop\scripts\setup-windows.ps1" -ForegroundColor White
