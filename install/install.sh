#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
shopt -s nullglob

usage() {
  cat <<EOF
Usage: install.sh [--dry-run] [--only <packages|configs|services|login|postinstall>]

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

SUDO_KEEPALIVE_PID=""

start_sudo_session() {
  [[ "$DRY_RUN" -eq 0 ]] || return 0
  [[ "${EUID:-$(id -u)}" -ne 0 ]] || return 0

  log "Requesting sudo up front to reduce password prompts during the install"
  log "Some later steps may still ask for your password; keep this terminal nearby."
  sudo -v

  while true; do
    sleep 60
    sudo -n -v 2>/dev/null || exit 0
  done &
  SUDO_KEEPALIVE_PID="$!"

  trap '[[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

start_sudo_session

for s in "${SCRIPTS[@]}"; do
  [[ -f "$s" ]] || continue
  name="$(basename "$s")"
  if [[ -n "$ONLY" ]]; then
    case "$ONLY" in
      packages) [[ "$name" == 10-* ]] || continue;;
      configs)  [[ "$name" == 20-* ]] || continue;;
      services) [[ "$name" == 30-* ]] || continue;;
      login) [[ "$name" == 35-* ]] || continue;;
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
