#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PKG_FILE="$SCRIPT_DIR/../packages/pacman.txt"
AUR_FILE="$SCRIPT_DIR/../packages/aur.txt"
TABLET_PKG_FILE="$SCRIPT_DIR/../packages/tablet-pacman.txt"
TABLET_AUR_FILE="$SCRIPT_DIR/../packages/tablet-aur.txt"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

if [[ ! -f "$PKG_FILE" ]]; then
  log "No $PKG_FILE found; skipping package installation"
  exit 0
fi

mapfile -t official_packages < <(read_list_file "$PKG_FILE")
mapfile -t aur_packages < <(read_list_file "$AUR_FILE")

for group in ${SOLACE_PACKAGE_GROUPS:-}; do
  case "$group" in
    apps|development|displaylink|security|sdr|gaming) ;;
    *) die "Unknown package group: $group";;
  esac
  mapfile -t group_official < <(read_list_file "$SCRIPT_DIR/../packages/groups/$group-pacman.txt")
  mapfile -t group_aur < <(read_list_file "$SCRIPT_DIR/../packages/groups/$group-aur.txt")
  official_packages+=("${group_official[@]}")
  aur_packages+=("${group_aur[@]}")
done

if has_package_group displaylink; then
  # Archinstall chooses the kernel. Select headers only for known Arch families;
  # custom kernels need their own explicit matching-header setup.
  if [[ $DRY_RUN -eq 1 ]]; then
    log "DRY: would verify matching headers for every installed kernel before DKMS setup"
  else
    kernel_found=0
    for kernel_tree in /usr/lib/modules/*; do
      [[ -f "$kernel_tree/pkgbase" ]] || continue
      kernel_found=1
      if [[ ! -e "$kernel_tree/build/Makefile" ]]; then
        kernel_base="$(cat "$kernel_tree/pkgbase")"
        case "$kernel_base" in
          linux|linux-lts|linux-zen|linux-hardened)
            official_packages+=("$kernel_base-headers")
            log "Selecting matching $kernel_base-headers for DisplayLink DKMS.";;
          *) die "Install matching headers for $kernel_base before selecting DisplayLink; no stock headers were substituted.";;
        esac
      fi
    done
    (( kernel_found )) || die "No installed kernel found for DisplayLink DKMS."
  fi
fi

if [[ "${SOLACE_INSTALL_TABLET_SUPPORT:-0}" == "1" ]]; then
  log "Tablet support selected"
  mapfile -t tablet_official_packages < <(read_list_file "$TABLET_PKG_FILE")
  mapfile -t tablet_aur_packages < <(read_list_file "$TABLET_AUR_FILE")
  official_packages+=("${tablet_official_packages[@]}")
  aur_packages+=("${tablet_aur_packages[@]}")
else
  log "Tablet support not selected"
fi

# A strict local-package policy cannot install ordinary unsigned makepkg output.
# Check before any package transactions; never silently override custom trust.
if [[ ${#aur_packages[@]} -gt 0 && "$DRY_RUN" -eq 0 ]]; then
  local_siglevel="$(pacman-conf LocalFileSigLevel)" || die "Unable to read Pacman local-package signature policy."
  if [[ " $local_siglevel " == *" PackageRequired "* ]]; then
    die "AUR builds require local-package signing or an explicit policy change. Standard Arch uses LocalFileSigLevel = Optional TrustedOnly in /etc/pacman.conf; repository SigLevel must remain Required. No signature policy was changed."
  fi
fi

if [[ ${#official_packages[@]} -gt 0 ]]; then
  log "Installing ${#official_packages[@]} official packages from $PKG_FILE"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo pacman -Syu --noconfirm"
    log "DRY: sudo pacman -S --needed --noconfirm ... (${#official_packages[@]} packages)"
  else
    run_cmd sudo pacman -Syu --noconfirm
    run_cmd sudo pacman -S --needed --noconfirm "${official_packages[@]}"
  fi
else
  log "No official packages listed in $PKG_FILE"
fi

bootstrap_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  log "Bootstrapping yay from the AUR"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo pacman -S --needed --noconfirm git base-devel"
    log "DRY: git clone https://aur.archlinux.org/yay.git /tmp/yay"
    log "DRY: (cd /tmp/yay && makepkg -si --noconfirm)"
    return 0
  fi

  run_cmd sudo pacman -S --needed --noconfirm git base-devel

  workdir="$(mktemp -d)"
  run_cmd git clone https://aur.archlinux.org/yay.git "$workdir/yay"
  (
    cd "$workdir/yay"
    makepkg -si --noconfirm
  )
  rm -rf -- "$workdir"
}

install_aur_packages() {
  local helper="$1"
  local pkg

  for pkg in "${aur_packages[@]}"; do
    log "Installing AUR package with $helper: $pkg"
    run_cmd "$helper" -S --noconfirm --needed "$pkg"
  done
}

if [[ ${#aur_packages[@]} -gt 0 ]]; then
  log "Installing ${#aur_packages[@]} AUR packages from $AUR_FILE"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    for pkg in "${aur_packages[@]}"; do
      log "DRY: AUR install $pkg"
    done
  else
    if command -v paru >/dev/null 2>&1; then
      log "Installing AUR packages with paru"
      install_aur_packages paru
    else
      bootstrap_yay
      if command -v yay >/dev/null 2>&1; then
        log "Installing AUR packages with yay"
        install_aur_packages yay
      else
        die "Unable to install yay helper"
      fi
    fi
  fi
else
  log "No AUR packages listed in $AUR_FILE"
fi
