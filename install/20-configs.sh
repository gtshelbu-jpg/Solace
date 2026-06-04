#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=1
fi

CONFIG_ROOT="$SCRIPT_DIR/../config"

if [[ ! -d "$CONFIG_ROOT" ]]; then
  log "No config/ directory found; skipping"
  exit 0
fi

log "Installing configs from $CONFIG_ROOT"

# Example: install hyprland config
if [[ -d "$CONFIG_ROOT/hypr" ]]; then
  for f in "$CONFIG_ROOT/hypr"/*; do
    [[ -f "$f" ]] || continue
    dest="$HOME/.config/hypr/$(basename "$f")"
    link_or_copy "$f" "$dest" link
  done
fi

if [[ -d "$CONFIG_ROOT/waybar" ]]; then
  mkdir -p "$HOME/.config/waybar"
  for f in "$CONFIG_ROOT/waybar"/*; do
    [[ -f "$f" ]] || continue
    link_or_copy "$f" "$HOME/.config/waybar/$(basename "$f")" link
  done
fi

if [[ -d "$CONFIG_ROOT/scripts" ]]; then
  mkdir -p "$HOME/.local/bin"
  for f in "$CONFIG_ROOT/scripts"/*; do
    [[ -f "$f" ]] || continue
    dest="$HOME/.local/bin/$(basename "$f")"
    link_or_copy "$f" "$dest" link
    if [[ "$DRY_RUN" -eq 0 ]]; then
      chmod +x "$dest" || true
    else
      log "DRY: chmod +x $dest"
    fi
  done
fi

log "Configs installed (or simulated in dry-run)"
