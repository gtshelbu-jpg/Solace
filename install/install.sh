#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
shopt -s nullglob

usage() {
  cat <<EOF
Usage: install.sh [--dry-run] [--only <packages|configs|services|postinstall>]

Runs the numbered install scripts in $SCRIPT_DIR.
EOF
}

ONLY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --only)
      [[ $# -ge 2 ]] || die "--only requires a value"
      ONLY="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

SCRIPTS=("$SCRIPT_DIR"/[0-9][0-9]-*.sh)

if [[ ${#SCRIPTS[@]} -eq 0 ]]; then
  die "No numbered install scripts found in $SCRIPT_DIR"
fi

for s in "${SCRIPTS[@]}"; do
  [[ -f "$s" ]] || continue
  name="$(basename "$s")"
  if [[ -n "$ONLY" ]]; then
    case "$ONLY" in
      packages) [[ "$name" == 10-* ]] || continue;;
      configs)  [[ "$name" == 20-* ]] || continue;;
      services) [[ "$name" == 30-* ]] || continue;;
      postinstall) [[ "$name" == 40-* ]] || continue;;
      *) die "Unknown --only value: $ONLY";;
    esac
  fi
  log "Running $name"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    bash "$s" --dry-run
  else
    bash "$s"
  fi
done

log "Install run complete"
