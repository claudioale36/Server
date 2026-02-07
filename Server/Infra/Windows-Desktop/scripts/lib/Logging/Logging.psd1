# "D:\Windows-Desktop\scripts\lib\Logging\Logging.psd1"

@{
    RootModule        = 'Logging.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b9b2c9a1-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    Author            = 'Claudio'
    CompanyName       = 'Personal'
    Description       = 'Módulo de logging liviano y reutilizable para scripts propios'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Set-LogConfig',
        'Log-Step',
        'Log-Ok',
        'Log-Warn',
        'Log-Error',
        'Write-Log'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
