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

# ========= VARIABLES =========
USER_HOME="$HOME"
SSH_DIR="$USER_HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
BASHRC="$USER_HOME/.bashrc"
KEYCHAIN_BLOCK="# >>> keychain ssh <<<"

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
        sudo apt install -y git keychain
        ;;
    yum)
        sudo yum install -y git keychain
        ;;
    dnf)
        sudo dnf install -y git keychain
        ;;
    pacman)
        sudo pacman -Sy --noconfirm git keychain
        ;;
esac
log_ok "Dependencias instaladas"

log_step "=== Configurando Git ==="

read -p "Usuario GitHub: " GH_USER
read -p "Email GitHub: " GH_EMAIL

git config --global user.name "$GH_USER"
git config --global user.email "$GH_EMAIL"
git config --global credential.helper cache     # Activar Credential Manager

log_ok "Git configurado"

# ========= SSH =========
log_step "Configurando SSH"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t ed25519 -C "$GH_EMAIL" -f "$SSH_KEY" -N ""
    log_ok "Clave SSH creada"
else
    log_ok "Clave SSH ya existe"
fi

# ========= SCRIPT iniciar-ssh =========
log_step "Creando comando iniciar-ssh"

sudo tee /usr/local/bin/iniciar-ssh >/dev/null << 'EOF'
#!/bin/bash
echo "🔐 Cargando claves SSH con keychain..."
keychain --quiet --eval ~/.ssh/id_ed25519
source ~/.keychain/$(hostname)-sh 2>/dev/null
echo "SSH Agent listo."
EOF

sudo chmod +x /usr/local/bin/iniciar-ssh
log_ok "Comando iniciar-ssh creado"

# ========= BASHRC (IDEMPOTENTE) =========
log_step "Configurando carga automática en .bashrc"

if ! grep -q "$KEYCHAIN_BLOCK" "$BASHRC"; then
cat >> "$BASHRC" << EOF

$KEYCHAIN_BLOCK
# Keychain SSH
if command -v keychain >/dev/null 2>&1; then
    keychain --quiet ~/.ssh/id_ed25519
    [ -f "\$HOME/.keychain/\$(hostname)-sh" ] && source "\$HOME/.keychain/\$(hostname)-sh"
fi

alias iniciar-ssh="/usr/local/bin/iniciar-ssh"
# <<< keychain ssh <<<
EOF
    log_ok ".bashrc actualizado"
else
    log_ok ".bashrc ya estaba configurado"
fi

# Recargar el archivo .bashrc
source "$BASHRC"

# ========= FINAL =========
log_ok "Configuración completada 🎉"
log_ok "👍 Git Credential Manager activado"
log_ok "🔐 Keychain configurado"
log_ok "▶️ Puedes ejecutar: iniciar-ssh"
log_ok "🔁 Tras reiniciar, SSH estará siempre listo."
log_ok "🎉 Sistema preparado para deploys automáticos 🚀"
echo
echo "➡ Copiá tu clave pública a GitHub:"
echo
echo "   cat ~/.ssh/id_ed25519.pub"
echo
echo "➡ O ejecutá:"
echo "   iniciar-ssh"



