#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

LOGIN_CONFIG_ROOT="$SCRIPT_DIR/../config/login"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"

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

  [[ -f "$src" ]] || die "Missing SDDM config: $src"
  [[ -f "$greeter_src" ]] || die "Missing SDDM greeter config: $greeter_src"

  install_login_file "$src" "$dest"
  install_login_file "$greeter_src" "$greeter_dest"
}

set_plymouth_theme() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo plymouth-set-default-theme -R ecorp-glitch"
    return 0
  fi

  run_cmd sudo plymouth-set-default-theme -R ecorp-glitch
}

ensure_plymouth_hook() {
  [[ -f "$MKINITCPIO_CONF" ]] || { warn "No $MKINITCPIO_CONF found; skipping Plymouth hook update"; return 0; }

  if grep -Eq '^[[:space:]]*HOOKS=.*plymouth' "$MKINITCPIO_CONF"; then
    log "Plymouth hook already present in $MKINITCPIO_CONF"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would back up and update $MKINITCPIO_CONF to add the plymouth hook"
    return 0
  fi

  backup_target "$MKINITCPIO_CONF"

  run_cmd sudo python3 - "$MKINITCPIO_CONF" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()

pattern = re.compile(r'^(HOOKS=\()([^\n]*?\budev\b)([^\n]*?\))$', re.MULTILINE)

def repl(match: re.Match[str]) -> str:
    prefix = match.group(1)
    before = match.group(2)
    after = match.group(3)
    if 'plymouth' in before or 'plymouth' in after:
      return match.group(0)
    return f"{prefix}{before} plymouth{after}"

new_text, count = pattern.subn(repl, text, count=1)

if count == 0:
    raise SystemExit(f'Could not find a HOOKS line with udev in {path}')

path.write_text(new_text)
PY

  log "Updated Plymouth hook in $MKINITCPIO_CONF"
}

rebuild_initramfs() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo mkinitcpio -P"
  else
    run_cmd sudo mkinitcpio -P
  fi
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

log "Installing graphical login and Plymouth boot support"
install_wayland_session
install_sddm_wayland_config
ensure_plymouth_hook
set_plymouth_theme
rebuild_initramfs
enable_login_manager

log "Login flow configured: boot splash via Plymouth, graphical login via SDDM, Hyprland session via Solace"