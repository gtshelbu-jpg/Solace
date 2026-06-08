#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
shopt -s nullglob

usage() {
  cat <<EOF
Usage: install.sh [--dry-run] [--tablet|--no-tablet] [--only <packages|configs|services|login|postinstall>]

Runs the numbered install scripts in $SCRIPT_DIR.
EOF
}

ONLY=""
TABLET_CHOICE="${SOLACE_INSTALL_TABLET_SUPPORT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --tablet) TABLET_CHOICE=1; shift;;
    --no-tablet) TABLET_CHOICE=0; shift;;
    --only)
      [[ $# -ge 2 ]] || die "--only requires a value"
      ONLY="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

ask_tablet_support() {
  [[ "$DRY_RUN" -eq 0 ]] || { export SOLACE_INSTALL_TABLET_SUPPORT="${TABLET_CHOICE:-0}"; return 0; }
  [[ -z "$TABLET_CHOICE" ]] || { export SOLACE_INSTALL_TABLET_SUPPORT="$TABLET_CHOICE"; return 0; }

  if command -v gum >/dev/null 2>&1; then
    if gum confirm "Install drawing tablet support?"; then
      TABLET_CHOICE=1
    else
      TABLET_CHOICE=0
    fi
  else
    local answer
    read -r -p "Install drawing tablet support? [y/N] " answer
    case "$answer" in
      [Yy]|[Yy][Ee][Ss]) TABLET_CHOICE=1;;
      *) TABLET_CHOICE=0;;
    esac
  fi

  export SOLACE_INSTALL_TABLET_SUPPORT="$TABLET_CHOICE"
}

ask_tablet_support

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
      services) [[ "$name" == 30-* || "$name" == 31-* ]] || continue;;
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
