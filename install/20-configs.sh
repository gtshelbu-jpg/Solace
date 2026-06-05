#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

CONFIG_ROOT="$SCRIPT_DIR/../config"
SNAPSHOT_ROOT="$SCRIPT_DIR/../Thinkpad"
SNAPSHOT_CONFIG="$SNAPSHOT_ROOT/config"
SNAPSHOT_SOLACE="$SNAPSHOT_ROOT/local/share/solace"
SNAPSHOT_FONTS="$SNAPSHOT_ROOT/local/share/fonts"
CONFIG_HOME="$HOME/.config"
LOCAL_SHARE_HOME="$HOME/.local/share/solace"
BIN_HOME="$HOME/.local/bin"
FONT_HOME="$HOME/.local/share/fonts"

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

install_snapshot_fonts() {
  local font
  local installed_solace_font=0

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would install bundled fonts into $FONT_HOME"
  fi

  if [[ -d "$SNAPSHOT_FONTS" ]]; then
    for font in "$SNAPSHOT_FONTS"/*.{ttf,otf}; do
      [[ -e "$font" || -L "$font" ]] || continue
      safe_copy "$font" "$FONT_HOME/$(basename "$font")"
      [[ "$(basename "$font")" == "solace.ttf" ]] && installed_solace_font=1
    done
  fi

  if [[ "$installed_solace_font" -eq 0 && -f "$SNAPSHOT_SOLACE/config/solace.ttf" ]]; then
    safe_copy "$SNAPSHOT_SOLACE/config/solace.ttf" "$FONT_HOME/solace.ttf"
  elif [[ "$installed_solace_font" -eq 0 && -f "$SNAPSHOT_CONFIG/solace.ttf" ]]; then
    safe_copy "$SNAPSHOT_CONFIG/solace.ttf" "$FONT_HOME/solace.ttf"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: fc-cache -f $FONT_HOME"
  elif command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONT_HOME"
  fi
}

copy_snapshot_entry() {
  local src="$1"
  local dest="$2"
  safe_copy "$src" "$dest"
}

install_snapshot_config() {
  local name

  for name in \
    aether \
    alacritty \
    autostart \
    btop \
    chromium-flags.conf \
    elephant \
    environment.d \
    fastfetch \
    fcitx5 \
    fontconfig \
    ghostty \
    gtk-3.0 \
    gtk-4.0 \
    hypr \
    hyprland-preview-share-picker \
    imv \
    kitty \
    mimeapps.list \
    mise \
    solace \
    starship.toml \
    swayosd \
    systemd \
    tmux \
    uwsm \
    walker \
    waybar \
    wiremix \
    xdg-terminals.list \
    zed
  do
    [[ -e "$SNAPSHOT_CONFIG/$name" || -L "$SNAPSHOT_CONFIG/$name" ]] || continue
    copy_snapshot_entry "$SNAPSHOT_CONFIG/$name" "$CONFIG_HOME/$name"
  done

  # Keep monitor layout generic. Explicit display descriptors belong in machine profiles.
  safe_copy "$CONFIG_ROOT/hypr/monitors.conf" "$CONFIG_HOME/hypr/monitors.conf"
}

install_snapshot_solace_assets() {
  local name

  for name in applications config default themes; do
    [[ -d "$SNAPSHOT_SOLACE/$name" ]] || continue
    case "$name" in
      default)
        install_snapshot_default_assets
        ;;
      *)
        copy_snapshot_entry "$SNAPSHOT_SOLACE/$name" "$LOCAL_SHARE_HOME/$name"
        ;;
    esac
  done

  install_snapshot_bins
}

install_snapshot_default_assets() {
  local name

  for name in "$SNAPSHOT_SOLACE/default"/*; do
    [[ -e "$name" || -L "$name" ]] || continue
    case "$(basename "$name")" in
      limine|pacman|snapper|systemd|udev)
        log "Skipping unsafe default asset: $name"
        ;;
      *)
        copy_snapshot_entry "$name" "$LOCAL_SHARE_HOME/default/$(basename "$name")"
        ;;
    esac
  done
}

install_snapshot_bins() {
  local src
  local link_src

  [[ -d "$SNAPSHOT_SOLACE/bin" ]] || return 0
  copy_snapshot_entry "$SNAPSHOT_SOLACE/bin" "$LOCAL_SHARE_HOME/bin"

  for src in "$SNAPSHOT_SOLACE/bin"/*; do
    [[ -e "$src" || -L "$src" ]] || continue
    link_src="$LOCAL_SHARE_HOME/bin/$(basename "$src")"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "DRY: chmod +x $link_src"
    else
      chmod +x "$link_src" || true
    fi

    case "$(basename "$src")" in
      *pacman*|*limine*|*direct-boot*|*drive*|*hibernation*|*snapshot*)
        log "Leaving potentially system-destructive helper out of PATH: $link_src"
        ;;
      *)
        if [[ "$DRY_RUN" -eq 1 ]]; then
          log "DRY: would link helper $link_src -> $BIN_HOME/$(basename "$src")"
        else
          safe_link "$link_src" "$BIN_HOME/$(basename "$src")"
        fi
        ;;
    esac
  done
}

sanitize_installed_hypr_defaults() {
  local looknfeel="$LOCAL_SHARE_HOME/default/hypr/looknfeel.conf"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would sanitize legacy Hyprland looknfeel defaults in $looknfeel"
    return 0
  fi

  [[ -f "$looknfeel" ]] || return 0

  sed -i \
    -e 's/^\([[:space:]]*col\.border_locked_active[[:space:]]*=[[:space:]]*\)-1[[:space:]]*$/\1$activeBorderColor/' \
    -e 's/^\([[:space:]]*col\.border_locked_inactive[[:space:]]*=[[:space:]]*\)-1[[:space:]]*$/\1$inactiveBorderColor/' \
    -e '/^[[:space:]]*dim_special[[:space:]]*=/d' \
    "$looknfeel"
}

seed_hypr_toggle_state() {
  local state_dir="$HOME/.local/state/solace/toggles/hypr"
  local state_flags="$state_dir/flags.conf"
  local default_flags="$LOCAL_SHARE_HOME/default/hypr/toggles/flags.conf"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would seed Hyprland toggle state placeholder at $state_flags"
    return 0
  fi

  mkdir -p "$state_dir"
  [[ -f "$state_flags" ]] && return 0

  if [[ -f "$default_flags" ]]; then
    cp -a -- "$default_flags" "$state_flags"
  else
    printf '# Placeholder so Hyprland toggle source glob always has a match.\n' >"$state_flags"
  fi
}

seed_desktop_background() {
  local current_background="$CONFIG_HOME/solace/current/background"
  local default_background="$CONFIG_HOME/solace/current/theme/backgrounds/wallhaven-dpepjo.jpg"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would seed desktop background at $current_background"
    return 0
  fi

  [[ -e "$current_background" || -L "$current_background" ]] && return 0
  [[ -f "$default_background" ]] || return 0

  ln -s "$(realpath --relative-to="$(dirname "$current_background")" "$default_background")" "$current_background"
}

install_snapshot_config
install_snapshot_solace_assets
install_snapshot_fonts
sanitize_installed_hypr_defaults
seed_hypr_toggle_state
seed_desktop_background
install_script_helpers

log "Configs installed (or simulated in dry-run)"
log "Installed Thinkpad-derived Solace UX config with hardware, mirror, and bootloader pieces filtered."
