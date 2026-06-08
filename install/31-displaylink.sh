#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

log "Configuring DisplayLink support"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "DRY: would install /etc/modules-load.d/evdi.conf"
  log "DRY: would run sudo systemctl daemon-reload"
  log "DRY: would enable and start displaylink.service when available"
  exit 0
fi

printf 'evdi\n' | run_cmd sudo tee /etc/modules-load.d/evdi.conf >/dev/null
run_cmd sudo systemctl daemon-reload

if systemctl list-unit-files --type=service --no-legend displaylink.service 2>/dev/null | grep -q '^displaylink\.service'; then
  run_cmd sudo systemctl enable --now displaylink.service
else
  warn "displaylink.service was not found. Check that AUR packages evdi-dkms and displaylink installed successfully."
fi

if command -v modprobe >/dev/null 2>&1; then
  run_cmd sudo modprobe evdi || warn "Could not load evdi immediately; it should load on next boot if DKMS built successfully."
fi
