#!/usr/bin/env bash

############################################
## AVAHI / MDNS PARA server.local
############################################

# Función para registrar el log (puedes personalizarla según cómo quieras registrar logs)
log() {
  echo "$1"
}

# Función para instalar paquetes según la distribución
pkg_install() {
  $PKG_INSTALL "$@" || true
}

# Función para obtener la interfaz de red activa
get_active_interface() {
  # Detectar la interfaz de red que tiene la IP en la red local
  ip -4 route show default | awk '{print $5}'  # Extrae la interfaz de la ruta por defecto
}

# Instalar Avahi y configurarlo
install_avahi() {
  log "📡 Instalando y configurando Avahi (mDNS) para hostname .local..."

  # Detectar la distribución y usar el gestor de paquetes correspondiente
  case "$DISTRO_FAMILY" in
    debian|ubuntu)
      pkg_install avahi-daemon avahi-utils libnss-mdns || true
      ;;
    fedora)
      pkg_install avahi avahi-tools nss-mdns || true
      systemctl enable --now avahi-daemon || true
      ;;
    arch)
      pkg_install avahi nss-mdns || true
      systemctl enable --now avahi-daemon || true
      ;;
    *)
      log "⚠️ Distro no reconocida para instalación automática de Avahi."
      return 0
      ;;
  esac

  # Comprobación del hostname actual
  current_hostname=$(hostname)
  if [[ "$current_hostname" != "server" ]]; then
    log "📝 El hostname actual es '$current_hostname'. Configurando hostname a 'server'..."
    sudo hostnamectl set-hostname server || true
  else
    log "✅ El hostname ya está configurado correctamente como 'server'."
  fi

  # Asegurarse de que Avahi esté corriendo
  systemctl enable --now avahi-daemon 2>/dev/null || true

  # Obtener la interfaz activa
  active_interface=$(get_active_interface)
  log "🌐 Detectada la interfaz activa: $active_interface"

  # Crear y configurar el archivo avahi-daemon.conf si no existe o si es necesario
  if [[ ! -f /etc/avahi/avahi-daemon.conf ]] || ! grep -q "host-name=server" /etc/avahi/avahi-daemon.conf; then
    log "📝 Configurando avahi-daemon.conf para 'server.local'..."

    # Crear el archivo avahi-daemon.conf con el contenido adecuado
    cat <<EOF | sudo tee /etc/avahi/avahi-daemon.conf > /dev/null
[server]
host-name=server
domain-name=local
use-ipv4=yes
use-ipv6=no
enable-dbus=no
allow-interfaces=$active_interface
EOF
    log "✅ Configuración de avahi-daemon.conf realizada."
  fi

  # Verificar que Avahi está corriendo
  systemctl status avahi-daemon | grep "active (running)" &>/dev/null
  if [[ $? -eq 0 ]]; then
    log "✅ Avahi está corriendo correctamente."
  else
    log "⚠️ Hubo un problema al arrancar Avahi."
  fi

  log "✅ Avahi configurado. El servidor responderá como: server.local"

  # Realizar una consulta DNS mDNS para verificar que 'server.local' resuelve correctamente
  log "🔍 Verificando la resolución DNS de 'server.local'..."
  nslookup server.local &>/dev/null
  if [[ $? -eq 0 ]]; then
    log "✅ La consulta DNS para 'server.local' fue exitosa."
  else
    log "⚠️ No se pudo resolver 'server.local'. Asegúrate de que Avahi esté configurado correctamente."
  fi

  # Hacer un ping a 'server.local' para verificar conectividad
  log "🔍 Haciendo ping a 'server.local'..."
  ping -c 3 server.local &>/dev/null
  if [[ $? -eq 0 ]]; then
    log "✅ El ping a 'server.local' fue exitoso."
  else
    log "⚠️ No se pudo hacer ping a 'server.local'. Verifica la configuración de red."
  fi

  log "✅ Avahi configurado. El servidor responderá como: server.local"

  # Verificar las interfaces de red disponibles
  log "🔍 Verificando las interfaces de red disponibles..."
  ip a

  # Verificar la dirección IP de 'server.local' con nslookup
  log "🔍 Verificando la IP de 'server.local'..."
  nslookup server.local

  # Verificar si el servidor responde al ping en la red local
  log "🔍 Haciendo ping a 'server.local'..."
  ping -c 3 server.local &>/dev/null
  if [[ $? -eq 0 ]]; then
    log "✅ El ping a 'server.local' fue exitoso."
  else
    log "⚠️ No se pudo hacer ping a 'server.local'. Verifica la configuración de red o el firewall."
  fi
}

# Detectar la distribución del sistema
detect_distro() {
  # Puedes agregar aquí el código que detecte la distribución para definir DISTRO_FAMILY
  # (esto también podría estar en lib.sh si se desea centralizar)
  if [ -f /etc/os-release ]; then
    DISTRO_FAMILY=$(grep -oP '(?<=^ID=)[^ ]+' /etc/os-release | tr -d '"')
  else
    log "❌ No se pudo detectar la distribución. ¿Está el archivo /etc/os-release disponible?"
    exit 1
  fi
}

# Llamamos a la función de detección de la distribución
detect_distro

# Llamamos a la instalación de Avahi
install_avahi
