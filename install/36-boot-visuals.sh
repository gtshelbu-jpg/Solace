#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

REPO_ROOT="$SCRIPT_DIR/.."
PLYMOUTH_SRC="$REPO_ROOT/Thinkpad/local/share/solace/default/plymouth"
LIMINE_SRC="$REPO_ROOT/Thinkpad/local/share/solace/default/limine"
LIMINE_SPLASH_ARGS="quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0"

install_plymouth_theme() {
  [[ -d "$PLYMOUTH_SRC" ]] || { warn "Missing Plymouth theme source: $PLYMOUTH_SRC"; return 0; }

  log "Installing Solace Plymouth theme"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would install $PLYMOUTH_SRC -> /usr/share/plymouth/themes/solace"
    log "DRY: would set Plymouth theme to solace"
    log "DRY: would preserve existing mkinitcpio hooks and add plymouth if possible"
    return 0
  fi

  run_cmd sudo rm -rf /usr/share/plymouth/themes/solace
  run_cmd sudo install -d -m 0755 /usr/share/plymouth/themes
  run_cmd sudo cp -a "$PLYMOUTH_SRC" /usr/share/plymouth/themes/solace
  run_cmd sudo plymouth-set-default-theme solace
  remove_stale_solace_hooks_dropin
  ensure_mkinitcpio_plymouth_hook
}

remove_stale_solace_hooks_dropin() {
  local stale_dropin="/etc/mkinitcpio.conf.d/solace_hooks.conf"

  [[ -e "$stale_dropin" || -L "$stale_dropin" ]] || return 0

  log "Removing stale Solace mkinitcpio hook override at $stale_dropin"
  backup_target "$stale_dropin"
  run_cmd sudo rm -f "$stale_dropin"
}

ensure_mkinitcpio_plymouth_hook() {
  local mkinitcpio_conf="/etc/mkinitcpio.conf"
  local tmp

  [[ -f "$mkinitcpio_conf" ]] || { warn "Missing $mkinitcpio_conf; cannot enable Plymouth hook"; return 0; }
  if awk '
    /^[[:space:]]*HOOKS=\([^)]*\)/ {
      hooks = $0
      sub(/^[^(]*\(/, "", hooks)
      sub(/\).*/, "", hooks)
      if (hooks ~ /(^|[[:space:]])plymouth([[:space:]]|$)/) found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$mkinitcpio_conf"; then
    return 0
  fi

  log "Adding plymouth hook to $mkinitcpio_conf"
  backup_target "$mkinitcpio_conf"
  tmp="$(mktemp)"

  awk '
    /^[[:space:]]*HOOKS=\([^)]*\)/ {
      line = $0
      prefix = line
      sub(/\(.*/, "(", prefix)
      hooks = line
      sub(/^[^(]*\(/, "", hooks)
      suffix = hooks
      sub(/^[^)]*\)/, ")", suffix)
      sub(/\).*/, "", hooks)

      if (hooks ~ /(^|[[:space:]])plymouth([[:space:]]|$)/) {
        print line
        next
      }

      count = split(hooks, hook, /[[:space:]]+/)
      printf "%s", prefix
      inserted = 0
      printed = 0
      for (i = 1; i <= count; i++) {
        if (hook[i] == "") continue
        if (printed++) printf " "
        printf "%s", hook[i]
        if (!inserted && (hook[i] == "udev" || hook[i] == "systemd")) {
          printf " plymouth"
          inserted = 1
        }
      }
      if (!inserted) {
        if (printed) printf " "
        printf "plymouth"
      }
      print suffix
      next
    }
    { print }
  ' "$mkinitcpio_conf" >"$tmp"

  run_cmd sudo install -m 0644 "$tmp" "$mkinitcpio_conf"
  rm -f "$tmp"
}

find_limine_configs() {
  local candidate
  for candidate in \
    /boot/limine/limine.conf \
    /boot/limine.conf \
    /boot/EFI/arch-limine/limine.conf \
    /boot/EFI/BOOT/limine.conf \
    /boot/EFI/limine/limine.conf; do
    [[ -f "$candidate" ]] && printf '%s\n' "$candidate"
  done

  find /boot -maxdepth 5 -type f \( -iname 'limine.conf' -o -iname 'limine.cfg' \) 2>/dev/null \
    | sort
}

