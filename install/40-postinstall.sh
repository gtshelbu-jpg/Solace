#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

log "Post-install checks complete."
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "DRY: would refresh application entries, GNOME/GTK theme settings, VS Code theme settings, and Chromium flags"
  log "DRY: log out and back in so Hyprland and user-session services pick up the new config links"
  exit 0
fi

if command -v solace-refresh-applications >/dev/null 2>&1; then
  solace-refresh-applications || true
fi
if command -v solace-theme-set-gnome >/dev/null 2>&1; then
  solace-theme-set-gnome || true
fi
if command -v solace-theme-set-vscode >/dev/null 2>&1; then
  solace-theme-set-vscode || true
fi
if command -v solace-refresh-chromium >/dev/null 2>&1; then
  solace-refresh-chromium || true
fi
log "Log out and back in so Hyprland and user-session services pick up the new config links."
