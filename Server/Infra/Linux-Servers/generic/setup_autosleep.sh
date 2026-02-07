#!/bin/bash
# ============================================================
# Script de configuración automática:
# Suspensión diaria + reanudación automática con RTC (Debian)
# ============================================================
# Ajustado para sistema Debian NetInstall
# Fecha: 2025-10-29
# Descripción:
#   Configura suspensión a las 02:15 y reanudación a las 05:35 con RTC.
#   Tras reanudarse, reinicia Docker o todo el sistema según preferencia.
# ============================================================

set -e

echo "🔧 Iniciando configuración de suspensión automática diaria..."

# ------------------------------------------------------------
# 1. Validación de permisos
# ------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "❌ Este script debe ejecutarse como root. Usa: sudo $0"
  exit 1
fi

# ------------------------------------------------------------
# 2. Verificar dependencias
# ------------------------------------------------------------
echo "📦 Verificando dependencias..."

if ! command -v rtcwake &>/dev/null; then
  echo "➡️ Instalando paquete util-linux (contiene rtcwake)..."
  apt update -y && apt install -y util-linux
else
  echo "✅ rtcwake detectado."
fi

if ! command -v systemctl &>/dev/null; then
  echo "❌ systemd no encontrado. Este script requiere systemd (no SysVinit)."
  exit 1
fi

if ! command -v docker &>/dev/null; then
  echo "⚠️ Docker no detectado. Se omitirá configuración post-resume de Docker."
fi

# ------------------------------------------------------------
# 3. Crear script de suspensión diaria
# ------------------------------------------------------------
echo "📝 Creando script: /usr/local/bin/server_sleep.sh"

cat << 'EOF' > /usr/local/bin/server_sleep.sh
#!/bin/bash
# ============================================================
# Script: server_sleep.sh
# Suspende el sistema y programa reanudación con RTC.
# ============================================================

set -euo pipefail

# Determinar HOME de forma segura (algunos servicios systemd no lo definen)
USER_HOME="${HOME:-$(getent passwd $(logname) | cut -d: -f6)}"
LOG_FILE="$USER_HOME/server_sleep.log"
MAX_SIZE=$((5 * 1024 * 1024)) # 5 MB

# Crear el archivo si no existe
touch "$LOG_FILE" 2>/dev/null || {
  echo "❌ No se pudo crear el archivo de log en $LOG_FILE"
  exit 1
}

# Rotación manual del log si supera los 5 MB
if [ -f "$LOG_FILE" ]; then
  SIZE=$(stat -c%s "$LOG_FILE")
  if (( SIZE > MAX_SIZE )); then
    mv "$LOG_FILE" "${LOG_FILE}.1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔄 Log rotado (excedió 5 MB)" > "$LOG_FILE"
  fi
fi

chmod 644 "$LOG_FILE"

WAKE_HOUR="05:35"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] --- Iniciando secuencia de suspensión ---" | tee -a "$LOG_FILE"

# Calcular hora de despertar absoluta
WAKE_TIMESTAMP=$(date +%s -d "today $WAKE_HOUR")
CURRENT_TIME=$(date +%s)
if [ "$WAKE_TIMESTAMP" -le "$CURRENT_TIME" ]; then
  WAKE_TIMESTAMP=$(date +%s -d "tomorrow $WAKE_HOUR")
fi

WAKE_DATETIME=$(date -d "@$WAKE_TIMESTAMP")
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Programando reanudación para: $WAKE_DATETIME" | tee -a "$LOG_FILE"

/usr/sbin/rtcwake -m mem -t "$WAKE_TIMESTAMP"
EOF

chmod 755 /usr/local/bin/server_sleep.sh
chown root:root /usr/local/bin/server_sleep.sh

# ------------------------------------------------------------
# 4. Crear servicio y timer para suspensión
# ------------------------------------------------------------
echo "⚙️ Creando servicio y temporizador systemd..."

