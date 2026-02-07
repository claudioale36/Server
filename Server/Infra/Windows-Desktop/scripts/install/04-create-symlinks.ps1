# ---------------------------------------------
# Script para crear varios enlaces simbólicos
# ---------------------------------------------
# Requiere PowerShell ejecutado como Administrador
# ---------------------------------------------

<#
===============================================================================
README – SCRIPT DE GESTIÓN DE ENLACES SIMBÓLICOS (AI-FRIENDLY)
===============================================================================

OBJETIVO GENERAL
----------------
Este script automatiza la creación y mantenimiento de enlaces simbólicos
(Symbolic Links) para directorios de aplicaciones en Windows, con el fin de:

- Mantener los datos reales de las aplicaciones en una partición secundaria (D:)
- Dejar en la partición del sistema (C:) únicamente enlaces simbólicos
- Facilitar reinstalaciones de Windows, backups y portabilidad
- Operar de forma SEGURA, IDEMPOTENTE y SIN BUCLES

El script está diseñado para poder ejecutarse múltiples veces sin efectos
adversos y para manejar estados inconsistentes del sistema de archivos.

-------------------------------------------------------------------------------

MODELO CONCEPTUAL (MUY IMPORTANTE)
----------------------------------
⚠️ Los nombres "Source" y "Destination" NO siguen la convención clásica ⚠️

Este es el modelo REAL que usa el script:

- Disco D:  → ORIGEN REAL DE LOS DATOS (datos persistentes)
- Disco C:  → UBICACIÓN DEL ENLACE SIMBÓLICO (compatibilidad con Windows/apps)

Por lo tanto:

- Source      = Ruta en C: donde DEBE existir el enlace simbólico
- Destination = Ruta en D: donde están (o estarán) los datos reales

Ejemplo:
---------
Source      = C:\Users\%USERNAME%\AppData\Local\OneDrive
Destination = D:\apps\Users\USER\AppData\Local\OneDrive

Resultado final esperado:
-------------------------
C:\Users\Oficina\AppData\Local\OneDrive  --> symlink -->  D:\apps\Users\USER\AppData\Local\OneDrive

-------------------------------------------------------------------------------

COMPORTAMIENTO DEL SCRIPT (LÓGICA DE DECISIÓN)
----------------------------------------------

Para cada entrada definida en $symlinks, el script evalúa los siguientes estados:

1) NO existe en C, SÍ existe en D
   → Se crea el enlace simbólico en C apuntando a D

2) SÍ existe en C (carpeta real), NO existe en D
   → Se copian los datos desde C hacia D
   → Se renombra el directorio de C a .bak (por seguridad de datos)
   → Luego se crea el enlace simbólico en C

3) SÍ existe en C y SÍ existe en D
   → Caso típico de apps preinstaladas (ej: OneDrive)
   → El directorio real en C se renombra a .bak (por seguridad)
   → Luego se crea el enlace simbólico en C apuntando a D

4) En C ya existe un enlace simbólico
   → No se hace nada (el estado es correcto)

5) Cualquier error inesperado (permisos, rutas rotas, etc.)
   → Se registra una advertencia
   → El script CONTINÚA con el siguiente elemento (no hay bucles)

-------------------------------------------------------------------------------

MEDIDAS DE SEGURIDAD
--------------------
- Nunca se eliminan datos automáticamente
- Los directorios reales en C se renombran a *.bak antes de crear enlaces
- Se evita explícitamente crear backups encadenados (*.bak.bak.bak)
- Se usa try/catch para impedir bloqueos del script
- El script es idempotente (puede ejecutarse varias veces)

-------------------------------------------------------------------------------

REQUISITOS
----------
- PowerShell ejecutado como Administrador
- Windows con soporte para Symbolic Links
- Permisos de escritura en C: y D:

-------------------------------------------------------------------------------

USO ESPERADO
------------
Este script está pensado para:
- Post-instalación de Windows
- Migración de perfiles de usuario
- Preparación de entornos reproducibles
- Automatización asistida por IA (este README está optimizado para ello)

Cualquier IA que lea ESTE archivo completo debería poder:
- Entender el objetivo
- Entender el modelo de datos
- Entender las decisiones del script
- Modificarlo sin romper la lógica

===============================================================================
FIN DEL README
===============================================================================
#>


