1- = INFORMACIÓN Y STACK =

1.1- Utilizo Linux como sistema operativo principal (Disco SSD propio formato BTRFS).

1.2- Utilizo Windows 11 como sistema operativo secundario (Disco SSD propio). Este disco Contiene la tipica particion "(C:)", y una partición adicional "(D:)" para archivos y datos de programas que trato de hacer persistentes entre reinstalaciones del Sistema.

1.3- Disco adicional formato ext4 para archivos (utilizado por Linux).



2- = OBJETIVOS E INTENCIÓN =

Crear un sistema reproducible, declarativo e inmutable. Quiero que ante la re-instalación de Windows 11 pueda restaurar la instalación y configuración de mis aplicaciones, datos y configuraciones del usuario del sistema (por ejemplo preferencias de energía).



2.1- Para lograr nuestros objetivos analizaremos apalancarnos en software Open Source como por ejemplo "Boxstarter" para realizar instalaciones automatizadas en el caso de las aplicaciones que causan problemas al forzarlas a la portabilidad.

Sugiere otros softwares Open Source o herramientas que encuentres en Github creadas por otros desarrolladores que faciliten la tarea de crear un Windows reproducible, declarativo y portable.

"Boxstarter" está orientado especificamente a instalaciones, pero no a configuraciones del sistema, usuarios ni claves de registro de Windows; considera buscar herramientas de otros desarrolladores en Github.

Si no existe el software, construiremos nuestros propios scripts de PowerShell o Windows terminal (considerame usuario avanzado).



2.2- Para tareas especificas, la idea es crear un sistema de scripts modularizados que permita realizar las configuraciones, restauraciones, creación de symlinks, etc; de forma automatizada, y que al instalar un nuevo Windows sea totalmente reproducible. Filosofia "Doble Click y Windows limpio, idéntico y listo para trabajar".

Todos los scripts serán ejecutados de forma modularizada por un script principal llamado "setup-windows.ps1" que realizará configuraciones iniciales, y luego llamará al resto de los script, por ejemplo "setup-network.ps1", preparalos para que funcionen correctamente de esta forma con todo lo que haga falta (por ejemplo heredar permisos).



3- = CONDICIONES DE LOS SCRIPTS =

3.1- Asegurate de que todos los scripts ".ps1" tengan en su primera linea su ruta y nombre para fácil identificación. Por ejemplo:

"# D:\\Windows-Desktop\\scripts\\setup-windows.ps1"



(no estoy seguro si es mejor la ruta absoluta completa o parcial "scripts\\setup-windows.ps1". Decidelo tu).



3.2- Asegurate de que todos los scripts sean seguros e idempotentes. Si por algún motivo un script falla y ejecutamos nuevamente "setup-windows.ps1", la segunda ejecución NO DEBE ROMPER NADA.

Agreguemos validaciones y confirmaciones si es necesario.

La estabilidad y seguridad son prioridad.



3.3- Asegurate de que todos los scripts tengan los permisos correctos de ejecución:

a. Añade un comentario en la primera linea con el comando para desbloquearlo (especifico para cada script en particular, incluida su ruta/nombre), si el usuario debe realizarlo de forma manual, solo deberá copiar y pegar.

b. Añade en todos los scripts una linea que convierta PowerShell en Administrador aunque el usuario deba confirmarlo manualmente.



3.4- Asegurate de que los scripts sean compatibles con Windows Terminal, PS 5.1 y PS 5, y no cause problemas de Encoding/Unicode (scripts 100% encoding-safe). Si es necesario agregar detección; si lo consideras viable podemos modularizar un script con una funcion "detect-enviroment.ps1" que sea llamado por todos los scripts.



3.5- Utiliza en todos los scripts los logs ya configurados y modularizados en "D:\\Windows-Desktop\\scripts\\lib\\Logging":

\- Logging.psm1

\- Logging.psd1