cat << 'EOF' > /etc/systemd/system/server-sleep.service
[Unit]
Description=Suspensión diaria con rtcwake
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/server_sleep.sh
StandardOutput=journal
StandardError=journal
EOF

cat << 'EOF' > /etc/systemd/system/server-sleep.timer
[Unit]
Description=Ejecuta server-sleep.service cada día a las 02:15 AM

[Timer]
OnCalendar=*-*-* 02:15:00
Persistent=true
Unit=server-sleep.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now server-sleep.timer

# ------------------------------------------------------------
# 5. Crear acción post-resume
# ------------------------------------------------------------
echo "🔁 Configurando acción tras la reanudación..."

# Modo: docker_restart o full_reboot
RESUME_MODE="full_reboot"

# Script post-resume
cat << 'EOF' > /usr/local/bin/post_resume_action.sh
#!/bin/bash

set -euo pipefail

# Determinar HOME de forma segura (algunos servicios systemd no lo definen)
USER_HOME="${HOME:-$(getent passwd $(logname) | cut -d: -f6)}"
LOG_FILE="$USER_HOME/post_resume.log"
MAX_SIZE=$((5 * 1024 * 1024)) # 5 MB

# Crear el archivo si no existe
touch "$LOG_FILE" 2>/dev/null || {
  echo "❌ No se pudo crear el archivo de log en $LOG_FILE"
  exit 1
}

# Rotación manual del log si supera los 5 MB
if [ -f "$LOG_FILE" ]; then
  SIZE=$(stat -c%s "$LOG_FILE")
  if (( SIZE > MAX_SIZE )); then
    mv "$LOG_FILE" "${LOG_FILE}.1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔄 Log rotado (excedió 5 MB)" > "$LOG_FILE"
  fi
fi

chmod 644 "$LOG_FILE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🌙 Sistema reanudado. Ejecutando acción post-resume..." | tee -a "$LOG_FILE"

# Esperar un poco para que systemd estabilice servicios
sleep 20

# Descomentar estas líneas si deseas reiniciar solo el servicio Docker
#if command -v docker &>/dev/null; then
#  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔄 Reiniciando Docker..." | tee -a "$LOG_FILE"
#  systemctl restart docker
#  docker start $(docker ps -a -q --filter "status=exited") || true
#fi

# Descomentar esta línea si deseas reiniciar completamente el sistema
 echo "[$(date '+%Y-%m-%d %H:%M:%S')] ♻️ Reiniciando sistema tras reanudación..." | tee -a "$LOG_FILE"
sleep 10
systemctl reboot
EOF

chmod +x /usr/local/bin/post_resume_action.sh

# Servicio systemd para ejecutar tras reanudación
cat << 'EOF' > /etc/systemd/system/post-resume.service
[Unit]
Description=Ejecutar acción personalizada tras la reanudación
After=suspend.target hibernate.target sleep.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/post_resume_action.sh

[Install]
WantedBy=suspend.target
WantedBy=hibernate.target
WantedBy=sleep.target
EOF

systemctl daemon-reload
systemctl enable post-resume.service

# ------------------------------------------------------------
# 6. Resumen final
# ------------------------------------------------------------
echo ""
echo "✅ Configuración completada."
echo "🕐 Suspensión: todos los días a las 02:15"
echo "⏰ Reanudación: todos los días a las 05:35"
echo "🔁 Acción tras reanudación: $RESUME_MODE"
echo ""
echo "📄 Logs (ubicados en tu carpeta home):"
echo "  - ~/server_sleep.log"
echo "  - ~/post_resume.log"
echo ""
echo "🧩 Servicios creados:"
echo "  - server-sleep.service / .timer"
echo "  - post-resume.service"
echo ""
echo "🧪 Probar manualmente:"
echo "     sudo /usr/local/bin/server_sleep.sh"
echo ""
echo "✅ Todo listo."
