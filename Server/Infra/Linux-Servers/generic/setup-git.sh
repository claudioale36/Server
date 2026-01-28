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

# Clave personalizada por usuario GitHub
SSH_KEY="$SSH_DIR/id_ed25519_$GH_USER"

if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t ed25519 -C "$GH_EMAIL" -f "$SSH_KEY" -N ""
    log_ok "Clave SSH creada"
else
    log_ok "Clave SSH ya existe"
fi

# ========= SSH CONFIG =========
log_step "Configurando SSH para usar puerto 443"

SSH_CONFIG="$SSH_DIR/config"

# Añadir configuración si no existe
if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
cat >> "$SSH_CONFIG" << EOF
Host github.com
  HostName ssh.github.com
  Port 443
  User git
  IdentityFile $SSH_KEY
EOF
    log_ok "SSH configurado para GitHub por puerto 443"
else
    log_warn "SSH ya tiene configuración para GitHub"
fi

chmod 600 "$SSH_CONFIG"


# ========= SCRIPT iniciar-ssh =========
log_step "Creando comando iniciar-ssh"

sudo tee /usr/local/bin/iniciar-ssh >/dev/null << 'EOF'
#!/bin/bash
echo "🔐 Cargando todas las claves SSH con keychain..."

SSH_DIR="$HOME/.ssh"

# Buscar todas las claves id_ed25519* (excepto .pub)
for KEY in "$SSH_DIR"/id_ed25519*; do
    [[ $KEY == *.pub ]] && continue
    keychain --quiet --eval "$KEY"
done

# Cargar keychain
KEYCHAIN_FILE="$HOME/.keychain/$(hostname)-sh"
[ -f "$KEYCHAIN_FILE" ] && source "$KEYCHAIN_FILE" 2>/dev/null

echo "SSH Agent listo. Claves cargadas:"
ssh-add -l
EOF

sudo chmod +x /usr/local/bin/iniciar-ssh
log_ok "Comando iniciar-ssh creado (carga automática de todas las claves)"

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



