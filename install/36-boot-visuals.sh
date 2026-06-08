#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

REPO_ROOT="$SCRIPT_DIR/.."
PLYMOUTH_SRC="$REPO_ROOT/Thinkpad/local/share/solace/default/plymouth"
LIMINE_SRC="$REPO_ROOT/Thinkpad/local/share/solace/default/limine"

install_plymouth_theme() {
  [[ -d "$PLYMOUTH_SRC" ]] || { warn "Missing Plymouth theme source: $PLYMOUTH_SRC"; return 0; }

  log "Installing Solace Plymouth theme"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would install $PLYMOUTH_SRC -> /usr/share/plymouth/themes/solace"
    log "DRY: would set Plymouth theme to solace"
    log "DRY: would install /etc/mkinitcpio.conf.d/solace_hooks.conf"
    return 0
  fi

  run_cmd sudo rm -rf /usr/share/plymouth/themes/solace
  run_cmd sudo install -d -m 0755 /usr/share/plymouth/themes
  run_cmd sudo cp -a "$PLYMOUTH_SRC" /usr/share/plymouth/themes/solace
  run_cmd sudo plymouth-set-default-theme solace
  run_cmd sudo install -d -m 0755 /etc/mkinitcpio.conf.d
  cat <<'EOF' | run_cmd sudo tee /etc/mkinitcpio.conf.d/solace_hooks.conf >/dev/null
HOOKS=(base udev plymouth autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
EOF
}

find_limine_config() {
  local candidate
  for candidate in \
    /boot/limine/limine.conf \
    /boot/limine.conf \
    /boot/EFI/arch-limine/limine.conf \
    /boot/EFI/BOOT/limine.conf \
    /boot/EFI/limine/limine.conf; do
    [[ -f "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  done
  return 1
}

install_limine_theme() {
  [[ -d "$LIMINE_SRC" ]] || { warn "Missing Limine theme source: $LIMINE_SRC"; return 0; }

  local limine_config=""
  limine_config="$(find_limine_config || true)"
  if [[ -z "$limine_config" ]]; then
    warn "No Limine config found; skipping Limine theme"
    return 0
  fi

  log "Installing Solace Limine theme"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would back up and replace $limine_config"
    log "DRY: would install Solace UKI splash bitmap"
    log "DRY: would patch mkinitcpio presets with --splash"
    log "DRY: would rebuild initramfs/UKIs"
    return 0
  fi

  backup_target "$limine_config"
  run_cmd sudo cp "$LIMINE_SRC/limine.conf" "$limine_config"
  run_cmd sudo install -Dm644 "$LIMINE_SRC/splash-solace.bmp" /usr/share/systemd/bootctl/splash-solace.bmp

  local preset
  for preset in /etc/mkinitcpio.d/*.preset; do
    [[ -f "$preset" ]] || continue
    if grep -q '^default_options=' "$preset"; then
      run_cmd sudo sed -i 's|^default_options=.*|default_options="--splash /usr/share/systemd/bootctl/splash-solace.bmp"|' "$preset"
    else
      run_cmd sudo sed -i '/^default_uki=/a default_options="--splash /usr/share/systemd/bootctl/splash-solace.bmp"' "$preset"
    fi
  done
}

rebuild_boot_images() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  if command -v limine-mkinitcpio >/dev/null 2>&1; then
    run_cmd sudo limine-mkinitcpio
  else
    run_cmd sudo mkinitcpio -P
  fi

  if command -v limine-update >/dev/null 2>&1; then
    run_cmd sudo limine-update
  fi
  if command -v limine-snapper-sync >/dev/null 2>&1; then
    run_cmd sudo limine-snapper-sync
  fi
}

install_plymouth_theme
install_limine_theme
rebuild_boot_images

log "Boot visuals configured where supported."
