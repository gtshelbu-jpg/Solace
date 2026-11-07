#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
shopt -s nullglob

usage() {
  cat <<EOF
Usage: install.sh [options]

  --dry-run                 Preview without changes or prompts
  --only STAGE              packages|configs|services|login|boot|postinstall
  --lid-policy POLICY       docked|suspend|awake|keep (asked before installation)
  --with GROUP              apps|development|displaylink|security|sdr|gaming (repeatable)
  --tablet | --no-tablet     Optional drawing tablet support
  --replace-configs         Back up and replace existing user configs (default: preserve)
  --boot-visuals            Opt in to boot/Plymouth changes (default: skip)
  --bash-prompt             Enable Starship in existing Bash config, with backup
  --bash-defaults           Integrate shared Bash defaults before personal overrides

Runs the numbered install scripts in $SCRIPT_DIR.
EOF
}

ONLY=""
TABLET_CHOICE="${SOLACE_INSTALL_TABLET_SUPPORT:-}"
export SOLACE_LID_POLICY="${SOLACE_LID_POLICY:-}"
export SOLACE_PACKAGE_GROUPS="${SOLACE_PACKAGE_GROUPS:-}"
export SOLACE_REPLACE_CONFIGS=0
export SOLACE_BOOT_VISUALS=0
export SOLACE_BASH_PROMPT=0
export SOLACE_BASH_DEFAULTS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --tablet) TABLET_CHOICE=1; shift;;
    --no-tablet) TABLET_CHOICE=0; shift;;
    --replace-configs) SOLACE_REPLACE_CONFIGS=1; shift;;
    --boot-visuals) SOLACE_BOOT_VISUALS=1; shift;;
    --bash-prompt) SOLACE_BASH_PROMPT=1; shift;;
    --bash-defaults) SOLACE_BASH_DEFAULTS=1; shift;;
    --lid-policy)
      [[ $# -ge 2 ]] || die "--lid-policy requires a value"
      SOLACE_LID_POLICY="$2"; shift 2;;
    --with)
      [[ $# -ge 2 ]] || die "--with requires a group"
      case "$2" in
        apps|development|displaylink|security|sdr|gaming) ;;
        *) die "Unknown package group: $2";;
      esac
      SOLACE_PACKAGE_GROUPS+=" $2"; shift 2;;
    --only)
      [[ $# -ge 2 ]] || die "--only requires a value"
      ONLY="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

case "$ONLY" in
  ""|packages|configs|services|login|boot|postinstall) ;;
  *) die "Unknown --only value: $ONLY";;
esac
if [[ $DRY_RUN -eq 0 ]]; then
  [[ $EUID -ne 0 ]] || die "Run as your regular user, not root or sudo."
  [[ -f /etc/arch-release ]] || die "Solace requires an installed Arch Linux system."
fi

ask_lid_policy() {
  if [[ -z $SOLACE_LID_POLICY ]]; then
    if [[ $DRY_RUN -eq 1 || ( -n $ONLY && $ONLY != "services" ) ]]; then
      SOLACE_LID_POLICY=keep
    elif [[ -t 0 ]]; then
      printf '\nLid-close behavior (applies after reboot):\n' >&2
      printf '  docked  Suspend undocked; stay running with external displays\n  suspend Always suspend\n  awake   Stay running; blank only the laptop panel\n  keep    Leave existing system lid policy alone\n' >&2
      read -r -p 'Choose [docked/suspend/awake/keep] (default docked): ' SOLACE_LID_POLICY
      SOLACE_LID_POLICY="${SOLACE_LID_POLICY:-docked}"
    else
      die "Non-interactive install requires --lid-policy docked|suspend|awake|keep"
    fi
  fi
  case "$SOLACE_LID_POLICY" in
    docked|suspend|awake|keep) ;;
    *) die "Unknown lid policy: $SOLACE_LID_POLICY";;
  esac
}

ask_tablet_support() {
  if [[ -n $ONLY && $ONLY != "packages" ]]; then
    export SOLACE_INSTALL_TABLET_SUPPORT="${TABLET_CHOICE:-0}"
    return 0
  fi
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

ask_lid_policy
ask_tablet_support
export DRY_RUN
export BACKUP_DIR="${BACKUP_DIR:-$HOME/.config-backups/solace-$(timestamp)-$$}"

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

section "Solace installer"
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run: no system changes will be made."
fi
if [[ "$SOLACE_INSTALL_VERBOSE" != "1" ]]; then
  log "Routine file-copy output is hidden. Set SOLACE_INSTALL_VERBOSE=1 for full detail."
fi

for s in "${SCRIPTS[@]}"; do
  [[ -f "$s" ]] || continue
  name="$(basename "$s")"
  if [[ $name == 36-* && $SOLACE_BOOT_VISUALS != "1" ]]; then
    log "Skipping boot changes; opt in explicitly with --boot-visuals."
    continue
  fi
  if [[ -n "$ONLY" ]]; then
    case "$ONLY" in
      packages) [[ "$name" == 10-* ]] || continue;;
      configs)  [[ "$name" == 20-* ]] || continue;;
      services) [[ "$name" == 30-* || "$name" == 31-* ]] || continue;;
      login) [[ "$name" == 35-* ]] || continue;;
      boot) [[ "$name" == 36-* ]] || continue;;
      postinstall) [[ "$name" == 40-* ]] || continue;;
      *) die "Unknown --only value: $ONLY";;
    esac
  fi
  section "$name"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    bash "$s" --dry-run
  else
    bash "$s"
  fi
done

success "Install run complete."
