#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

LOGIN_CONFIG_ROOT="$SCRIPT_DIR/../config/login"
SNAPSHOT_DEFAULT_ROOT="$SCRIPT_DIR/../Thinkpad/local/share/solace/default"

install_login_file() {
  local src="$1"
  local dest="$2"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would install $src -> $dest"
    return 0
  fi

  backup_target "$dest"
  run_cmd sudo install -Dm644 "$src" "$dest"
}

install_system_tree() {
  local src="$1"
  local dest="$2"

  [[ -d "$src" ]] || die "Missing system tree: $src"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would install tree $src -> $dest"
    return 0
  fi

  backup_target "$dest"
  run_cmd sudo install -d -m 0755 "$dest"
  run_cmd sudo cp -a "$src/." "$dest/"
}

install_wayland_session() {
  local src="$LOGIN_CONFIG_ROOT/wayland-sessions/solace.desktop"
  local dest="/usr/local/share/wayland-sessions/solace.desktop"

  [[ -f "$src" ]] || die "Missing Wayland session definition: $src"
  install_login_file "$src" "$dest"
}

install_sddm_wayland_config() {
  local src="$LOGIN_CONFIG_ROOT/sddm/10-wayland.conf"
  local dest="/etc/sddm.conf.d/10-wayland.conf"
  local greeter_src="$LOGIN_CONFIG_ROOT/sddm/hyprland.conf"
  local greeter_dest="/usr/share/sddm/hyprland.conf"
  local autologin_dest="/etc/sddm.conf.d/autologin.conf"
  local theme_dest="/etc/sddm.conf.d/theme.conf"
  local sddm_theme_src="$SNAPSHOT_DEFAULT_ROOT/sddm/solace"
  local sddm_theme_dest="/usr/share/sddm/themes/solace"

  [[ -f "$src" ]] || die "Missing SDDM config: $src"
  [[ -f "$greeter_src" ]] || die "Missing SDDM greeter config: $greeter_src"
  install_login_file "$src" "$dest"
  install_login_file "$greeter_src" "$greeter_dest"
  install_system_tree "$sddm_theme_src" "$sddm_theme_dest"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would remove SDDM autologin config at $autologin_dest"
    log "DRY: would install SDDM theme config -> $theme_dest"
    return 0
  fi

  run_cmd sudo install -d -m 0755 /etc/sddm.conf.d
  if [[ -e "$autologin_dest" || -L "$autologin_dest" ]]; then
    backup_target "$autologin_dest"
    run_cmd sudo rm -f "$autologin_dest"
  fi
  printf '[Theme]\nCurrent=solace\n' | run_cmd sudo tee "$theme_dest" >/dev/null
}

enable_login_manager() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo systemctl set-default graphical.target"
    log "DRY: sudo systemctl enable sddm.service"
  else
    run_cmd sudo systemctl set-default graphical.target
    run_cmd sudo systemctl enable sddm.service
  fi
}

log "Installing graphical login support"
log "Preserving all keyrings and distribution PAM configuration."
install_wayland_session
install_sddm_wayland_config
enable_login_manager

log "Login flow configured: graphical login via SDDM, Hyprland session via Solace"
