#!/usr/bin/env bash
set -euo pipefail

########################
## LOGS
########################
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

log_step()   { echo -e "\n${YELLOW}➡️  $1${RESET}"; }
log_ok()     { echo -e "${GREEN}✅ $1${RESET}"; }
log_warn()   { echo -e "${YELLOW}⚠️  $1${RESET}"; }
log_error()  { echo -e "${RED}❌ $1${RESET}"; }
fail_exit()  { log_error "$1"; exit 1; }

########################
## CHEQUEOS
########################
[[ $EUID -eq 0 ]] || fail_exit "Este script debe ejecutarse como root"

########################
## INSTALAR DEPENDENCIAS
########################
install_packages() {
  log_step "Instalando dependencias XRDP + XFCE..."

  apt update -qq

  apt install -y \
    xrdp \
    xorgxrdp \
    dbus-x11 \
    xfce4 \
    xfce4-session \
    xfce4-terminal \
    xfce4-panel \
    xfce4-settings
}

########################
## CONFIGURAR XFCE PARA XRDP
########################
configure_xfce() {
  log_step "Configurando XFCE como entorno por defecto para xrdp..."

  # startwm.sh
  local STARTWM="/etc/xrdp/startwm.sh"

  if ! grep -q "startxfce4" "$STARTWM"; then
    cp "$STARTWM" "${STARTWM}.bak.$(date +%F_%T)"
    sed -i '/^test -x \/etc\/X11\/Xsession/,$d' "$STARTWM"

    cat <<'EOF' >> "$STARTWM"
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

exec dbus-launch --exit-with-session startxfce4
EOF
  fi

  log_ok "XFCE configurado en startwm.sh"
}

########################
## CREAR .xsession
########################
configure_xsession() {
  log_step "Configurando .xsession por defecto..."

  echo "startxfce4" > /etc/skel/.xsession
  chmod 644 /etc/skel/.xsession

  # Aplicar a usuarios existentes
  for home in /home/*; do
    [[ -d "$home" ]] || continue
    user="$(basename "$home")"

    if id "$user" &>/dev/null; then
      echo "startxfce4" > "$home/.xsession"
      chown "$user:$user" "$home/.xsession"
    fi
  done

  log_ok ".xsession configurado"
}

########################
## DESACTIVAR WAYLAND
########################
disable_wayland() {
  log_step "Desactivando Wayland..."

  local GDM_CONF="/etc/gdm3/custom.conf"

  if [[ -f "$GDM_CONF" ]]; then
    sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' "$GDM_CONF"
    sed -i 's/^WaylandEnable=true/WaylandEnable=false/' "$GDM_CONF"
  fi

  log_ok "Wayland desactivado"
}

########################
## ASEGURAR QUE NO INICIE GUI AL BOOT
########################
disable_gui_boot() {
  log_step "Asegurando que el entorno grafico no inicie al arrancar..."

  systemctl set-default multi-user.target

  log_ok "GUI no iniciará al boot"
}

########################
## PERMISOS XRDP
########################
configure_permissions() {
  log_step "Configurando permisos XRDP..."

  adduser xrdp ssl-cert || true

  chmod 1777 /tmp || true

  log_ok "Permisos XRDP verificados"
}

########################
## SERVICIOS
########################
restart_services() {
  log_step "Reiniciando y habilitando xrdp..."

  systemctl enable xrdp
  systemctl restart xrdp

  systemctl status xrdp --no-pager | grep Active || true
}

########################
## FIREWALL (LAN ONLY)
########################
configure_firewall() {
  if command -v ufw &>/dev/null; then
    log_step "Configurando UFW (solo LAN)..."
    ufw allow from 192.168.1.0/24 to any port 3389 proto tcp
    ufw reload
  fi
}

########################
## MAIN
########################
main() {
  log_step "Configurando servidor RDP (xrdp + XFCE)..."

  install_packages
  configure_xfce
  configure_xsession
  disable_wayland
  disable_gui_boot
  configure_permissions
  restart_services
  configure_firewall

  log_ok "Servidor xrdp listo para conexiones LAN"
}

main "$@"