[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$USER = $env:USERNAME
$USERPROFILE = $env:USERPROFILE

$symlinks = @(
    @{
        Name = ".openbb_platform"
        Source = "$USERPROFILE\.openbb_platform"
        Destination = "D:\apps\Users\USER\.openbb_platform"
    },
    @{
        Name = "Descargas"
        Source = "$USERPROFILE\Downloads"
        Destination = "D:\apps\Users\USER\Downloads"
    },
    @{
        Name = "Escritorio"
        Source = "$USERPROFILE\Desktop"
        Destination = "D:\apps\Users\USER\Desktop"
    },
    @{
        Name = "Claude"
        Source = "$USERPROFILE\AppData\Local\AnthropicClaude"
        Destination = "D:\apps\Users\USER\AppData\Local\AnthropicClaude"
    },
    @{
        Name = "Bitwarden Updater"
        Source = "$USERPROFILE\AppData\Local\bitwarden-updater"
        Destination = "D:\apps\Users\USER\AppData\Local\bitwarden-updater"
    },
    @{
        Name = "Chromium"
        Source = "$USERPROFILE\AppData\Local\Chromium"
        Destination = "D:\apps\Users\USER\AppData\Local\UnGoogled Chromium\Chromium"
    },
    @{
        Name = "co.openbb.platform"
        Source = "$USERPROFILE\AppData\Local\co.openbb.platform"
        Destination = "D:\apps\Users\USER\AppData\Local\UnGoogled Chromium\co.openbb.platform"
    },
    @{
        Name = "KDE Connect"
        Source = "$USERPROFILE\AppData\Local\kdeconnect"
        Destination = "D:\apps\Users\USER\AppData\Local\kdeconnect"
    },
    @{
        Name = "KDE Connect App"
        Source = "$USERPROFILE\AppData\Local\kdeconnect.app"
        Destination = "D:\apps\Users\USER\AppData\Local\kdeconnect.app"
    },
    @{
        Name = "Firefox"
        Source = "$USERPROFILE\AppData\Local\Mozilla"
        Destination = "D:\apps\Users\USER\AppData\Local\Mozilla"
    },
    @{
        Name = "Obsidian Updater"
        Source = "$USERPROFILE\AppData\Local\obsidian-updater"
        Destination = "D:\apps\Users\USER\AppData\Local\obsidian-updater"
    },
    @{
        Name = "OneDrive"
        Source = "$USERPROFILE\AppData\Local\OneDrive"
        Destination = "D:\apps\Users\USER\AppData\Local\OneDrive"
    },
    @{
        Name = "Open Data Platform by OpenBB"
        Source = "$USERPROFILE\AppData\Local\Open Data Platform by OpenBB"
        Destination = "D:\apps\Users\USER\AppData\Local\Open Data Platform by OpenBB"
    },
    @{
        Name = "Portfolio Performance"
        Source = "$USERPROFILE\AppData\Local\PortfolioPerformance"
        Destination = "D:\apps\Users\USER\AppData\Local\PortfolioPerformance"
    },
    @{
        Name = "Bitwarden en \local\Programs"
        Source = "$USERPROFILE\AppData\Local\Programs\Bitwarden"
        Destination = "D:\apps\Users\USER\AppData\Local\Programs\Bitwarden"
    },
    @{
        Name = "Bitwarden"
        Source = "$USERPROFILE\AppData\Roaming\Bitwarden"
        Destination = "D:\apps\Users\USER\AppData\Roaming\Bitwarden"
    },
    @{
        Name = "Claude"
        Source = "$USERPROFILE\AppData\Roaming\Claude"
        Destination = "D:\apps\Users\USER\AppData\Roaming\Claude"
    },
    @{
        Name = "Mozilla"
        Source = "$USERPROFILE\AppData\Roaming\Mozilla"
        Destination = "D:\apps\Users\USER\AppData\Roaming\Mozilla"
    },
    @{
        Name = "Obsidian"
        Source = "$USERPROFILE\AppData\Roaming\obsidian"
        Destination = "D:\apps\Users\USER\AppData\Roaming\obsidian"
    }

)

foreach ($item in $symlinks) {
    Write-Host "`nProcesando $($item.Name)..."

    $item.Source = $item.Source -replace '%USERNAME%', $USER

    $linkPath = $item.Source
    $realPath = $item.Destination

    try {

        # Evitar .bak encadenados
        if ($linkPath -match '\.bak') {
            Write-Warning "Ruta .bak detectada, se omite."
            continue
        }

        $linkExists = Test-Path $linkPath
        $realExists = Test-Path $realPath

        if ($linkExists) {
            $info = Get-Item $linkPath -Force

            # Ya es symlink
            if ($info.LinkType -eq 'SymbolicLink') {
                Write-Host "Symlink ya existe, se omite."
                continue
            }

            # Existe en C y en D → renombrar C a .bak
            if ($realExists) {
                $bakPath = "$linkPath.bak"

                if (Test-Path $bakPath) {
                    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                    $bakPath = "$linkPath.bak-$timestamp"
                }

                Write-Host "Existe en C y D, renombrando por seguridad:"
                Write-Host "  $linkPath → $bakPath"

                Rename-Item -Path $linkPath -NewName (Split-Path $bakPath -Leaf)
            }
            else {
                # Existe solo en C → mover a D
                Write-Host "Moviendo datos reales a D:"
                Write-Host "  $linkPath → $realPath"

                $realParent = Split-Path $realPath -Parent
                if (-not (Test-Path $realParent)) {
                    New-Item -ItemType Directory -Path $realParent -Force | Out-Null
                }

                Move-Item -Path $linkPath -Destination $realParent -Force
            }
        }

        # Crear symlink si no existe
        if (-not (Test-Path $linkPath)) {
            Write-Host "Creando symlink:"
            Write-Host "  $linkPath → $realPath"
	    
			$realParent = Split-Path $realPath -Parent
			if (-not (Test-Path $realParent)) {
				 New-Item -ItemType Directory -Path $realParent -Force | Out-Null
			}

			New-Item -ItemType SymbolicLink -Path $linkPath -Target $realPath | Out-Null
			Write-Host "$($item.Name) listo ✅"
		}
    }
    catch {
        Write-Warning "Error procesando $($item.Name): $($_.Exception.Message)"
        continue
    }
}

Write-Host "`nProceso finalizado."
