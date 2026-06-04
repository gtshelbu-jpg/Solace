#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

log "Post-install checks complete."
log "Log out and back in so Hyprland and user-session services pick up the new config links."
log "If Plymouth does not appear, verify /etc/mkinitcpio.conf contains the plymouth hook and your kernel cmdline contains: quiet splash"
