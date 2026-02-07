#!/usr/bin/env bash

##################################################
# SETUP GENERIC SERVER
##################################################

umask 022

############################################
# Feature flags
############################################
ENABLE_DOCKER="yes"
ENABLE_GITHUB_CREDS="yes"
ENABLE_XFCE_XRDP="yes"

############################################
# GitHub identities
############################################
GITHUB_IDENTITIES=(
  "github-server:id_ed25519_github_claudio"
  "github-personal:id_ed25519_github_personal"
)

############################################
# Firewall – LAN ports only
############################################
LAN_PORTS_TCP=(
  22     # SSH
  3389   # XRDP
  139    # Samba UDP
  445    # Samba TCP
)

############################################
# Target user (non-root)
############################################
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

SSH_DIR="$TARGET_HOME/.ssh"
BASHRC="$TARGET_HOME/.bashrc"

############################################
# Safety
############################################
if [[ $EUID -ne 0 ]]; then
  echo "❌ Ejecutar como root"
fi

############################################
# Logging & resilience
############################################
log()  { echo "[INFO]  $1" | tee -a "$LOG_FILE"; }
warn() { echo "[WARN]  $1" | tee -a "$LOG_FILE"; }

run() {
  log "Running: $*"
  "$@" >>"$LOG_FILE" 2>&1 || warn "Failed: $*"
}

ensure_exec() {
  [[ -x "$1" ]] || chmod +x "$1"
}

############################################
# Detect package manager
############################################
detect_pkg_manager() {
  if command -v apt-get &>/dev/null; then
    PKG="apt"
    UPDATE="apt-get update"
    INSTALL="apt-get install -y"
  elif command -v dnf &>/dev/null; then
    PKG="dnf"
    UPDATE="dnf makecache"
    INSTALL="dnf install -y"
  elif command -v pacman &>/dev/null; then
    PKG="pacman"
    UPDATE="pacman -Sy"
    INSTALL="pacman -S --noconfirm"
  else
    warn "No supported package manager"
    exit 1
  fi
  log "Package manager: $PKG"
}

############################################
# Base system
############################################
install_base() {
  run $UPDATE
  run $INSTALL \
    sudo curl wget ca-certificates gnupg \
    openssh git keychain vim htop tmux \
    unzip dbus-x11
}

############################################
# User
############################################
setup_user() {
  if ! id "$TARGET_USER" &>/dev/null; then
    log "Creating user "$TARGET_USER""
    useradd -m -s /bin/bash "$TARGET_USER"
    passwd "$TARGET_USER"
  fi
}

############################################
# Docker (official, idempotent, server-ready)
############################################
install_docker() {
  [[ "$ENABLE_DOCKER" != "yes" ]] && return

  log "Installing Docker ($PKG)..."

  case "$PKG" in
    apt)
      # ---- Prerequisites ----
      $INSTALL ca-certificates curl gnupg >/dev/null

      # ---- Keyring ----
      if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg \
          | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
      fi

      # ---- Repo ----
      if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
          https://download.docker.com/linux/debian \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
          > /etc/apt/sources.list.d/docker.list
      fi

      $UPDATE

      # ---- Install ----
      $INSTALL \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
      ;;

    dnf)
      # ---- Repo ----
      if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
        dnf install -y dnf-plugins-core
        dnf config-manager \
          --add-repo \
          https://download.docker.com/linux/centos/docker-ce.repo
      fi

      # ---- Install ----
      $INSTALL \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
      ;;

    pacman)
      # Arch already ships recent Docker
      $INSTALL docker docker-compose
      ;;
  esac

  # ---- Enable & start service (idempotent) ----
  systemctl enable docker >/dev/null 2>&1 || true
  systemctl start docker  >/dev/null 2>&1 || true

  # ---- User permissions ----
  if [[ -n "$TARGET_USER" ]] && id "$TARGET_USER" &>/dev/null; then
    if ! id -nG "$TARGET_USER" | grep -qw docker; then
      usermod -aG docker "$TARGET_USER"
      log "User '$TARGET_USER' added to docker group (re-login required)"
    fi
  fi

  log "Docker installation completed"
}

