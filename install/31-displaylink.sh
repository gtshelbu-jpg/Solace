#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

if ! has_package_group displaylink; then
  log "Skipping optional DisplayLink setup (select --with displaylink)."
  exit 0
fi

log "Configuring optional DisplayLink support"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "DRY: would install /etc/modules-load.d/evdi.conf"
  log "DRY: would run sudo systemctl daemon-reload"
  log "DRY: would enable and start displaylink.service when available"
  exit 0
fi

printf 'evdi\n' | run_cmd sudo tee /etc/modules-load.d/evdi.conf >/dev/null
run_cmd sudo systemctl daemon-reload

if systemctl list-unit-files --type=service --no-legend displaylink.service 2>/dev/null | grep -q '^displaylink\.service'; then
  run_cmd sudo systemctl enable displaylink.service
  if modinfo -k "$(uname -r)" evdi >/dev/null 2>&1; then
    run_cmd sudo modprobe evdi
    run_cmd sudo systemctl start displaylink.service
  else
    warn "EVDI is not built for the running kernel. Reboot into the installed kernel after confirming DKMS completed; DisplayLink is enabled for the next boot."
  fi
else
  warn "displaylink.service was not found. Check that AUR packages evdi-dkms and displaylink installed successfully."
fi
