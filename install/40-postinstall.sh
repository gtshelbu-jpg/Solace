#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

log "Checking installed desktop configuration without resetting user preferences."
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "DRY: would verify required desktop configs, theme outputs and wallpaper"
  log "DRY: log out and back in so Hyprland and user-session services pick up the new config links"
  exit 0
fi

for required in \
  hypr/hyprland.conf \
  hypr/hypridle.conf \
  hypr/hyprlock.conf \
  solace/current/theme.name \
  solace/current/theme/gum.env.conf \
  solace/current/theme/gtk.css \
  solace/current/background
do
  [[ -f "$HOME/.config/$required" ]] || die "Missing desktop configuration: ~/.config/$required"
done
log "Keyrings, MIME preferences and existing application settings were not refreshed or reset."
log "Log out and back in so Hyprland and user-session services pick up the new config links."
