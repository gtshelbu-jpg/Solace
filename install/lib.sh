#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
BACKUP_DIR="${BACKUP_DIR:-}"

log() { printf '%s\n' "$*" >&2; }
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
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: $*"
    return 0
  fi

  log "+ $*"
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
