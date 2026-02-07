# 🚀 Quick Start Guide - Windows 11 Full Dev Environment

## ⚡ Instalación en 3 Pasos

### 1️⃣ Preparación (Una sola vez)

**IMPORTANTE**: Si vas a instalar Windows desde cero:

- ❌ **NO actives SmartAppControl** durante la instalación (OOBE)
- ✅ Usa **Windows 11 Pro** (no Home si es posible)
- ✅ Crea una cuenta local (no obligatorio usar Microsoft Account)

### 2️⃣ Ejecutar Setup

Abre PowerShell como **Administrador** y ejecuta:

```powershell
D:\Windows-Desktop\scripts\setup-windows.ps1
```

**Duración**: 10-30 minutos (dependiendo de tu conexión a internet)

### 3️⃣ Reiniciar

Cuando el script termine, **REINICIA** el sistema.

---

## ✅ Verificación

Después de reiniciar, verifica que todo está OK:

```powershell
D:\Windows-Desktop\scripts\verify-setup.ps1
```

Deberías ver **100%** de configuración completada.

---

## 🎯 Lo que hace el script

### Fase 0: Pre-Install (Desactivar Seguridad)
- ✅ SmartAppControl OFF
- ✅ Windows Defender OFF
- ✅ UAC OFF
- ✅ PowerShell Unrestricted

### Fase 1: LGPO (Group Policies)
- Aplicar políticas persistentes usando LGPO.exe

### Fase 2: DSC (Configuración del Sistema)
- Windows Features (WSL2, Hyper-V)
- Servicios críticos
- Variables de entorno

### Fase 3: Install (Configuración)
- Crear symlinks D:\raiz
- Configurar DNS, Samba
- Optimizar Bluetooth
- Permitir apps desde D:\

### Fase 4: Optimize (Optimización)
- Privacy, Telemetry
- Servicios innecesarios
- Apps integradas de Windows

### Fase 5: Boxstarter (Aplicaciones)
- Git, VS Code, Node.js, Python, Docker
- Firefox, UnGoogled Chromium
- Obsidian, Bitwarden, KDE Connect
- Portfolio Performance, OpenBB
- Y más...

---

## 🔧 Si algo falla

### UAC sigue apareciendo
```powershell
D:\Windows-Desktop\scripts\pre-install\02-disable-uac.ps1
# Luego REINICIA (2 veces si es necesario)
```

### Defender sigue activo

1. Abre **Windows Security**
2. Desactiva **Tamper Protection** manualmente
3. Ejecuta:
```powershell
D:\Windows-Desktop\scripts\pre-install\01-disable-defender.ps1
D:\Windows-Desktop\lgpo\apply-all-policies.ps1
```

### Apps no se instalaron

```powershell
D:\Windows-Desktop\boxstarter\boxstarter.ps1
```

### Re-aplicar TODO

```powershell
D:\Windows-Desktop\scripts\setup-windows.ps1
```

---

## 📦 Instaladores Locales

Algunas apps no están en Chocolatey. Coloca sus instaladores en:

```
D:\Windows-Desktop\boxstarter\repo\
```

Por ejemplo:
- `Open-Data-Platform_latest_windows_x86_64.exe`
- `ungoogled-chromium_installer.exe`
- Cualquier otro `.exe`

El script te preguntará si quieres instalarlos.

---

## 🎨 Personalización Rápida

### Agregar una app a Chocolatey

Edita: `D:\Windows-Desktop\boxstarter\config\apps.ps1`

```powershell
# Al final del archivo
choco install nombre-del-paquete -y
```

### Agregar un symlink

Edita: `D:\Windows-Desktop\scripts\install\04-create-symlinks.ps1`

```powershell
@{
    Name = "Mi App"
    Source = "C:\Users\$env:USERNAME\AppData\Local\MiApp"
    Destination = "D:\raiz\Users\USER\AppData\Local\MiApp"
}
```

---

## 🆘 Comandos Útiles

### Ver estado de servicios
```powershell
Get-Service | Where-Object { $_.Name -match "Defender|DiagTrack" }
```

### Ver Execution Policy
```powershell
Get-ExecutionPolicy -List
```

### Ver Windows Features
```powershell
Get-WindowsOptionalFeature -Online | Where-Object { $_.State -eq "Enabled" }
```

### Crear punto de restauración manual
```powershell
Checkpoint-Computer -Description "Antes de cambios" -RestorePointType "MODIFY_SETTINGS"
```

---

## 📋 Checklist Post-Instalación

- [ ] Sistema reiniciado al menos 1 vez
- [ ] UAC no aparece (sin prompts)
- [ ] Windows Security muestra advertencias rojas
- [ ] PowerShell Execution Policy = Unrestricted
- [ ] Apps instaladas: `git --version`, `node --version`, `docker --version`
- [ ] Symlinks creados en Desktop y Downloads
- [ ] VS Code funciona correctamente
- [ ] Docker Desktop arranca sin errores

---

## 🎓 Próximos Pasos

1. **Configura Git**:
   ```powershell
   git config --global user.name "Tu Nombre"
   git config --global user.email "tu@email.com"
   ```

2. **Instala WSL2 distro**:
   ```powershell
   wsl --install -d Ubuntu-22.04
   ```

3. **Verifica Docker**:
   ```powershell
   docker run hello-world
   ```

4. **Abre VS Code** y instala extensiones favoritas

5. **Exporta tu configuración**:
   ```powershell
   D:\Windows-Desktop\boxstarter\registry\export-all.ps1
   ```

---

## 🔄 Re-instalación Futura

Cuando reinstales Windows:

1. Respalda `D:\Windows-Desktop\` (ya está en D:, debería persistir)
2. Instala Windows 11 Pro limpio
3. Ejecuta `setup-windows.ps1`
4. Importa backup de registro (opcional):
   ```powershell
   D:\Windows-Desktop\boxstarter\registry\import-all.ps1
   ```
5. ¡Listo! Sistema idéntico al anterior

---

## 💡 Tips

- **Acceso directo**: El script crea "Reharden Windows" en tu escritorio
- **Logs**: Revisa `D:\Windows-Desktop\scripts\logs\` si algo falla
- **Backups**: Exporta configuración antes de cambios grandes
- **DSC**: Mantiene el estado deseado del sistema automáticamente

---

## 🎉 ¡Listo!

Tu Windows está configurado como un **Full Dev Environment** sin restricciones.

**Disfruta tu sistema optimizado** 🚀

---

**Necesitas ayuda?** Revisa el `README.md` completo o ejecuta `verify-setup.ps1`
