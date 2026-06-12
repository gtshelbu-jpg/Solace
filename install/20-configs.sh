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
SNAPSHOT_AETHER_SHARE="$SNAPSHOT_ROOT/local/share/aether"
SNAPSHOT_APPLICATIONS="$SNAPSHOT_ROOT/local/share/applications"
SNAPSHOT_FONTS="$SNAPSHOT_ROOT/local/share/fonts"
CONFIG_HOME="$HOME/.config"
LOCAL_SHARE_HOME="$HOME/.local/share/solace"
LOCAL_AETHER_SHARE_HOME="$HOME/.local/share/aether"
LOCAL_APPLICATIONS_HOME="$HOME/.local/share/applications"
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

seed_shell_startup() {
  local default_bashrc="$SNAPSHOT_SOLACE/default/bashrc"
  local bash_profile="$HOME/.bash_profile"

  [[ -f "$default_bashrc" ]] || return 0

  safe_copy "$default_bashrc" "$HOME/.bashrc"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would write $bash_profile to source ~/.bashrc"
    return 0
  fi

  if [[ -e "$bash_profile" || -L "$bash_profile" ]]; then
    backup_target "$bash_profile"
    rm -rf -- "$bash_profile"
  fi

  printf '[[ -f ~/.bashrc ]] && . ~/.bashrc\n' >"$bash_profile"
  log "Wrote $bash_profile"
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
    nvim \
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

install_snapshot_aether_assets() {
  if [[ -d "$SNAPSHOT_AETHER_SHARE" ]]; then
    copy_snapshot_entry "$SNAPSHOT_AETHER_SHARE" "$LOCAL_AETHER_SHARE_HOME"
  fi

  if [[ -f "$SNAPSHOT_APPLICATIONS/aether-protocol-handler.desktop" ]]; then
    safe_copy "$SNAPSHOT_APPLICATIONS/aether-protocol-handler.desktop" "$LOCAL_APPLICATIONS_HOME/aether-protocol-handler.desktop"
  fi
}

install_snapshot_solace_assets() {
  local name
  local asset

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

  for asset in logo.txt logo.svg; do
    [[ -f "$SNAPSHOT_SOLACE/$asset" ]] || continue
    safe_copy "$SNAPSHOT_SOLACE/$asset" "$LOCAL_SHARE_HOME/$asset"
  done

  install_snapshot_bins
}

install_snapshot_default_assets() {
  local name

  for name in "$SNAPSHOT_SOLACE/default"/*; do
    [[ -e "$name" || -L "$name" ]] || continue
    case "$(basename "$name")" in
      limine|pacman|plymouth|snapper|systemd|udev)
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
    case "$(basename "$src")" in
      *pacman*|*limine*|*direct-boot*|*drive*|*hibernation*|*plymouth*|*snapshot*)
        if [[ "$DRY_RUN" -eq 1 ]]; then
          log "DRY: would remove boot/storage helper from installed bin: $link_src"
        else
          rm -f -- "$link_src"
        fi
        log "Skipping boot/storage helper: $link_src"
        continue
        ;;
    esac

    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "DRY: chmod +x $link_src"
    else
      chmod +x "$link_src" || true
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "DRY: would link helper $link_src -> $BIN_HOME/$(basename "$src")"
    else
      safe_link "$link_src" "$BIN_HOME/$(basename "$src")"
    fi
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

remove_storage_shell_helpers() {
  local drives_fns="$LOCAL_SHARE_HOME/default/bash/fns/drives"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would remove storage formatting shell helpers from $drives_fns"
    return 0
  fi

  [[ -e "$drives_fns" || -L "$drives_fns" ]] || return 0
  rm -f -- "$drives_fns"
  log "Removed storage formatting shell helpers from installed defaults"
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
  local default_background

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would seed desktop background at $current_background"
    return 0
  fi

  [[ -e "$current_background" || -L "$current_background" ]] && return 0
  default_background="$(find -L "$CONFIG_HOME/solace/current/theme/backgrounds" -maxdepth 1 -type f 2>/dev/null | sort | head -n1 || true)"
  [[ -n "$default_background" ]] || return 0

  ln -s "$(realpath --relative-to="$(dirname "$current_background")" "$default_background")" "$current_background"
}

seed_aether_theme_bridge() {
  local aether_theme="$CONFIG_HOME/aether/theme"
  local solace_current="$CONFIG_HOME/solace/current"
  local solace_theme="$solace_current/theme"
  local theme_name="$solace_current/theme.name"
  local current_background="$solace_current/background"
  local first_background

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would bridge Aether theme output into Solace current theme"
    return 0
  fi

  [[ -d "$aether_theme" ]] || return 0

  mkdir -p "$solace_current"
  rm -rf -- "$solace_theme"
  ln -sfn "$aether_theme" "$solace_theme"
  printf 'aether\n' >"$theme_name"

  mkdir -p "$CONFIG_HOME/btop/themes" "$CONFIG_HOME/mako" "$CONFIG_HOME/zed/themes"
  ln -sfn "$CONFIG_HOME/solace/current/theme/btop.theme" "$CONFIG_HOME/btop/themes/current.theme"
  ln -sfn "$CONFIG_HOME/solace/current/theme/mako.ini" "$CONFIG_HOME/mako/config"
  ln -sfn "$CONFIG_HOME/solace/current/theme/aether.zed.json" "$CONFIG_HOME/zed/themes/aether.json"

  if [[ ! -e "$current_background" && ! -L "$current_background" ]]; then
    first_background="$(find -L "$aether_theme/backgrounds" -maxdepth 1 -type f 2>/dev/null | sort | head -n1 || true)"
    [[ -n "$first_background" ]] && ln -sfn "$first_background" "$current_background"
  fi
}

install_snapshot_config
install_snapshot_solace_assets
install_snapshot_aether_assets
install_snapshot_fonts
sanitize_installed_hypr_defaults
remove_storage_shell_helpers
seed_hypr_toggle_state
seed_desktop_background
seed_aether_theme_bridge
install_script_helpers
seed_shell_startup

log "Configs installed (or simulated in dry-run)"
log "Installed Thinkpad-derived Solace UX config with hardware, mirror, and bootloader pieces filtered."
