#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUR_CACHE_DIR="$SCRIPT_DIR/upstream/aur"
LOCAL_REPO_DIR="$SCRIPT_DIR/localrepo"

usage() {
  cat <<EOF
Usage: archiso/build-aur-package.sh <aur-package>

Builds an AUR package with makepkg and adds the resulting package to the
Solace local archiso repository.

Example:
  archiso/build-aur-package.sh calamares
EOF
}

[[ $# -eq 1 ]] || { usage >&2; exit 1; }

PKG_NAME="$1"
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
  makepkg -s --needed --noconfirm
)

find "$PKG_DIR" -maxdepth 1 -type f -name '*.pkg.tar.*' -exec cp -f -- {} "$LOCAL_REPO_DIR/" \;
repo-add "$LOCAL_REPO_DIR/solace-local.db.tar.gz" "$LOCAL_REPO_DIR"/*.pkg.tar.*

echo "Added $PKG_NAME package(s) to $LOCAL_REPO_DIR"
