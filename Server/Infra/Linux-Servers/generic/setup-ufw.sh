#!/usr/bin/env bash

set -euo pipefail

# === COLORES ===
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

# === FUNCIONES AUXILIARES ===
log_step()   { echo -e "\n${YELLOW}➡️  $1${RESET}"; }
log_ok()     { echo -e "${GREEN}✅ $1${RESET}"; }
log_warn()   { echo -e "${YELLOW}⚠️  $1${RESET}"; }
log_error()  { echo -e "${RED}❌ $1${RESET}"; }
fail_exit()  { log_error "$1"; exit 1; }

###
# VARIABLES
###
# Puertos a permitir si UFW está activo
ALLOW_SSH_PORT="${ALLOW_SSH_PORT:-22}"

ALLOW_SAMBA_UDP_PORT=139
ALLOW_SAMBA_TCP_PORT=445

ALLOW_RDP_PORT=3389

# Flags de endurecimiento (puedes cambiar a "false" si no quieres aplicar)
HARDEN_SSH="${HARDEN_SSH:-true}"
ENABLE_UFW="${ENABLE_UFW:-true}"

$ENABLE_UFW || { log "🧱 UFW desactivado por configuración."; return 0; }

log_step "🧱 Configurando UFW con restricciones estrictas (solo LAN)..."

# Detectar IP principal y CIDR del host robustamente
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
CIDR=$(ip -o -4 addr show | awk -v ip="$IP_ADDR" '$0~ip{print $4; exit}')
if [ -z "$CIDR" ]; then
  log_error "⚠ No se pudo detectar CIDR automáticamente. Intentando fallback /24..."
  if [[ "$IP_ADDR" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$ ]]; then
    CIDR="${BASH_REMATCH[1]}.0/24"
  else
    CIDR="192.168.1.0/24"
  fi
fi

LAN_RANGE="$CIDR"
log_step "📡 LAN detectada: $LAN_RANGE (IP local: $IP_ADDR)"

# Desactivar IPv6 en UFW (si no lo usas)
if [ -f /etc/default/ufw ]; then
  sed -i 's/^IPV6=.*/IPV6=no/' /etc/default/ufw || true
fi

# Antes de habilitar UFW, prevenir ataques a SSH desde WAN (iptables inmediato)
# DROP paquetes TCP a 22 que NO vengan de la LAN
if command -v iptables >/dev/null 2>&1; then
  iptables -C INPUT -p tcp --dport "${ALLOW_SSH_PORT}" ! -s "${LAN_RANGE}" -j DROP 2>/dev/null || \
  iptables -I INPUT -p tcp --dport "${ALLOW_SSH_PORT}" ! -s "${LAN_RANGE}" -j DROP
  log_ok "iptables: bloqueo preventivo de SSH desde WAN aplicado."
fi

# Reset y políticas
ufw --force reset || true
ufw default deny incoming
ufw default allow outgoing

# SSH solo desde LAN
if [ -n "$ALLOW_SSH_PORT" ]; then
  ufw allow from "${LAN_RANGE}" to any port "${ALLOW_SSH_PORT}" proto tcp || true
fi

# SSH solo LAN (usar variables si definen)
ufw allow from "${LAN_RANGE}" to any port "${SSH_HTTP_PORT:-22}" proto tcp || true
ufw allow from "${LAN_RANGE}" to any port "${SSH_HTTPS_PORT:-22}" proto tcp || true

# RDP solo LAN (usar variables si definen)
ufw allow from "${LAN_RANGE}" to any port "${RDP_HTTP_PORT:-3389}" proto tcp || true
ufw allow from "${LAN_RANGE}" to any port "${RDP_HTTPS_PORT:-3389}" proto tcp || true

# Samba solo LAN (usar variables si definen)
ufw allow from "${LAN_RANGE}" to any port "${SAMBA_UDP_PORT:-139}" proto udp || true
ufw allow from "${LAN_RANGE}" to any port "${SAMBA_TCP_PORT:-445}" proto tcp || true

# Avahi con mDNS solo LAN (usar variables si definen)
ufw allow from "${LAN_RANGE}" to any port "${AVAHI_UDP_PORT:-5353}" proto udp || true
ufw allow from "${LAN_RANGE}" to any port "${AVAHI_TCP_PORT:-5353}" proto tcp || true

# Puerto para Base de datos Postgres
ufw allow from "${LAN_RANGE}" to any port "${POSTGRES_TCP_PORT:-5432}" proto tcp || true

# Puerto para N8N
ufw allow from "${LAN_RANGE}" to any port "${N8N_TCP_PORT:-5678}" proto tcp || true


ufw --force enable || true

log_ok "🧱 UFW configurado y activo. TODO fuera de LAN está bloqueado."

# Refuerzo adicional: bloquear puerto 22 en ipv6 y ipv4 (si existe)
if command -v ip6tables >/dev/null 2>&1; then
  ip6tables -I INPUT -p tcp --dport "${ALLOW_SSH_PORT}" -j REJECT || true
fi

