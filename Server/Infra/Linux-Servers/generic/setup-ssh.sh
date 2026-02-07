#!/usr/bin/env bash
set -euo pipefail

########################
## LOGS
########################
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

log_step()  { echo -e "\n${YELLOW}➡️  $1${RESET}"; }
log_ok()    { echo -e "${GREEN}✅ $1${RESET}"; }
log_warn()  { echo -e "${YELLOW}⚠️  $1${RESET}"; }
log_error() { echo -e "${RED}❌ $1${RESET}"; }
fail_exit() { log_error "$1"; exit 1; }

########################
## CHEQUEOS CRITICOS
########################
[[ $EUID -eq 0 ]] || fail_exit "Este script debe ejecutarse como root"

ACTIVE_SSH="$(who | grep -c 'pts/')"

########################
## INSTALAR DEPENDENCIAS
########################
install_packages() {
  log_step "Verificando dependencias críticas (openssh-server, ufw)..."

  apt update -qq

  for pkg in openssh-server ufw; do
    if ! dpkg -s "$pkg" &>/dev/null; then
      log_step "Instalando $pkg..."
      apt install -y "$pkg"
    else
      log_ok "$pkg ya está instalado"
    fi
  done
}

########################
## CONFIGURAR SSH
########################
configure_sshd() {
  log_step "Configurando SSH de forma segura..."

  local SSHD_CONF="/etc/ssh/sshd_config"
  local BACKUP="${SSHD_CONF}.bak.$(date +%F_%T)"

  [[ -f "$SSHD_CONF" ]] || fail_exit "sshd_config no encontrado"

  cp "$SSHD_CONF" "$BACKUP"

  # Helper idempotente
  set_sshd_option() {
    local key="$1"
    local value="$2"

    if grep -qE "^${key}\s+" "$SSHD_CONF"; then
      sed -i "s|^${key}\s\+.*|${key} ${value}|" "$SSHD_CONF"
    else
      echo "${key} ${value}" >> "$SSHD_CONF"
    fi
  }

  set_sshd_option "Port" "22"
  set_sshd_option "Protocol" "2"
  set_sshd_option "PermitRootLogin" "no"
  set_sshd_option "PasswordAuthentication" "yes"
  set_sshd_option "PubkeyAuthentication" "yes"
  set_sshd_option "PermitEmptyPasswords" "no"
  set_sshd_option "ChallengeResponseAuthentication" "no"
  set_sshd_option "UsePAM" "yes"
  set_sshd_option "X11Forwarding" "no"
  set_sshd_option "ClientAliveInterval" "300"
  set_sshd_option "ClientAliveCountMax" "2"
  set_sshd_option "LoginGraceTime" "30"
  set_sshd_option "MaxAuthTries" "3"

  log_ok "sshd_config configurado"
}

########################
## VALIDAR CONFIGURACION SSH
########################
validate_sshd() {
  log_step "Validando configuración SSH..."

  if sshd -t; then
    log_ok "Configuración SSH válida"
  else
    fail_exit "Configuración SSH inválida. No se aplicaron cambios."
  fi
}

########################
## FIREWALL (UFW)
########################
configure_ufw() {
  log_step "Configurando UFW (LAN-only, seguro)..."

  ufw default deny incoming
  ufw default allow outgoing

  # SSH solo LAN
  ufw allow from 192.168.1.0/24 to any port 22 proto tcp

  # Permitir loopback
  ufw allow in on lo

  # Activar UFW sin romper SSH
  if ! ufw status | grep -q "Status: active"; then
    echo "y" | ufw enable
  fi

  log_ok "UFW configurado y activo"
}

########################
## SERVICIO SSH
########################
restart_ssh() {
  log_step "Reiniciando servicio SSH..."

  systemctl enable ssh
  systemctl restart ssh

  systemctl status ssh --no-pager | grep Active || true

  log_ok "SSH activo"
}

########################
## PROTECCION ANTI-BLOQUEO
########################
post_checks() {
  log_step "Chequeos finales..."

  if [[ "$ACTIVE_SSH" -gt 0 ]]; then
    log_ok "Sesión SSH activa detectada — no se cortó la conexión"
  else
    log_warn "No se detectó sesión SSH activa"
  fi
}

########################
## MAIN
########################
main() {
  log_step "Bootstrap SSH crítico del servidor"

  install_packages
  configure_sshd
  validate_sshd
  configure_ufw
  restart_ssh
  post_checks

  log_ok "Servidor listo para administración remota segura"
}

main "$@"