find_limine_config() {
  find_limine_configs | awk '!seen[$0]++ { print; exit }'
}

install_limine_theme() {
  [[ -d "$LIMINE_SRC" ]] || { warn "Missing Limine theme source: $LIMINE_SRC"; return 0; }

  local limine_configs=()
  mapfile -t limine_configs < <(find_limine_configs | awk '!seen[$0]++')
  if [[ ${#limine_configs[@]} -eq 0 ]]; then
    warn "No Limine config found; skipping Limine theme"
    return 0
  fi

  log "Installing Solace Limine theme"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would merge Solace Limine visual theme into ${#limine_configs[@]} config file(s)"
    log "DRY: would install Solace UKI splash bitmap"
    if [[ "${SOLACE_BOOT_REGENERATE:-0}" == "1" ]]; then
      log "DRY: SOLACE_BOOT_REGENERATE=1 would update Limine generator defaults and rebuild boot images"
    fi
    for limine_config in "${limine_configs[@]}"; do
      log "DRY: Limine config candidate: $limine_config"
    done
    return 0
  fi

  local limine_config
  for limine_config in "${limine_configs[@]}"; do
    backup_target "$limine_config"
    merge_limine_theme "$limine_config"
  done

  run_cmd sudo install -Dm644 "$LIMINE_SRC/splash-solace.bmp" /usr/share/systemd/bootctl/splash-solace.bmp
  ensure_solace_limine_default_splash
  for limine_config in "${limine_configs[@]}"; do
    ensure_solace_limine_splash_cmdline "$limine_config"
  done

  if [[ "${SOLACE_BOOT_REGENERATE:-0}" != "1" ]]; then
    log "Skipping Limine entry regeneration; set SOLACE_BOOT_REGENERATE=1 to update Solace-generated UKIs/entries."
    return 0
  fi

  ensure_limine_default_config "${limine_configs[@]}"

  local preset
  for preset in /etc/mkinitcpio.d/*.preset; do
    [[ -f "$preset" ]] || continue
    if grep -q '^default_options=' "$preset"; then
      run_cmd sudo sed -i 's|^default_options=.*|default_options="--splash /usr/share/systemd/bootctl/splash-solace.bmp"|' "$preset"
    else
      run_cmd sudo sed -i '/^default_uki=/a default_options="--splash /usr/share/systemd/bootctl/splash-solace.bmp"' "$preset"
    fi
  done

  for limine_config in "${limine_configs[@]}"; do
    merge_limine_theme "$limine_config"
    ensure_solace_limine_splash_cmdline "$limine_config"
  done
}

ensure_solace_limine_default_splash() {
  local default_limine="/etc/default/limine"

  [[ -f "$default_limine" ]] || return 0
  if ! grep -Eq '^TARGET_OS_NAME="?[Ss]olace"?$|^CUSTOM_UKI_NAME="?[Ss]olace"?$' "$default_limine"; then
    log "Leaving non-Solace Limine generator defaults untouched: $default_limine"
    return 0
  fi

  if grep -Eq '^KERNEL_CMDLINE\[default\]\+="[^"]*(^|[[:space:]])quiet([[:space:]]|$)[^"]*(^|[[:space:]])splash([[:space:]]|$)' "$default_limine"; then
    return 0
  fi

  log "Ensuring Solace Limine generator defaults include quiet splash"
  backup_target "$default_limine"
  printf 'KERNEL_CMDLINE[default]+=" quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0"\n' \
    | run_cmd sudo tee -a "$default_limine" >/dev/null
}

extract_limine_base_cmdline() {
  local limine_config
  local cmdline=""

  for limine_config in "$@"; do
    [[ -f "$limine_config" ]] || continue
    cmdline="$(sed -n 's/^[[:space:]]*cmdline:[[:space:]]*//p' "$limine_config" | head -n1)"
    [[ -n "$cmdline" ]] && break
  done

  if [[ -z "$cmdline" && -r /proc/cmdline ]]; then
    cmdline="$(cat /proc/cmdline)"
  fi

  for arg in $LIMINE_SPLASH_ARGS; do
    cmdline="$(printf '%s\n' "$cmdline" | sed -E "s/(^|[[:space:]])${arg//./\\.}([[:space:]]|$)/ /g")"
  done
  printf '%s\n' "$cmdline" | tr -s '[:space:]' ' ' | sed -E 's/^ //; s/ $//'
}

ensure_limine_default_config() {
  local default_limine="/etc/default/limine"
  local dropin="/etc/limine-entry-tool.d/solace-boot-visuals.conf"
  local tmp
  local base_cmdline
  local escaped_cmdline

  base_cmdline="$(extract_limine_base_cmdline "$@")"
  escaped_cmdline="${base_cmdline//\\/\\\\}"
  escaped_cmdline="${escaped_cmdline//&/\\&}"
  escaped_cmdline="${escaped_cmdline//|/\\|}"
  escaped_cmdline="${escaped_cmdline//\"/\\\"}"

  log "Ensuring Limine generator defaults include Solace boot visuals"
  run_cmd sudo install -d -m 0755 /etc/limine-entry-tool.d
  printf 'KERNEL_CMDLINE[default]+=" %s"\n' "$LIMINE_SPLASH_ARGS" | run_cmd sudo tee "$dropin" >/dev/null

  tmp="$(mktemp)"
  if [[ -f "$default_limine" ]]; then
    backup_target "$default_limine"
    awk '
      /^# Solace boot visuals$/ { skip = 1; next }
      skip && /^# End Solace boot visuals$/ { skip = 0; next }
      !skip { print }
    ' "$default_limine" >"$tmp"
    {
      printf '\n# Solace boot visuals\n'
      printf 'KERNEL_CMDLINE[default]+=" %s"\n' "$LIMINE_SPLASH_ARGS"
      if ! grep -q '^ENABLE_UKI=' "$default_limine"; then
        printf 'ENABLE_UKI=yes\n'
      fi
      if ! grep -q '^CUSTOM_UKI_NAME=' "$default_limine"; then
        printf 'CUSTOM_UKI_NAME="solace"\n'
      fi
      if ! grep -q '^ENABLE_LIMINE_FALLBACK=' "$default_limine"; then
        printf 'ENABLE_LIMINE_FALLBACK=yes\n'
      fi
      printf '# End Solace boot visuals\n'
    } >>"$tmp"
  elif [[ -f "$LIMINE_SRC/default.conf" ]]; then
    sed "s|@@CMDLINE@@|$escaped_cmdline|g" "$LIMINE_SRC/default.conf" >"$tmp"
  else
    {
      printf 'TARGET_OS_NAME="Solace"\n'
      printf 'ESP_PATH="/boot"\n'
      printf 'KERNEL_CMDLINE[default]+="%s"\n' "$escaped_cmdline"
      printf 'KERNEL_CMDLINE[default]+=" %s"\n' "$LIMINE_SPLASH_ARGS"
      printf 'ENABLE_UKI=yes\n'
      printf 'CUSTOM_UKI_NAME="solace"\n'
      printf 'ENABLE_LIMINE_FALLBACK=yes\n'
    } >"$tmp"
  fi

  run_cmd sudo install -m 0644 "$tmp" "$default_limine"
  rm -f "$tmp"
}

ensure_limine_splash_cmdline() {
  local limine_config="$1"
  local tmp

  [[ -f "$limine_config" ]] || return 0
  if ! grep -Eq '^[[:space:]]*cmdline:' "$limine_config"; then
    return 0
  fi

  log "Ensuring splash kernel args in $limine_config"
  tmp="$(mktemp)"
  awk '
    /^[[:space:]]*cmdline:/ {
      line = $0
      if (line !~ /(^|[[:space:]])quiet([[:space:]]|$)/) line = line " quiet"
      if (line !~ /(^|[[:space:]])splash([[:space:]]|$)/) line = line " splash"
      if (line !~ /(^|[[:space:]])loglevel=/) line = line " loglevel=0"
      if (line !~ /(^|[[:space:]])systemd\.show_status=/) line = line " systemd.show_status=false"
      if (line !~ /(^|[[:space:]])rd\.udev\.log_level=/) line = line " rd.udev.log_level=0"
      if (line !~ /(^|[[:space:]])vt\.global_cursor_default=/) line = line " vt.global_cursor_default=0"
      print line
      next
    }
    { print }
  ' "$limine_config" >"$tmp"

  run_cmd sudo install -m 0644 "$tmp" "$limine_config"
  rm -f "$tmp"
}

ensure_solace_limine_splash_cmdline() {
  local limine_config="$1"
  local tmp

  [[ -f "$limine_config" ]] || return 0
  if ! grep -Eiq '(^[[:space:]]*/[+]?Solace|path:.*solace.*\.efi|comment:[[:space:]]*Solace)' "$limine_config"; then
    return 0
  fi

  log "Ensuring quiet splash only on Solace entries in $limine_config"
  tmp="$(mktemp)"
  awk '
    /^[[:space:]]*\/[^/]/ {
      in_solace = ($0 ~ /^[[:space:]]*\/\+?[Ss]olace([[:space:]]|$)/)
    }
    /^[[:space:]]*comment:[[:space:]]*[Ss]olace([[:space:]]|$)/ {
      in_solace = 1
    }
    /^[[:space:]]*path:.*[Ss]olace[^[:space:]]*\.efi/ {
      in_solace = 1
    }
    /^[[:space:]]*cmdline:/ && in_solace {
      line = $0
      if (line !~ /(^|[[:space:]])quiet([[:space:]]|$)/) line = line " quiet"
      if (line !~ /(^|[[:space:]])splash([[:space:]]|$)/) line = line " splash"
      if (line !~ /(^|[[:space:]])loglevel=/) line = line " loglevel=0"
      if (line !~ /(^|[[:space:]])systemd\.show_status=/) line = line " systemd.show_status=false"
      if (line !~ /(^|[[:space:]])rd\.udev\.log_level=/) line = line " rd.udev.log_level=0"
      if (line !~ /(^|[[:space:]])vt\.global_cursor_default=/) line = line " vt.global_cursor_default=0"
      print line
      next
    }
    { print }
  ' "$limine_config" >"$tmp"

  if cmp -s "$tmp" "$limine_config"; then
    rm -f "$tmp"
    return 0
  fi

  backup_target "$limine_config"
  run_cmd sudo install -m 0644 "$tmp" "$limine_config"
  rm -f "$tmp"
}

merge_limine_theme() {
  local limine_config="$1"
  local tmp
  tmp="$(mktemp)"

  {
    cat "$LIMINE_SRC/limine.conf"
    printf '\n'
    awk '
      BEGIN {
        split("interface_branding interface_branding_color interface_help_color interface_help_color_bright hash_mismatch_panic term_background backdrop term_palette term_palette_bright term_foreground term_foreground_bright term_background_bright", keys, " ")
        for (i in keys) theme_keys[keys[i]] = 1
      }
      /^[[:space:]]*### Read more at config document:/ { next }
      /^[[:space:]]*# Terminal colors/ { next }
      /^[[:space:]]*# Text colors/ { next }
      /^[[:space:]]*[A-Za-z0-9_]+[[:space:]]*:/ {
        key = $0
        sub(/^[[:space:]]*/, "", key)
        sub(/[[:space:]]*:.*/, "", key)
        if (theme_keys[key]) next
      }
      { print }
    ' "$limine_config"
  } >> "$tmp"

  run_cmd sudo install -m 0644 "$tmp" "$limine_config"
  rm -f "$tmp"
}

rebuild_boot_images() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  if [[ "${SOLACE_BOOT_REGENERATE:-0}" != "1" ]]; then
    log "Skipping boot image rebuild; set SOLACE_BOOT_REGENERATE=1 to rebuild initramfs/UKIs."
    return 0
  fi

  if command -v limine-mkinitcpio >/dev/null 2>&1; then
    run_cmd sudo limine-mkinitcpio
  else
    run_cmd sudo mkinitcpio -P
  fi

  if command -v limine-update >/dev/null 2>&1; then
    run_cmd sudo limine-update
  fi
  if command -v limine-snapper-sync >/dev/null 2>&1; then
    run_cmd sudo limine-snapper-sync
  fi
}

install_plymouth_theme
install_limine_theme
rebuild_boot_images

log "Boot visuals configured where supported."
