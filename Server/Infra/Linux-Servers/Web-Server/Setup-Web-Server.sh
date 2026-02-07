#!/usr/bin/env bash
### SETUP SERVER
# - Repos oficiales y update
# - Usuario admin no-root (opcional auto-creación)
# - Docker (get.docker.com) + daemon.json con rotación de logs
# - XFCE sin display manager + NoMachine
# - SSH hardening opcional
# - Unattended upgrades
# - UFW
# Ejecutar como root. Puedes definir TARGET_USER antes de ejecutar.

set -euo pipefail

IFS=$'\n\t'

trap 'echo "❌ Error en la línea $LINENO"; exit 1' ERR

########################
## CONFIGURACIÓN
########################
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"                   # Detectar la ruta del script

export UBUNTUSERVER_FRONTEND=noninteractive

# Usuario objetivo (por defecto: SUDO_USER si existe, sino whoami si es root, y si no existe lo crea)
TARGET_USER="${TARGET_USER:-}"
NOMACHINE_URL="https://www.nomachine.com/free/linux/64/deb"
TMP_DIR="/tmp/nomachine_install"

# Flags de endurecimiento (puedes cambiar a "false" si no quieres aplicar)
HARDEN_SSH="${HARDEN_SSH:-true}"
ENABLE_UFW="${ENABLE_UFW:-true}"

# Puertos a permitir si UFW está activo
ALLOW_SSH_PORT="${ALLOW_SSH_PORT:-22}"
ALLOW_NOMACHINE_PORT="${ALLOW_NOMACHINE_PORT:-4000}"

ALLOW_SAMBA_UDP_PORT=139
ALLOW_SAMBA_TCP_PORT=445

ALLOW_AVAHI_UDP_PORT=5353
ALLOW_AVAHI_TCP_PORT=5353

# Archivo de logs
LOG_FILE="$DIR/instalacion.log"

########################
### CONFIG DINAMICA ###
########################
echo "LAN_IP=$(hostname -I | awk '{print $1}')" > .env

########################
## HELPERS
########################
log() { echo -e "$*"; }

command_exists() { command -v "$1" &>/dev/null; }

apt_update_quiet() { apt-get update -yq; }

