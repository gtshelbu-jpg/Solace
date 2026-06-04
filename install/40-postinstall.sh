#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=1
fi

log "Post-install placeholder: add user tweaks here"
