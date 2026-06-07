#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

log "Post-install checks complete."
if command -v solace-refresh-applications >/dev/null 2>&1; then
  solace-refresh-applications || true
fi
log "Log out and back in so Hyprland and user-session services pick up the new config links."
