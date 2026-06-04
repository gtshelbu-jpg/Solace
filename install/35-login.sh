#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

LOGIN_CONFIG_ROOT="$SCRIPT_DIR/../config/login"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
RECOMMENDED_KERNEL_FLAGS=("quiet" "splash")

install_login_file() {
  local src="$1"
  local dest="$2"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would install $src -> $dest"
    return 0
  fi

  backup_target "$dest"
  run_cmd sudo install -Dm644 "$src" "$dest"
}

install_wayland_session() {
  local src="$LOGIN_CONFIG_ROOT/wayland-sessions/solace.desktop"
  local dest="/usr/local/share/wayland-sessions/solace.desktop"

  [[ -f "$src" ]] || die "Missing Wayland session definition: $src"
  install_login_file "$src" "$dest"
}

install_sddm_wayland_config() {
  local src="$LOGIN_CONFIG_ROOT/sddm/10-wayland.conf"
  local dest="/etc/sddm.conf.d/10-wayland.conf"
  local greeter_src="$LOGIN_CONFIG_ROOT/sddm/hyprland.conf"
  local greeter_dest="/usr/share/sddm/hyprland.conf"

  [[ -f "$src" ]] || die "Missing SDDM config: $src"
  [[ -f "$greeter_src" ]] || die "Missing SDDM greeter config: $greeter_src"

  install_login_file "$src" "$dest"
  install_login_file "$greeter_src" "$greeter_dest"
}

set_plymouth_theme() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo plymouth-set-default-theme -R ecorp-glitch"
    return 0
  fi

  run_cmd sudo plymouth-set-default-theme -R ecorp-glitch
}

ensure_plymouth_hook() {
  [[ -f "$MKINITCPIO_CONF" ]] || { warn "No $MKINITCPIO_CONF found; skipping Plymouth hook update"; return 0; }

  if grep -Eq '^[[:space:]]*HOOKS=.*plymouth' "$MKINITCPIO_CONF"; then
    log "Plymouth hook already present in $MKINITCPIO_CONF"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would back up and update $MKINITCPIO_CONF to add the plymouth hook"
    return 0
  fi

  backup_target "$MKINITCPIO_CONF"

  run_cmd sudo python3 - "$MKINITCPIO_CONF" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()

pattern = re.compile(r'^(HOOKS=\()([^\n]*?\budev\b)([^\n]*?\))$', re.MULTILINE)

def repl(match: re.Match[str]) -> str:
    prefix = match.group(1)
    before = match.group(2)
    after = match.group(3)
    if 'plymouth' in before or 'plymouth' in after:
      return match.group(0)
    return f"{prefix}{before} plymouth{after}"

new_text, count = pattern.subn(repl, text, count=1)

if count == 0:
    raise SystemExit(f'Could not find a HOOKS line with udev in {path}')

path.write_text(new_text)
PY

  log "Updated Plymouth hook in $MKINITCPIO_CONF"
}

check_kernel_cmdline_flags() {
  local cmdline=""
  local missing=()
  local flag

  if [[ -r /proc/cmdline ]]; then
    cmdline="$(< /proc/cmdline)"
  fi

  for flag in "${RECOMMENDED_KERNEL_FLAGS[@]}"; do
    if [[ " $cmdline " != *" $flag "* ]]; then
      missing+=("$flag")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    log "Kernel cmdline already includes Plymouth-friendly flags: ${RECOMMENDED_KERNEL_FLAGS[*]}"
    return 0
  fi

  warn "Kernel cmdline is missing Plymouth-friendly flag(s): ${missing[*]}"
  warn "Solace updates supported bootloader/kernel cmdline files during the login install step, but the new flags take effect after reboot."
}

