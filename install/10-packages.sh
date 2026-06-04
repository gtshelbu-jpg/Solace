#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PKG_FILE="$SCRIPT_DIR/../packages/pacman.txt"
AUR_FILE="$SCRIPT_DIR/../packages/aur.txt"

if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=1
fi

if [[ ! -f "$PKG_FILE" ]]; then
  log "No $PKG_FILE found; skipping package installation"
  exit 0
fi

log "Installing official packages from $PKG_FILE"
if [[ "$DRY_RUN" -eq 1 ]]; then
  while read -r p; do [[ -z "$p" || "$p" =~ ^# ]] && continue; log "DRY: pacman -S --needed --noconfirm $p"; done < "$PKG_FILE"
else
  sudo pacman -Syu --noconfirm
  sudo pacman -S --needed --noconfirm - < <(grep -E -v '^\s*#' "$PKG_FILE" | sed '/^\s*$/d')
fi

if [[ -f "$AUR_FILE" ]]; then
  log "AUR packages listed in $AUR_FILE (requires an AUR helper like paru or yay)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    while read -r p; do [[ -z "$p" || "$p" =~ ^# ]] && continue; log "DRY: aur install $p"; done < "$AUR_FILE"
  else
    if command -v paru >/dev/null 2>&1; then
      log "Installing AUR packages with paru"
      paru -S --noconfirm --needed $(grep -E -v '^\s*#' "$AUR_FILE" | sed '/^\s*$/d' | tr '\n' ' ')
    elif command -v yay >/dev/null 2>&1; then
      log "Installing AUR packages with yay"
      yay -S --noconfirm --needed $(grep -E -v '^\s*#' "$AUR_FILE" | sed '/^\s*$/d' | tr '\n' ' ')
    else
      log "No AUR helper found; listing packages to install manually:"
      grep -E -v '^\s*#' "$AUR_FILE" || true
    fi
  fi
fi
