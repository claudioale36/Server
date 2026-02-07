#!/bin/bash
set -e

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

log_step "=== Detectando gestor de paquetes ==="

if command -v apt >/dev/null 2>&1; then
    PKG="apt"
elif command -v yum >/dev/null 2>&1; then
    PKG="yum"
elif command -v dnf >/dev/null 2>&1; then
    PKG="dnf"
elif command -v pacman >/dev/null 2>&1; then
    PKG="pacman"
else
    echo "❌ No se pudo detectar un gestor de paquetes compatible."
    exit 1
fi

log_ok "➡️ Gestor detectado: $PKG"
echo ""

echo "=== Instalando Git + Keychain + Git Credential Manager ==="

case $PKG in
    apt)
        sudo apt update
        sudo apt install -y git git-lfs keychain wget gpg
        wget -q https://aka.ms/gcm/linux-install-source.sh -O /tmp/gcm.sh
        sudo bash /tmp/gcm.sh install
        ;;
    yum)
        sudo yum install -y git git-lfs keychain wget gpg
        wget -q https://aka.ms/gcm/linux-install-source.sh -O /tmp/gcm.sh
        sudo bash /tmp/gcm.sh install
        ;;
    dnf)
        sudo dnf install -y git git-lfs keychain wget gpg
        wget -q https://aka.ms/gcm/linux-install-source.sh -O /tmp/gcm.sh
        sudo bash /tmp/gcm.sh install
        ;;
    pacman)
        sudo pacman -Sy --noconfirm git git-lfs keychain wget gnupg
        wget -q https://aka.ms/gcm/linux-install-source.sh -O /tmp/gcm.sh
        sudo bash /tmp/gcm.sh install
        ;;
esac

log_step "=== Configurando Git ==="

read -p "Usuario GitHub: " GH_USER
read -p "Email GitHub: " GH_EMAIL

git config --global user.name "$GH_USER"
git config --global user.email "$GH_EMAIL"

# Activar Credential Manager
git config --global credential.helper manager

log_step "=== Creando script modular iniciar-ssh.sh ==="

cat << 'EOF' | sudo tee /usr/local/bin/iniciar-ssh.sh >/dev/null
#!/bin/bash
echo "🔐 Cargando claves SSH mediante keychain..."
keychain --quiet --eval ~/.ssh/id_ed25519_$GH_EMAIL > /tmp/keychain_env
source /tmp/keychain_env
echo "SSH Agent listo."
EOF

sudo chmod +x /usr/local/bin/iniciar-ssh.sh

log_step "=== Insertando configuración en .bashrc (si no existe) ==="

BASHRC="$HOME/.bashrc"

ensure_line() {
    grep -qxF "$1" "$BASHRC" || echo "$1" >> "$BASHRC"
}

ensure_line ''
ensure_line '# Carga automática de SSH keychain'
ensure_line 'if [ -f "$HOME/.keychain/$(hostname)-sh" ]; then'
ensure_line '    . "$HOME/.keychain/$(hostname)-sh"'
ensure_line 'elif [ -f "$HOME/.keychain/$(hostname)-xorg-sh" ]; then'
ensure_line '    . "$HOME/.keychain/$(hostname)-xorg-sh"'
ensure_line 'fi'
ensure_line 'alias iniciar-ssh="/usr/local/bin/iniciar-ssh.sh"'
ensure_line ''

log_ok "=== Configuración completada ==="
log_ok "👍 Git Credential Manager activado"
log_ok "🔐 Keychain configurado"
log_ok "▶️ Puedes ejecutar: iniciar-ssh"
log_ok "🔁 Tras reiniciar, SSH estará siempre listo."
log_ok "🎉 Sistema preparado para deploys automáticos 🚀"
