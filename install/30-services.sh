#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=1
fi

SERVICES=("NetworkManager" "pipewire" "wireplumber")

for s in "${SERVICES[@]}"; do
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: systemctl enable --now $s"
  else
    run_cmd sudo systemctl enable --now "$s"
  fi
done
