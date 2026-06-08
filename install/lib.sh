#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
BACKUP_DIR="${BACKUP_DIR:-}"
SOLACE_INSTALL_VERBOSE="${SOLACE_INSTALL_VERBOSE:-0}"

if [[ -t 2 && "${NO_COLOR:-}" == "" ]]; then
  COLOR_RESET=$'\033[0m'
  COLOR_BOLD=$'\033[1m'
  COLOR_DIM=$'\033[2m'
  COLOR_BLUE=$'\033[34m'
  COLOR_GREEN=$'\033[32m'
  COLOR_YELLOW=$'\033[33m'
  COLOR_RED=$'\033[31m'
else
  COLOR_RESET=""
  COLOR_BOLD=""
  COLOR_DIM=""
  COLOR_BLUE=""
  COLOR_GREEN=""
  COLOR_YELLOW=""
  COLOR_RED=""
fi

is_routine_log() {
  case "$1" in
    "DRY: would copy "*|"DRY: would link "*|"DRY: chmod +x "*|"DRY: fc-cache "*|"DRY: would remove boot/storage helper "*)
      return 0
      ;;
    "Copied "*|"Linked "*|"Skipping boot/storage helper: "*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

log() {
  local msg="$*"

  if [[ "$SOLACE_INSTALL_VERBOSE" != "1" ]] && is_routine_log "$msg"; then
    return 0
  fi

  case "$msg" in
    DRY:*) printf '%s%s%s\n' "$COLOR_DIM" "$msg" "$COLOR_RESET" >&2 ;;
    WARN:*) printf '%s%s%s\n' "$COLOR_YELLOW" "$msg" "$COLOR_RESET" >&2 ;;
    ERROR:*) printf '%s%s%s\n' "$COLOR_RED" "$msg" "$COLOR_RESET" >&2 ;;
    +*) printf '%s%s%s\n' "$COLOR_DIM" "$msg" "$COLOR_RESET" >&2 ;;
    *) printf '%s\n' "$msg" >&2 ;;
  esac
}

section() {
  printf '\n%s%s%s\n' "$COLOR_BOLD$COLOR_BLUE" "$*" "$COLOR_RESET" >&2
}

success() {
  printf '%s%s%s\n' "$COLOR_GREEN" "$*" "$COLOR_RESET" >&2
}

warn() { log "WARN: $*"; }
die() { log "ERROR: $*"; exit 1; }

timestamp() { date -u +%Y%m%dT%H%M%SZ; }

ensure_backup_dir() {
  if [[ -z "$BACKUP_DIR" ]]; then
    BACKUP_DIR="$HOME/.config-backups/solace-$(timestamp)"
    mkdir -p "$BACKUP_DIR"
  fi
}

backup_target() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0

  ensure_backup_dir

  local rel_path="$target"
  if [[ "$target" == "$HOME/"* ]]; then
    rel_path="${target#"$HOME/"}"
  else
    rel_path="${target#/}"
  fi

  local backup_path="$BACKUP_DIR/$rel_path"
  mkdir -p "$(dirname "$backup_path")"
  log "Backing up $target -> $backup_path"
  cp -a -- "$target" "$backup_path"
}

run_cmd() {
  local display="$*"
  if (( ${#display} > 160 )); then
    display="$1"
    [[ $# -ge 2 ]] && display+=" $2"
    [[ $# -ge 3 ]] && display+=" $3"
    display+=" ... ($# args)"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: $display"
    return 0
  fi

  log "+ $display"
  "$@"
}

safe_link() {
  local src="$1" dest="$2"
  [[ -e "$src" || -L "$src" ]] || die "Source not found: $src"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would link $src -> $dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    backup_target "$dest"
    rm -rf -- "$dest"
  fi

  local relative_src
  relative_src="$(realpath --relative-to="$(dirname "$dest")" "$src")"
  ln -s "$relative_src" "$dest"
  log "Linked $dest -> $src"
}

safe_copy() {
  local src="$1" dest="$2"
  [[ -e "$src" || -L "$src" ]] || die "Source not found: $src"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would copy $src -> $dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    backup_target "$dest"
    rm -rf -- "$dest"
  fi

  cp -a -- "$src" "$dest"
  log "Copied $src -> $dest"
}

install_executable() {
  local src="$1" dest="$2"
  safe_copy "$src" "$dest"

  if [[ "$DRY_RUN" -eq 0 ]]; then
    chmod +x "$dest" || true
  else
    log "DRY: chmod +x $dest"
  fi
}

read_list_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  grep -E -v '^[[:space:]]*($|#)' "$file" | sed 's/[[:space:]]*$//'
}
