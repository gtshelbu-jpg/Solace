#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

CONFIG_ROOT="$SCRIPT_DIR/../config"
SNAPSHOT_ROOT="$SCRIPT_DIR/../Thinkpad"
CONFIG_HOME="$HOME/.config"
LOCAL_SHARE_HOME="$HOME/.local/share/solace"
BIN_HOME="$HOME/.local/bin"

shopt -s nullglob

if [[ ! -d "$CONFIG_ROOT" ]]; then
  log "No config/ directory found; skipping"
  exit 0
fi

log "Installing configs from $CONFIG_ROOT"

install_directory_contents() {
  local src_dir="$1"
  local dest_dir="$2"
  local mode="${3:-link}"

  [[ -d "$src_dir" ]] || return 0

  local entries=("$src_dir"/*)
  if [[ ${#entries[@]} -eq 0 ]]; then
    log "Skipping empty directory: $src_dir"
    return 0
  fi

  for src in "${entries[@]}"; do
    [[ -e "$src" || -L "$src" ]] || continue
    if [[ "$mode" == "copy" ]]; then
      safe_copy "$src" "$dest_dir/$(basename "$src")"
    else
      safe_link "$src" "$dest_dir/$(basename "$src")"
    fi
  done
}

install_terminal_configs() {
  local src_dir="$CONFIG_ROOT/terminal"
  [[ -d "$src_dir" ]] || return 0

  local src
  for src in "$src_dir"/*; do
    [[ -e "$src" || -L "$src" ]] || continue
    case "$(basename "$src")" in
      alacritty.toml)
        safe_link "$src" "$CONFIG_HOME/alacritty/alacritty.toml"
        ;;
      kitty.conf)
        safe_link "$src" "$CONFIG_HOME/kitty/kitty.conf"
        ;;
      *)
        safe_link "$src" "$CONFIG_HOME/terminal/$(basename "$src")"
        ;;
    esac
  done
}

install_notification_configs() {
  local src_dir="$CONFIG_ROOT/notifications"
  [[ -d "$src_dir" ]] || return 0

  local src
  for src in "$src_dir"/*; do
    [[ -e "$src" || -L "$src" ]] || continue
    case "$(basename "$src")" in
      mako.ini)
        safe_link "$src" "$CONFIG_HOME/mako/config"
        ;;
      *)
        safe_link "$src" "$CONFIG_HOME/notifications/$(basename "$src")"
        ;;
    esac
  done
}

install_script_helpers() {
  local src_dir="$CONFIG_ROOT/scripts"
  [[ -d "$src_dir" ]] || return 0

  local helper
  for helper in "$src_dir"/*; do
    [[ -e "$helper" || -L "$helper" ]] || continue
    install_executable "$helper" "$BIN_HOME/$(basename "$helper")"
  done
}

install_snapshot_tree() {
  local src_dir="$1"
  local dest_dir="$2"

  [[ -d "$src_dir" ]] || return 0

  local entries=("$src_dir"/*)
  if [[ ${#entries[@]} -eq 0 ]]; then
    log "Skipping empty snapshot tree: $src_dir"
    return 0
  fi

  for src in "${entries[@]}"; do
    [[ -e "$src" || -L "$src" ]] || continue
    safe_copy "$src" "$dest_dir/$(basename "$src")"
  done
}

install_directory_contents "$CONFIG_ROOT/hypr" "$CONFIG_HOME/hypr"
install_directory_contents "$CONFIG_ROOT/waybar" "$CONFIG_HOME/waybar"
install_directory_contents "$CONFIG_ROOT/launcher" "$CONFIG_HOME/launcher"
install_directory_contents "$CONFIG_ROOT/shell" "$CONFIG_HOME/shell"
install_directory_contents "$CONFIG_ROOT/themes" "$LOCAL_SHARE_HOME/themes" copy
install_terminal_configs
install_notification_configs
install_script_helpers

log "Overlaying Thinkpad snapshot config trees"
install_snapshot_tree "$SNAPSHOT_ROOT/config" "$CONFIG_HOME"
install_snapshot_tree "$SNAPSHOT_ROOT/local/share/solace" "$LOCAL_SHARE_HOME"

log "Configs installed (or simulated in dry-run)"