ensure_flags_in_cmdline_file() {
  local mode="$1"
  local file="$2"

  [[ -f "$file" ]] || return 1

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: would ensure '${RECOMMENDED_KERNEL_FLAGS[*]}' in $file"
    return 0
  fi

  backup_target "$file"

  run_cmd sudo python3 - "$mode" "$file" "${RECOMMENDED_KERNEL_FLAGS[@]}" <<'PY'
from pathlib import Path
import re
import sys

mode = sys.argv[1]
path = Path(sys.argv[2])
flags = sys.argv[3:]
text = path.read_text()

def add_flags(cmdline: str) -> str:
    parts = cmdline.split()
    for flag in flags:
        if flag not in parts:
            parts.append(flag)
    return " ".join(parts)

changed = False

if mode == "kernel":
    lines = text.splitlines()
    if not lines:
        lines = [""]
    lines[0] = add_flags(lines[0])
    new_text = "\n".join(lines) + ("\n" if text.endswith("\n") or lines else "")
    changed = new_text != text
elif mode == "limine":
    def repl(match: re.Match[str]) -> str:
        global changed
        updated = match.group(1) + add_flags(match.group(2))
        if updated != match.group(0):
            changed = True
        return updated
    new_text = re.sub(r"^(\s*cmdline:\s*)(.*?)\s*$", repl, text, flags=re.MULTILINE)
elif mode == "systemd-boot":
    def repl(match: re.Match[str]) -> str:
        global changed
        updated = match.group(1) + add_flags(match.group(2))
        if updated != match.group(0):
            changed = True
        return updated
    new_text = re.sub(r"^(\s*options\s+)(.*?)\s*$", repl, text, flags=re.MULTILINE)
elif mode == "grub":
    pattern = re.compile(r'^(GRUB_CMDLINE_LINUX_DEFAULT=)(["\'])(.*?)(\2)\s*$', re.MULTILINE)
    match = pattern.search(text)
    if match:
        updated_value = add_flags(match.group(3))
        replacement = f"{match.group(1)}{match.group(2)}{updated_value}{match.group(4)}"
        new_text = text[:match.start()] + replacement + text[match.end():]
        changed = new_text != text
    else:
        suffix = "" if text.endswith("\n") or not text else "\n"
        new_text = text + suffix + f'GRUB_CMDLINE_LINUX_DEFAULT="{add_flags("")}"\n'
        changed = True
else:
    raise SystemExit(f"Unknown cmdline mode: {mode}")

if changed:
    path.write_text(new_text)
PY

  log "Ensured Plymouth kernel flags in $file"
  return 0
}

ensure_plymouth_kernel_flags() {
  local found=0
  local file

  if ensure_flags_in_cmdline_file kernel /etc/kernel/cmdline; then
    found=1
  fi

  for file in /boot/limine.conf /efi/limine.conf /boot/efi/limine.conf; do
    if ensure_flags_in_cmdline_file limine "$file"; then
      found=1
    fi
  done

  shopt -s nullglob
  for file in /boot/loader/entries/*.conf /efi/loader/entries/*.conf /boot/efi/loader/entries/*.conf; do
    if ensure_flags_in_cmdline_file systemd-boot "$file"; then
      found=1
    fi
  done
  shopt -u nullglob

  if ensure_flags_in_cmdline_file grub /etc/default/grub; then
    found=1
    if command -v grub-mkconfig >/dev/null 2>&1; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        log "DRY: sudo grub-mkconfig -o /boot/grub/grub.cfg"
      else
        run_cmd sudo grub-mkconfig -o /boot/grub/grub.cfg
      fi
    else
      warn "Updated /etc/default/grub but grub-mkconfig was not found; GRUB config may need regeneration."
    fi
  fi

  if [[ "$found" -eq 0 ]]; then
    warn "No known bootloader cmdline file found for automatic Plymouth flag setup."
    warn "Supported automatic targets: /etc/kernel/cmdline, Limine configs, systemd-boot loader entries, /etc/default/grub."
  fi
}

rebuild_initramfs() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo mkinitcpio -P"
  else
    run_cmd sudo mkinitcpio -P
  fi
}

enable_login_manager() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo systemctl set-default graphical.target"
    log "DRY: sudo systemctl enable sddm.service"
  else
    run_cmd sudo systemctl set-default graphical.target
    run_cmd sudo systemctl enable sddm.service
  fi
}

log "Installing graphical login and Plymouth boot support"
install_wayland_session
install_sddm_wayland_config
ensure_plymouth_hook
set_plymouth_theme
ensure_plymouth_kernel_flags
rebuild_initramfs
enable_login_manager
check_kernel_cmdline_flags

log "Login flow configured: boot splash via Plymouth, graphical login via SDDM, Hyprland session via Solace"
