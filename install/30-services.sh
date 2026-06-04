#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

SYSTEM_SERVICES=("NetworkManager.service")

for service_name in "${SYSTEM_SERVICES[@]}"; do
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo systemctl enable --now $service_name"
  else
    run_cmd sudo systemctl enable --now "$service_name"
  fi
done

log "System services configured; user-session audio and portal services are handled by the desktop session."