#############
# Docker daemon config (logging + estabilidad)
#############
mkdir -p /etc/docker
cat >/etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker

############################################
# GitHub SSH
############################################
configure_github() {
  [[ "$ENABLE_GITHUB_CREDS" != "yes" ]] && return

  log "Configuring GitHub SSH (multi-identity)"

  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  SSH_CONFIG="$SSH_DIR/config"
  : > "$SSH_CONFIG"

  for entry in "${GITHUB_IDENTITIES[@]}"; do
    IFS=":" read -r host keyname <<< "$entry"

    key_path="$SSH_DIR/$keyname"

    generate_ssh_key "$key_path" "$host"

    cat >>"$SSH_CONFIG" <<EOF

Host $host
    HostName ssh.github.com
    Port 443
    User git
    IdentityFile ~/.ssh/$keyname
    IdentitiesOnly yes
EOF
  done

  chmod 600 "$SSH_CONFIG"
  chown -R "$TARGET_USER:$TARGET_USER" "$SSH_DIR"

  # Keychain (carga TODAS las claves)
  if ! grep -q "SSH Keychain (GitHub identities)" "$BASHRC" 2>/dev/null; then
    {
      echo ""
      echo "# SSH Keychain (GitHub identities)"
      echo -n "eval \$(keychain --eval --quiet"
      for entry in "${GITHUB_IDENTITIES[@]}"; do
        IFS=":" read -r _ keyname <<< "$entry"
        echo -n " $keyname"
      done
      echo ")"
      echo "alias iniciar-ssh='keychain id_ed25519_github_claudio id_ed25519_github_personal'"
    } >> "$BASHRC"
  fi

  chown "$TARGET_USER:$TARGET_USER" "$BASHRC"

  log "GitHub SSH multi-identity configured"
}

generate_ssh_key() {
  local key_path="$1"
  local comment="$2"

  if [[ ! -f "$key_path" ]]; then
    log "Generating SSH key: $key_path"
    sudo -u "$TARGET_USER" ssh-keygen \
      -t ed25519 \
      -f "$key_path" \
      -C "$comment" \
      -N ""
  else
    log "SSH key already exists: $key_path"
  fi
}

############################################
# XFCE + XRDP (on-demand)
############################################
install_xfce_xrdp() {
  [[ "$ENABLE_XFCE_XRDP" != "yes" ]] && return

  case "$PKG" in
    apt)
      run $INSTALL xfce4 xfce4-goodies xrdp dbus-x11 xauth
      ;;
    dnf)
      run $INSTALL @xfce-desktop-environment xrdp dbus-x11 xauth
      ;;
    pacman)
      run $INSTALL xfce4 xfce4-goodies xrdp dbus-x11 xauth
      ;;
  esac

  systemctl enable xrdp
  systemctl start xrdp
  adduser xrdp ssl-cert 2>/dev/null || true

  cat > /etc/skel/.xsession <<'EOF'
exec startxfce4
EOF
}

###############
# Sin GUI al inicio
###############
log "Forcing server mode (no graphical boot)"

systemctl set-default multi-user.target
systemctl disable lightdm gdm sddm 2>/dev/null || true

###############
# Config XRDP
###############
cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
exec startxfce4
EOF

chmod +x /etc/xrdp/startwm.sh

###############
# Forzar sesión XFCE para usuarios EXISTENTES
###############
echo "exec startxfce4" > "$TARGET_HOME/.xsession"
chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.xsession"
chmod 644 "$TARGET_HOME/.xsession"

systemctl restart xrdp

############################################
# Firewall
############################################
configure_firewall() {
  run $INSTALL ufw

  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing

  for port in "${LAN_PORTS_TCP[@]}"; do
    ufw allow "$port/tcp"
  done

  ufw --force enable
}

############################################
# Main
############################################
log "Bootstrap started"

detect_pkg_manager
install_base
setup_user
install_docker
configure_github
install_xfce_xrdp
configure_firewall

log "Bootstrap finished"
