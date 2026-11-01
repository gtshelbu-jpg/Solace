#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUR_CACHE_DIR="$SCRIPT_DIR/upstream/aur"
LOCAL_REPO_DIR="$SCRIPT_DIR/localrepo"

usage() {
  cat <<EOF
Usage: archiso/build-aur-package.sh <aur-package> --sign-key <fingerprint>

Builds an AUR package with makepkg and adds the resulting package to the
Solace local archiso repository.

Example:
  archiso/build-aur-package.sh calamares --sign-key YOUR_SIGNING_KEY
EOF
}

[[ $# -eq 3 && $2 == "--sign-key" ]] || { usage >&2; exit 1; }

PKG_NAME="$1"
[[ $PKG_NAME =~ ^[a-z0-9][a-z0-9@._+-]*$ ]] || { echo 'Invalid package name' >&2; exit 1; }
SIGN_KEY="$3"
[[ $SIGN_KEY =~ ^[A-Fa-f0-9]{40}$ || $SIGN_KEY =~ ^[A-Fa-f0-9]{64}$ ]] || { echo 'Use a full signing-key fingerprint' >&2; exit 1; }
PKG_DIR="$AUR_CACHE_DIR/$PKG_NAME"

for cmd in git makepkg repo-add; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "ERROR: missing required command: $cmd" >&2
    exit 1
  }
done

mkdir -p "$AUR_CACHE_DIR" "$LOCAL_REPO_DIR"

if [[ -d "$PKG_DIR/.git" ]]; then
  git -C "$PKG_DIR" pull --ff-only
else
  git clone "https://aur.archlinux.org/$PKG_NAME.git" "$PKG_DIR"
fi

(
  cd "$PKG_DIR"
  makepkg -s --needed --noconfirm --sign --key "$SIGN_KEY"
)

shopt -s nullglob
packages=("$PKG_DIR"/*.pkg.tar.zst "$PKG_DIR"/*.pkg.tar.xz "$PKG_DIR"/*.pkg.tar.gz)
(( ${#packages[@]} )) || { echo 'No package artifacts were produced' >&2; exit 1; }
for package in "${packages[@]}"; do
  [[ -f "$package.sig" ]] || { echo 'Package signature missing' >&2; exit 1; }
  cp -f -- "$package" "$package.sig" "$LOCAL_REPO_DIR/"
done
all_packages=("$LOCAL_REPO_DIR"/*.pkg.tar.zst "$LOCAL_REPO_DIR"/*.pkg.tar.xz "$LOCAL_REPO_DIR"/*.pkg.tar.gz)
repo-add --sign --key "$SIGN_KEY" "$LOCAL_REPO_DIR/solace-local.db.tar.gz" "${all_packages[@]}"

echo "Added $PKG_NAME package(s) to $LOCAL_REPO_DIR"
