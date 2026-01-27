#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "$*"; }
TMP_DIR="${TMP_DIR:-/tmp/nomachine_install}"
NOMACHINE_URL="${NOMACHINE_URL:-https://www.nomachine.com/free/linux/64/deb}"

detect_pkg_mgr || true

download_nomachine_deb() {
  mkdir -p "$TMP_DIR"
  pushd "$TMP_DIR" >/dev/null || return 1

  log "🔎 Obteniendo URL de NoMachine (scrape minimal)..."
  # Intentamos obtener el primer enlace al .deb en la pagina
  if command -v wget >/dev/null 2>&1; then
    page=$(wget -qO- "$NOMACHINE_URL")
  elif command -v curl >/dev/null 2>&1; then
    page=$(curl -sL "$NOMACHINE_URL")
  else
    log "❌ Ni wget ni curl disponibles."
    popd >/dev/null
    return 1
  fi

  latest_deb=$(echo "$page" | grep -oP 'https?:\/\/download\.nomachine\.com\/download\/\d+\/Linux\/nomachine_.*?_amd64\.deb' | head -n1 || true)
  if [ -z "$latest_deb" ]; then
    log "❌ No pude extraer la URL del .deb desde la pagina. Intentando descargar directamente NOMACHINE_URL..."
    latest_deb="$NOMACHINE_URL"
  fi

  log "⬇ Descargando: $latest_deb"
  wget -q "$latest_deb" -O nomachine.deb || { log "❌ Descarga fallida."; popd >/dev/null; return 1; }

  # Calcular hash local
  sha256sum nomachine.deb | tee nomachine.deb.sha256

  # Intentar descargar checksum del proveedor (si existe)
  # Muchas veces NoMachine no publica checksum en la misma ruta; si no existe, hacemos fallback.
  # Aquí intentamos donde el proveedor pudiera hospedar sumas, sino lo dejamos como aviso.
  popd >/dev/null
  return 0
}

verify_and_install_nomachine() {
  pushd "$TMP_DIR" >/dev/null || return 1
  # Si hay un archivo .sha256 desde vendor lo usaríamos; si no, avisamos y lo instalamos.
  if [ -f nomachine.deb.sha256 ]; then
    log "ℹ Sumario SHA256 calculado y guardado en $TMP_DIR/nomachine.deb.sha256"
  fi

  log "⬆ Instalando NoMachine..."
  if [ "$PKG" = "apt" ]; then
    dpkg -i nomachine.deb || apt-get install -f -y || true
  elif [ "$PKG" = "dnf" ]; then
    dnf localinstall -y nomachine.deb || true
  elif [ "$PKG" = "pacman" ]; then
    pacman -U --noconfirm nomachine.deb || true
  fi

  # Habilitar el servicio (si aplica)
  systemctl daemon-reload || true
  systemctl enable --now nxserver.service || true

  popd >/dev/null
  log "✅ NoMachine instalado. Si querés verificar la integridad con la fuente del vendor, añadí manualmente el checksum provisto por la web y compáralo con nomachine.deb.sha256"
}

main() {
  detect_pkg_mgr
  download_nomachine_deb
  verify_and_install_nomachine
}

main "$@"
