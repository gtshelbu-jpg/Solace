#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PKG_FILE="$SCRIPT_DIR/../packages/pacman.txt"
AUR_FILE="$SCRIPT_DIR/../packages/aur.txt"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

if [[ ! -f "$PKG_FILE" ]]; then
  log "No $PKG_FILE found; skipping package installation"
  exit 0
fi

mapfile -t official_packages < <(read_list_file "$PKG_FILE")
mapfile -t aur_packages < <(read_list_file "$AUR_FILE")

if [[ ${#official_packages[@]} -gt 0 ]]; then
  log "Installing official packages from $PKG_FILE"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo pacman -Syu --noconfirm"
    log "DRY: sudo pacman -S --needed --noconfirm ${official_packages[*]}"
  else
    run_cmd sudo pacman -Syu --noconfirm
    run_cmd sudo pacman -S --needed --noconfirm "${official_packages[@]}"
  fi
else
  log "No official packages listed in $PKG_FILE"
fi

bootstrap_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  log "Bootstrapping yay from the AUR"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo pacman -S --needed --noconfirm git base-devel"
    log "DRY: git clone https://aur.archlinux.org/yay.git /tmp/yay"
    log "DRY: (cd /tmp/yay && makepkg -si --noconfirm)"
    return 0
  fi

  run_cmd sudo pacman -S --needed --noconfirm git base-devel

  workdir="$(mktemp -d)"
  run_cmd git clone https://aur.archlinux.org/yay.git "$workdir/yay"
  (
    cd "$workdir/yay"
    makepkg -si --noconfirm
  )
  rm -rf -- "$workdir"
}

if [[ ${#aur_packages[@]} -gt 0 ]]; then
  log "AUR packages listed in $AUR_FILE"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: AUR install ${aur_packages[*]}"
  else
    if command -v paru >/dev/null 2>&1; then
      log "Installing AUR packages with paru"
      run_cmd paru -S --noconfirm --needed "${aur_packages[@]}"
    else
      bootstrap_yay
      if command -v yay >/dev/null 2>&1; then
        log "Installing AUR packages with yay"
        run_cmd yay -S --noconfirm --needed "${aur_packages[@]}"
      else
        die "Unable to install yay helper"
      fi
    fi
  fi
else
  log "No AUR packages listed in $AUR_FILE"
fi
