# --- package manager detection ---
detect_pkg_mgr() {
  PKG=""
  PKG_INSTALL=""
  PKG_UPDATE=""
  PKG_UPGRADE=""
  PKG_REMOVE=""

  if command -v apt-get >/dev/null 2>&1; then
    PKG="apt"
    PKG_INSTALL="apt-get install -y"
    PKG_UPDATE="apt-get update -y"
    PKG_UPGRADE="apt-get upgrade -y"
    PKG_REMOVE="apt-get remove -y"
  elif command -v dnf >/dev/null 2>&1; then
    PKG="dnf"
    PKG_INSTALL="dnf install -y"
    PKG_UPDATE="dnf makecache --refresh -y"
    PKG_UPGRADE="dnf upgrade -y"
    PKG_REMOVE="dnf remove -y"
  elif command -v pacman >/dev/null 2>&1; then
    PKG="pacman"
    PKG_INSTALL="pacman -S --noconfirm"
    PKG_UPDATE="pacman -Sy"
    PKG_UPGRADE="pacman -Syu --noconfirm"
    PKG_REMOVE="pacman -Rns --noconfirm"
  else
    log "❌ Gestor de paquetes no soportado automatico. Edita el script."
    exit 1
  fi

  # Asegurarse de que DISTRO_FAMILY esté correctamente definido
  if [ -z "$DISTRO_FAMILY" ]; then
    log "❌ DISTRO_FAMILY no está definido. Verifica la detección de la distribución."
    exit 1
  fi
}
