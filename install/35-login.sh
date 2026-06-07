#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

LOGIN_CONFIG_ROOT="$SCRIPT_DIR/../config/login"
SNAPSHOT_DEFAULT_ROOT="$SCRIPT_DIR/../Thinkpad/local/share/solace/default"
LOGIN_USER="${SUDO_USER:-${USER:-}}"
if [[ -z "$LOGIN_USER" || "$LOGIN_USER" == "root" ]]; then
  LOGIN_USER="$(logname 2>/dev/null || true)"
fi
LOGIN_HOME=""
if [[ -n "$LOGIN_USER" ]]; then
  LOGIN_HOME="$(getent passwd "$LOGIN_USER" | cut -d: -f6 || true)"
fi

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

install_default_keyring() {
  [[ -n "$LOGIN_USER" && "$LOGIN_USER" != "root" && -n "$LOGIN_HOME" ]] || die "Could not determine non-root home for default keyring"

  local keyring_dir="$LOGIN_HOME/.local/share/keyrings"
  local keyring_file="$keyring_dir/Default_keyring.keyring"
  local default_file="$keyring_dir/default"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would create passwordless default keyring in $keyring_dir"
    return 0
  fi

  mkdir -p "$keyring_dir"

  cat > "$keyring_file" <<EOF
[keyring]
display-name=Default keyring
ctime=$(date +%s)
mtime=0
lock-on-idle=false
lock-after=false
EOF

  printf 'Default_keyring\n' > "$default_file"

  chmod 700 "$keyring_dir"
  chmod 600 "$keyring_file"
  chmod 644 "$default_file"
  chown -R "$LOGIN_USER:$LOGIN_USER" "$keyring_dir" 2>/dev/null || true
}

remove_sddm_password_keyring_pam() {
  local pam_file="/etc/pam.d/sddm"

  [[ -f "$pam_file" ]] || { warn "No $pam_file found; skipping SDDM PAM keyring cleanup"; return 0; }

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would remove gnome-keyring password-login hooks from $pam_file"
    return 0
  fi

  backup_target "$pam_file"
  run_cmd sudo sed -i '/-auth.*pam_gnome_keyring\.so/d' "$pam_file"
  run_cmd sudo sed -i '/-password.*pam_gnome_keyring\.so/d' "$pam_file"
}

log "Installing graphical login support"
install_default_keyring
install_wayland_session
install_sddm_wayland_config
remove_sddm_password_keyring_pam
enable_login_manager

log "Login flow configured: graphical login via SDDM, Hyprland session via Solace"