\- Estos archivos los podrás encontrar cargados como archivos dentro del contexto con los nombres mencionados.



\- Ejemplo de Integración en cualquier script:

\################

\# IMPORT MODULES

\################

try {

&nbsp;   Import-Module "$PSScriptRoot\\..\\lib\\Logging\\Logging" -ErrorAction Stop

}

catch {

&nbsp;   Write-Error "No se pudo cargar el módulo Logging"

&nbsp;   exit 1

}



$ScriptName = Split-Path $PSCommandPath -Leaf

$LogFile = Join-Path $PSScriptRoot ($ScriptName -replace '\\.ps1$', '.log')



\###############################

\# ENCODING / CONSOLE SAFE LOGGING

\###############################

$UseUnicode = ($Host.Name -match "ConsoleHost|Windows Terminal")



Set-LogConfig `

&nbsp;   -UseUnicode $UseUnicode `

&nbsp;   -ToFile $true `

&nbsp;   -FilePath $LogFile



Log-Step "Configurando..."

Log-Warn "Configurado parcialmente (revisar)"

Log-Error "Error al Configurar..."

Log-Ok "Configuración exitosa"



3.6- Por defecto todos los scripts deben generar logs incrementales de máximo 5mb en su ubicación, y el archivo debe ser nombrado con el mismo nombre del script; a menos que te indique lo contrario. Por ejemplo "\*\*NOMBRE-SCRIPT\*\*.log".



3.7- Siempre que importes funciones de scripts modularizados, hazlo de forma segura, con rutas relativas para no romperse, y considera si el script consumidor necesita informacion adicional (Por ejemplo: "necesito escribir logs", o "solo muestro logs el terminal, no hay problema con logs en archivos de texto").

Ejemplo:

\############################################

\# IMPORTS

\############################################

\# Garantizar que el proceso pueda importar scripts (DEBE ESTAR EN TODOS LOS SCRIPTS)

try {

&nbsp;   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

} catch {

&nbsp;   Write-Warning "No se pudo ajustar ExecutionPolicy del proceso"

}



$LibPath = Join-Path $PSScriptRoot "..\\lib\\logs.ps1"



if (-not (Test-Path $LibPath)) {

&nbsp;   Write-Error "No se encontró lib/logs.ps1 en $LibPath"

&nbsp;   exit 1

}



. $LibPath



$ScriptName = Split-Path $PSCommandPath -Leaf

$LogDir     = $PSScriptRoot

$LogFile    = Join-Path $LogDir ($ScriptName -replace '\\.ps1$', '.log')



$Global:LogUseUnicode = $true

$Global:LogToFile     = $true

$Global:LogFilePath   = $LogFile



4- = REPRODUCIBILIDAD, INMUTABILIDAD Y PERSISTENCIA DEL SISTEMA =

4.1- He ideado el siguiente método:

a- La unidad "(D:)" es casi un "clon" de la unidad "(C:)", replicando la estructura de directorios de Windows. Ejemplo para Firefox:

"D:\\apps\\Users\\USER\\AppData\\Local\\Mozilla".

b- Mis archivos "de verdad" en realidad están en mi unidad "(D:)". Y el directorio "C:\\Users\\Oficina\\AppData\\Local\\Mozilla" es un symlink a la ruta de la unidad "(D:)".

c- En el caso de reinstalar Windows, recreo el enlace simbólico en el nuevo sistema, restaurando automáticamente mis datos (como historial, perfiles del navegador, etc).



5- A pesar de esta estructura propia, muchos programas necesitan claves de registro para funcionar correctamente, que si no están en el nuevo Windows, fallará aunque los archivos persistentes en la unidad "(D:)" estén intactos.

Debemos atender esta cuestión con la importancia que merece para cada caso, y hacer exportaciones/importaciones en cada uno de los trabajos que hagamos.

Aún no tengo softwares en los que pueda apalancarme para realizar esta tarea, puedes sugerirme algunos o bien crearemos nuestro propio software.



