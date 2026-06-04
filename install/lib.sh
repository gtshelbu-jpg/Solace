#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
BACKUP_DIR=""

log() { printf "%s\n" "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

timestamp() { date -u +%Y%m%dT%H%M%SZ; }

ensure_backup_dir() {
  if [[ -z "$BACKUP_DIR" ]]; then
    BACKUP_DIR="$HOME/.config-backups/solace-$(timestamp)"
    mkdir -p "$BACKUP_DIR"
  fi
}

backup_file() {
  local src="$1"
  ensure_backup_dir
  if [[ -e "$src" || -L "$src" ]]; then
    local dest="$BACKUP_DIR/$(basename "$src")"
    log "Backing up $src -> $dest"
    cp -a "$src" "$dest"
  fi
}

link_or_copy() {
  local src="$1" dest="$2" mode="${3:-link}"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would install $src -> $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    backup_file "$dest"
    rm -rf "$dest"
  fi
  if [[ "$mode" == "link" ]]; then
    ln -s "$(realpath --relative-to="$(dirname "$dest")" "$src")" "$dest"
    log "Linked $dest -> $src"
  else
    cp -a "$src" "$dest"
    log "Copied $src -> $dest"
  fi
}

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: $*"
  else
    log "+ $*"
    eval "$@"
  fi
}
