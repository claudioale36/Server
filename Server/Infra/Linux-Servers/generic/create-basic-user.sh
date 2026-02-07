#!/usr/bin/env bash

if [[ -f .env ]]; then
  source .env
fi

########################
## CONFIGURACIÓN
########################
TARGET_USER="${TARGET_USER:-}"

########################
## USUARIO Y LOCALES
########################
detect_target_user() {
  if [[ -n "$TARGET_USER" ]]; then
    log "👤 Usando TARGET_USER=$TARGET_USER"
    return
  fi
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    TARGET_USER="$SUDO_USER"
  else
    TARGET_USER="$(whoami)"
    # Si whoami es root, proponemos 'admin' como usuario no-root
    if [[ "$TARGET_USER" == "root" ]]; then
      TARGET_USER="admin"
    fi
  fi
  log "👤 Usuario objetivo: $TARGET_USER"
}

create_user_if_needed() {
  if id "$TARGET_USER" &>/dev/null; then
    log "✅ Usuario $TARGET_USER ya existe."
  else
    log "👤 Creando usuario $TARGET_USER (sin contraseña inicial, sudo sin password)..."
    adduser --gecos "" --disabled-password "$TARGET_USER"
  fi

  # Sudo sin contraseña para facilitar automatización
  echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-$TARGET_USER-nopasswd
  chmod 440 /etc/sudoers.d/90-$TARGET_USER-nopasswd
}

create_basic_user() {
  local user="${USER_NAME:?ERROR: Falta variable USER_NAME en .env}"
  local password="${USER_PASSWORD:?ERROR: Falta variable USER_PASSWORD en .env}"
  echo "${user}:${password}" | chpasswd
  if ! id "$user" &>/dev/null; then
    log "👤 Creando usuario básico $user..."
    adduser --gecos "" --disabled-password "$user"
    echo "${user}:${pass}" | chpasswd
    # Guardar copia segura local (protejalo, optional)
    echo "Usuario: ${user}" >/root/fipanel-password.txt
    echo "Password: ${password}" >>/root/${user}-password.txt
    chmod 600 /root/${user}-password.txt
  else
    log "✅ Usuario $user ya existe."
  fi
}

########################
## MAIN
########################
main() {

  ./create_basic_user
  ./
}

main "$@"