apt_install_safe() {
  # instala paquetes, pero NO aborta si alguno falla
  local pkgs=("$@")
  if ((${#pkgs[@]})); then
    apt-get install -yq "${pkgs[@]}" || log "⚠️  Algunos paquetes fallaron al instalarse: ${pkgs[*]} (continuando)"
  fi
}

file_has_line() { local f="$1" line="$2"; grep -Fqx "$line" "$f" 2>/dev/null; }

ensure_line_in_file() {
  local f="$1" line="$2"
  file_has_line "$f" "$line" || echo "$line" >>"$f"
}

get_codename() {
  # Detecta codename (bookworm, etc.)
  if command_exists lsb_release; then
    lsb_release -cs
  elif [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "${VERSION_CODENAME:-bookworm}"
  else
    echo "bookworm"
  fi
}

########################
## CHEQUEOS INICIALES
########################
check_root() {
  if [[ $(id -u) -ne 0 ]]; then
    log "⚠️  Este script debe ejecutarse como root o con sudo."
    exit 1
  fi
}

detect_target_user() {
  if [[ -n "$TARGET_USER" ]]; then
    log "👤 Usando TARGET_USER=$TARGET_USER"
    return
  fi
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    TARGET_USER="$SUDO_USER"
  else
    TARGET_USER="$(whoami)"
    # Si whoami es root, proponemos 'admin' como usuario no-root
    if [[ "$TARGET_USER" == "root" ]]; then
      TARGET_USER="admin"
    fi
  fi
  log "👤 Usuario objetivo: $TARGET_USER"
}

########################
## REPOS & SISTEMA
########################
configure_repos() {
  log "📝 Configurando repositorios de Debian..."
  local sources_file="/etc/apt/sources.list"
  local release
  release="$(get_codename)"

  cat > "$sources_file" <<EOF
deb http://deb.debian.org/debian ${release} main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian ${release} main contrib non-free non-free-firmware

deb http://deb.debian.org/debian-security ${release}-security main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian-security ${release}-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian ${release}-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian ${release}-updates main contrib non-free non-free-firmware
EOF

  apt_update_quiet
}

########################
## ACTUALIZA EL SISTEMA, INSTALA DEPENDENCIAS MINIMAS Y ACTIVA ACTUALIZACIONES DESATENDIDAS
########################
system_update() {
  log "🧼 Actualizando sistema e instalando base mínima..."
  apt-get upgrade -yq
  apt_install_safe sudo curl wget ca-certificates gnupg lsb-release apt-transport-https bash-completion \
                   locales htop vim git net-tools ufw fail2ban
  apt-get autoremove --purge -yq || true
  apt-get clean || true
}

enable_unattended_upgrades() {
  log "🔄 Activando actualizaciones automáticas de seguridad..."
  apt_install_safe unattended-upgrades apt-listchanges
  # Forzar configuración no interactiva
  mkdir -p /etc/apt/apt.conf.d
  cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

  # Habilitar orígenes de seguridad por defecto
  cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=${distro_codename},label=Debian-Security";
        "origin=Debian,codename=${distro_codename},label=Debian";
};
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:30";
EOF
}

########################
##      LOCALES
########################
configure_locale() {
  log "🌍 Configurando locales..."
  sed -i 's/^# *es_AR.UTF-8 UTF-8/es_AR.UTF-8 UTF-8/' /etc/locale.gen || true
  sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen || true
  locale-gen || true
  update-locale LANG=es_AR.UTF-8 || true
}

########################
##    SWAP Y LOGS
########################
setup_swap() {
  if ! swapon --show | grep -q "/swapfile"; then
    log "💾 Creando swapfile de 1GB..."
    fallocate -l 1G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=1024
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    ensure_line_in_file /etc/fstab "/swapfile none swap sw 0 0"
  else
    log "✅ Swap ya configurada."
  fi
}

tune_journald() {
  log "🧻 Limitando tamaño de logs del sistema (journald)..."
  mkdir -p /etc/systemd/journald.conf.d
  cat > /etc/systemd/journald.conf.d/size-limit.conf <<EOF
[Journal]
SystemMaxUse=100M
SystemMaxFileSize=20M
RuntimeMaxUse=50M
EOF
  systemctl restart systemd-journald || true
}

########################
## XFCE + NOMACHINE
########################
install_xfce() {
  log "🖥️ Instalando XFCE sin display manager..."
  apt_install_safe xfce4 xfce4-goodies xfce4-terminal xauth dbus-x11 x11-xserver-utils

  local user_home
  user_home=$(eval echo "~$TARGET_USER")
  echo "exec startxfce4" > "${user_home}/.xsession"
  chown "$TARGET_USER:$TARGET_USER" "${user_home}/.xsession"
  chmod +x "${user_home}/.xsession"
}

install_nomachine() {
  log "📡 Instalando NoMachine..."
  mkdir -p "$TMP_DIR"
  pushd "$TMP_DIR" >/dev/null || return 1

  local latest_deb
  latest_deb=$(wget -qO- "$NOMACHINE_URL" \
    | grep -oP 'https:\/\/download\.nomachine\.com\/download\/\d+\/Linux\/nomachine_.*?_amd64\.deb' \
    | head -n1 || true)

  if [[ -z "${latest_deb:-}" ]]; then
    log "⚠️  No se pudo obtener la URL de NoMachine. Saltando instalación."
    popd >/dev/null || true
    rm -rf "$TMP_DIR"
    return 0
  fi

  wget -q "$latest_deb" -O nomachine.deb || { log "⚠️  Descarga falló, saltando NoMachine."; popd >/dev/null; rm -rf "$TMP_DIR"; return 0; }
  dpkg -i nomachine.deb || apt-get install -f -yq || true

  popd >/dev/null || true
  rm -rf "$TMP_DIR"
}

########################
## SSH / FIREWALL / UPDATES
########################
harden_ssh() {
  $HARDEN_SSH || { log "🔓 Hardening SSH desactivado por configuración."; return 0; }

  log "🔐 Endureciendo SSH (solo acceso LAN, sin root, seguro)..."

  local sshd="/etc/ssh/sshd_config"

  # Remove any existing entries to avoid duplicates, then append
  sed -i '/^PermitRootLogin/d' "$sshd"
  echo "PermitRootLogin no" >> "$sshd"

  sed -i '/^PasswordAuthentication/d' "$sshd"
  echo "PasswordAuthentication no" >> "$sshd"

  sed -i '/^MaxAuthTries/d' "$sshd"
  echo "MaxAuthTries 3" >> "$sshd"

  sed -i '/^LoginGraceTime/d' "$sshd"
  echo "LoginGraceTime 20" >> "$sshd"

  sed -i '/^ClientAliveInterval/d' "$sshd"
  echo "ClientAliveInterval 300" >> "$sshd"

  sed -i '/^ClientAliveCountMax/d' "$sshd"
  echo "ClientAliveCountMax 2" >> "$sshd"

  sed -i '/^AddressFamily/d' "$sshd"
  echo "AddressFamily inet" >> "$sshd"

  sed -i '/^AllowTcpForwarding/d' "$sshd"
  echo "AllowTcpForwarding no" >> "$sshd"

  sed -i '/^X11Forwarding/d' "$sshd"
  echo "X11Forwarding no" >> "$sshd"

  sed -i '/^UsePAM/d' "$sshd"
  echo "UsePAM yes" >> "$sshd"

  # (Opcional) Si querés limitar el acceso a un usuario concreto:
  # sed -i '/^AllowUsers/d' "$sshd"
  # echo "AllowUsers $TARGET_USER" >> "$sshd"

  systemctl restart ssh || systemctl restart sshd || true
  log "🔐 SSH endurecido y reiniciado. Nota: PasswordAuthentication=NO (usar claves)."
}

setup_ufw() {
  $ENABLE_UFW || { log "🧱 UFW desactivado por configuración."; return 0; }

  log "🧱 Configurando UFW con restricciones estrictas (solo LAN)..."

  # Detectar IP principal y CIDR del host robustamente
  IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
  CIDR=$(ip -o -4 addr show | awk -v ip="$IP_ADDR" '$0~ip{print $4; exit}')
  if [ -z "$CIDR" ]; then
    log "⚠ No se pudo detectar CIDR automáticamente. Intentando fallback /24..."
    if [[ "$IP_ADDR" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$ ]]; then
      CIDR="${BASH_REMATCH[1]}.0/24"
    else
      CIDR="192.168.1.0/24"
    fi
  fi
  LAN_RANGE="$CIDR"
  log "📡 LAN detectada: $LAN_RANGE (IP local: $IP_ADDR)"

  # Desactivar IPv6 en UFW (si no lo usas)
  if [ -f /etc/default/ufw ]; then
    sed -i 's/^IPV6=.*/IPV6=no/' /etc/default/ufw || true
  fi

  # Antes de habilitar UFW, prevenir ataques a SSH desde WAN (iptables inmediato)
  # DROP paquetes TCP a 22 que NO vengan de la LAN
  if command -v iptables >/dev/null 2>&1; then
    iptables -C INPUT -p tcp --dport "${ALLOW_SSH_PORT}" ! -s "${LAN_RANGE}" -j DROP 2>/dev/null || \
      iptables -I INPUT -p tcp --dport "${ALLOW_SSH_PORT}" ! -s "${LAN_RANGE}" -j DROP
    log "iptables: bloqueo preventivo de SSH desde WAN aplicado."
  fi

  # Reset y políticas
  ufw --force reset || true
  ufw default deny incoming
  ufw default allow outgoing

  # SSH solo desde LAN
  if [ -n "$ALLOW_SSH_PORT" ]; then
    ufw allow from "${LAN_RANGE}" to any port "${ALLOW_SSH_PORT}" proto tcp || true
  fi

  # Puertos adicionales SOLO desde LAN
  if [ -n "$ENABLE_PORTS" ]; then
    for PORT in $ENABLE_PORTS; do
      log "🔌 Abriendo puerto $PORT solo desde LAN..."
      ufw allow from "${LAN_RANGE}" to any port "${PORT}" proto tcp || true
      # NoMachine uses UDP 4000 too
      if [ "$PORT" == "4000" ]; then
        ufw allow from "${LAN_RANGE}" to any port 4000 proto udp || true
      fi
    done
  fi

  # Nextcloud solo LAN (usar variables si definen)
  ufw allow from "${LAN_RANGE}" to any port "${NEXTCLOUD_HTTP_PORT:-8080}" proto tcp || true
  ufw allow from "${LAN_RANGE}" to any port "${NEXTCLOUD_HTTPS_PORT:-8443}" proto tcp || true

  # Samba solo LAN (usar variables si definen)
  ufw allow from "${LAN_RANGE}" to any port "${SAMBA_UDP_PORT:-139}" proto udp || true
  ufw allow from "${LAN_RANGE}" to any port "${SAMBA_TCP_PORT:-445}" proto tcp || true

  # Avahi con mDNS solo LAN (usar variables si definen)
  ufw allow from "${LAN_RANGE}" to any port "${AVAHI_UDP_PORT:-5353}" proto udp || true
  ufw allow from "${LAN_RANGE}" to any port "${AVAHI_TCP_PORT:-5353}" proto tcp || true

  ufw --force enable || true
  log "🧱 UFW configurado y activo. TODO fuera de LAN está bloqueado."

  # Refuerzo adicional: bloquear puerto 22 en ipv6 y ipv4 (si existe)
  if command -v ip6tables >/dev/null 2>&1; then
    ip6tables -I INPUT -p tcp --dport "${ALLOW_SSH_PORT}" -j REJECT || true
  fi
}

########################
## DESACTIVAR LANZAMIENTO DE LA GUI EN EL INICIO
########################
disable_auto_gui() {
  log "🛑 Desactivando arranque automático del entorno gráfico..."
  # Cambiar target por defecto a multi-user (modo texto)
  systemctl set-default multi-user.target

  # Detener y deshabilitar posibles display managers
  for dm in gdm3 lightdm sddm xdm; do
    if systemctl is-enabled "$dm" &>/dev/null; then
      systemctl disable "$dm" || true
      systemctl stop "$dm" || true
      log "🚫 Display manager $dm deshabilitado."
    fi
  done
}


########################
## MENSAJE FINAL
########################
final_message() {
  log "✅ Instalación completada."
  log "👤 Usuario objetivo: $TARGET_USER"
  log "ℹ️  Cierra sesión y vuelve a entrar para que el grupo 'docker' aplique a ${TARGET_USER}."
  log "➡️ Puedes reiniciar: sudo reboot"
}

########################
## MAIN
########################
main() {
  log "🔧 Iniciando configuración del servidor..."
  check_root
  ./create_basic_user
  configure_locale

  system_update
  configure_repos
  enable_unattended_upgrades

  setup_swap
  tune_journald

  disable_auto_gui

  harden_ssh
  setup_ufw
  ./setup-avahi.sh

  ./setup-docker.sh

##########################
### PROGRAMAS ADICIONALES
##########################
  # Entorno de Escritorio
  ./install-xfce.sh

  # Remmina y NoMachine para escritorio remoto
  ./setup-nomachine.sh
  ./setup-remmina.sh

  # Instalar Webmin
  ./setup-webmin.sh

  # Ejecutar script de instalación para Nextcloud
  ./Server/Nextcloud/scripts/setup-nextcloud.sh

  final_message
}

main "$@"
