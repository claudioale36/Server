# "D:\Windows-Desktop\scripts\lib\Logging\Logging.psm1"

<#
===============================================================================
README – MÓDULO DE LOGGING REUTILIZABLE (Logging)
===============================================================================

OBJETIVO GENERAL
----------------
Este módulo provee un sistema de logging liviano, consistente y reutilizable
para scripts de automatización en PowerShell, con foco en:

- Legibilidad humana (con o sin Unicode / emojis)
- Logging estructurado y semántico (STEP, OK, WARN, ERROR)
- Posibilidad de salida a consola y/o archivo
- Uso seguro en scripts post-instalación de Windows
- Arquitectura modular y mantenible

El módulo está diseñado para ser SIMPLE, EXPLÍCITO y SIN EFECTOS COLATERALES.

-------------------------------------------------------------------------------

ESTRUCTURA DEL MÓDULO
--------------------
El módulo está compuesto por:

- Logging.psm1  → Implementación del logging
- Logging.psd1  → Manifiesto del módulo (metadatos, versión, exports)

El archivo `.psd1` permite:
- Importar el módulo por nombre (sin ruta al .psm1)
- Definir versión y compatibilidad
- Declarar explícitamente las funciones exportadas
- Facilitar mantenimiento, evolución y tooling

-------------------------------------------------------------------------------

FILOSOFÍA DE DISEÑO
------------------
- NO usa variables globales
- El estado interno del módulo es privado (scope: script:)
- La configuración es explícita mediante Set-LogConfig
- El módulo NO escribe archivos si no se le indica
- El módulo NO asume Unicode por defecto del host
- El módulo NO lanza excepciones propias

El script consumidor decide:
- Si usar Unicode
- Si loguear a archivo
- Dónde guardar los logs

-------------------------------------------------------------------------------

IMPORTACIÓN CORRECTA DEL MÓDULO
-------------------------------
Siempre se debe importar el módulo usando su carpeta raíz
(no el archivo .psm1 directamente):

    Import-Module "...\lib\Logging\Logging"

Esto hace que PowerShell:
1) Lea Logging.psd1
2) Cargue Logging.psm1 como RootModule
3) Exporte solo las funciones declaradas

RECOMENDADO: usar fail-fast

    try {
        Import-Module "$PSScriptRoot\..\lib\Logging\Logging" -ErrorAction Stop
    }
    catch {
        Write-Error "No se pudo cargar el módulo Logging"
        exit 1
    }

-------------------------------------------------------------------------------

INICIALIZACIÓN OBLIGATORIA
--------------------------
Antes de usar cualquier función Log-*, el módulo DEBE ser inicializado
explícitamente mediante Set-LogConfig.

Ejemplo típico por script:

    $ScriptName = Split-Path $PSCommandPath -Leaf
    $LogFile = Join-Path $PSScriptRoot ($ScriptName -replace '\.ps1$', '.log')

    $UseUnicode = ($Host.Name -match "ConsoleHost|Windows Terminal")

    Set-LogConfig `
        -UseUnicode $UseUnicode `
        -ToFile $true `
        -FilePath $LogFile

Si NO se llama a Set-LogConfig:
- Se usará Unicode por defecto
- NO se escribirá ningún archivo de log

-------------------------------------------------------------------------------

FUNCIONES EXPORTADAS
--------------------

Set-LogConfig
-------------
Configura el comportamiento del módulo.

Parámetros:
- UseUnicode [bool] → Habilita/deshabilita símbolos Unicode
- ToFile     [bool] → Activa escritura a archivo
- FilePath   [string] → Ruta del archivo de log

---

Log-Step
--------
Marca un paso lógico del script.

Ejemplo:
    Log-Step "Configurando radio Bluetooth"

---

Log-Ok
------
Indica una operación exitosa.

Ejemplo:
    Log-Ok "Bluetooth configurado correctamente"

---

Log-Warn
--------
Advertencia no fatal.

Ejemplo:
    Log-Warn "El dispositivo no respondió, se continúa"

---

Log-Error
---------
Error lógico del script (NO lanza excepción).

Ejemplo:
    Log-Error "No se pudo aplicar la configuración"

---

Write-Log
---------
Función base de logging. Uso interno o avanzado.

-------------------------------------------------------------------------------

EJEMPLO DE USO COMPLETO
-----------------------

    try {
        Import-Module "$PSScriptRoot\..\lib\Logging\Logging" -ErrorAction Stop
    }
    catch {
        Write-Error "No se pudo cargar el módulo Logging"
        exit 1
    }

    $LogFile = Join-Path $PSScriptRoot "mi-script.log"

    Set-LogConfig -UseUnicode $true -ToFile $true -FilePath $LogFile

    Log-Step "Iniciando script"
    Log-Ok "Todo listo"

-------------------------------------------------------------------------------

CASOS DE USO ESPERADOS
---------------------
- Scripts post-instalación de Windows
- Automatización personal
- Scripts de restauración de entorno
- Herramientas internas reutilizables
- Proyectos asistidos por IA

Este README está optimizado para:
- Lectura humana
- Mantenimiento a largo plazo
- Comprensión por IAs
- Evolución sin romper scripts existentes

===============================================================================
FIN DEL README
===============================================================================
#>

# Estado interno del módulo (NO global)
$script:LogUseUnicode = $true
$script:LogToFile     = $false
$script:LogFilePath   = $null

function Set-LogConfig {
    param(
        [bool]$UseUnicode = $true,
        [bool]$ToFile = $false,
        [string]$FilePath = $null
    )

    $script:LogUseUnicode = $UseUnicode
    $script:LogToFile     = $ToFile
    $script:LogFilePath   = $FilePath
}

function Get-LogPrefix {
    param([string]$Level)

    if ($script:LogUseUnicode) {
        switch ($Level) {
            "STEP"  { "➡️ " }
            "OK"    { "✅ " }
            "WARN"  { "⚠️ " }
            "ERROR" { "❌ " }
            default { "• " }
        }
    } else {
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

    Write-Output $line

    if ($script:LogToFile -and $script:LogFilePath) {
        Add-Content -Path $script:LogFilePath -Value $line -Encoding UTF8
    }
}

function Log-Step  { Write-Log ($args -join " ") "STEP" }
function Log-Ok    { Write-Log ($args -join " ") "OK" }
function Log-Warn  { Write-Log ($args -join " ") "WARN" }
function Log-Error { Write-Log ($args -join " ") "ERROR" }

Export-ModuleMember -Function `
    Set-LogConfig, `
    Log-Step, Log-Ok, Log-Warn, Log-Error, Write-Log
