. "$PSScriptRoot/../lib/logs.ps1"
Log-Step "Desactivando tareas programadas"

$tasks = @(
 "\Microsoft\Windows\Application Experience\*",
 "\Microsoft\Windows\Customer Experience Improvement Program\*",
 "\Microsoft\Windows\Feedback\*",
 "\Microsoft\Windows\Maps\*"
)

foreach ($t in $tasks) {
  Get-ScheduledTask -TaskPath $t -ErrorAction SilentlyContinue |
    Disable-ScheduledTask
}

Log-Ok "Tareas desactivadas"
