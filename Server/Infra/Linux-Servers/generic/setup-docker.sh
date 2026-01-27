#!/bin/bash

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

# Función para mostrar mensajes de log
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Función para instalar Docker desde el repositorio oficial
install_docker() {

  log_step "🐳 Instalando dependencias para Docker..."

  # Instalación de dependencias necesarias
  sudo apt update
  sudo apt install -y ca-certificates curl gnupg lsb-release

  log_step "🐳 Añadir la clave GPG de Docker..."
  # Añadir la clave GPG de Docker
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  log_step "🐳 Añadir el repositorio de Docker..."
  # Añadir el repositorio de Docker
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  log_step "🐳 Instalando Docker desde el repositorio oficial..."
  # Actualizar la lista de paquetes e instalar Docker
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  log_step "✅ Docker instalado con éxito."
}

# Función para configurar Docker (logs y reenvío de IPv4)
configure_docker() {
  log_step "⚙️ Configurando Docker (rotación de logs, IPv4 forward...)"

  # Configuración de la rotación de logs
  sudo mkdir -p /etc/docker
  cat | sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

  log_step "⚙️ Habilitar reenvío de IPv4 (por si es necesario para los contenedores)...)"
  # Habilitar reenvío de IPv4 (por si es necesario para los contenedores)
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo sysctl -p > /dev/null 2>&1

  # Recargar la configuración y reiniciar Docker
  sudo systemctl daemon-reload
  sudo systemctl restart docker

  log_step "✅ Configuración de Docker completada."
}

# Función para asegurar que Docker se inicie al arranque
enable_docker() {
  log_step "🔧 Activando Docker para que se inicie al arranque..."
  sudo systemctl enable docker --now
}

# Función para agregar un usuario al grupo docker
add_user_to_docker_group() {
  TARGET_USER="$1"
  if [ -n "$TARGET_USER" ]; then
    log_step "👥 Agregando al usuario '$TARGET_USER' al grupo docker..."
    sudo usermod -aG docker "$TARGET_USER" || true
  else
    log_error "⚠️ No se especificó un usuario para agregar al grupo docker."
  fi
}

# Función principal para ejecutar el flujo
main() {
  # Verificar si el script se está ejecutando como root
  if [ "$(id -u)" -ne 0 ]; then
    log_error "❌ Este script debe ejecutarse como root."
    exit 1
  fi

  # Instalación de Docker
  install_docker

  # Configuración de Docker
  configure_docker

  # Habilitar Docker para iniciar al arranque
  enable_docker

  docker compose version

  # Agregar un usuario al grupo docker (opcional)
  # Descomentar la siguiente línea si deseas agregar un usuario específico.
  # add_user_to_docker_group "usuario"

  log "🚀 ✅ Docker está listo para usarse."
}

# Ejecutar el script principal
main
