#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

log "Post-install checks complete."
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "DRY: would refresh application entries, Walker/Elephant, GNOME/GTK theme settings, VS Code theme settings, and Chromium flags"
  log "DRY: log out and back in so Hyprland and user-session services pick up the new config links"
  exit 0
fi

run_installed_helper() {
  local helper="$1"
  local installed="$HOME/.local/share/solace/bin/$helper"

  if command -v "$helper" >/dev/null 2>&1; then
    "$helper" || true
  elif [[ -x "$installed" ]]; then
    "$installed" || true
  fi
}

run_installed_helper solace-refresh-applications
run_installed_helper solace-refresh-walker
run_installed_helper solace-theme-set-gnome
run_installed_helper solace-theme-set-browser
run_installed_helper solace-theme-set-vscode
run_installed_helper solace-refresh-chromium
log "Log out and back in so Hyprland and user-session services pick up the new config links."
