#!/usr/bin/env bash

install_xfce() {
  log "🖥️ Instalando XFCE sin display manager..."
  apt_install_safe xfce4 xfce4-goodies xfce4-terminal xauth dbus-x11 x11-xserver-utils

  local user_home
  user_home=$(eval echo "~$TARGET_USER")
  echo "exec startxfce4" > "${user_home}/.xsession"
  chown "$TARGET_USER:$TARGET_USER" "${user_home}/.xsession"
  chmod +x "${user_home}/.xsession"
}
