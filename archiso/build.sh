#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILE_DIR="$SCRIPT_DIR/profile"
WORK_DIR="$SCRIPT_DIR/work"
OUT_DIR="$SCRIPT_DIR/out"
LOCAL_REPO_DIR="$SCRIPT_DIR/localrepo"
EMBED_SOURCE="$REPO_ROOT"
GPG_DIR=""
CLEAN=0
ALLOW_DIRTY_SOURCES=0
EXTRA_NAMES=()
EXTRA_PATHS=()

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'EOF'
Usage: archiso/build.sh [options]
  --profile PATH       Archiso profile (copied to disposable staging)
  --work PATH          Per-variant mkarchiso work directory
  --out PATH           ISO output directory
  --embed-source PATH  Solace source to embed at /opt/solace
  --extra-source NAME PATH
                       Extra source at /opt/NAME; NAME must begin solace-
  --local-repo PATH    Optional SIGNED local package repository
  --gpg-dir PATH       Dedicated populated build-time Pacman keyring
  --clean              Clean only a builder-marked work directory
  --allow-dirty-sources  Explicit development build; embed working trees, not a release

Existing package signatures are required. No TrustAll or unsigned-repo bypass.
EOF
}
while (( $# )); do
  case "$1" in
    --clean) CLEAN=1; shift;;
    --allow-dirty-sources) ALLOW_DIRTY_SOURCES=1; shift;;
    --profile|--work|--out|--embed-source|--local-repo|--gpg-dir)
      (( $# >= 2 )) || die "$1 requires a path"
      case "$1" in
        --profile) PROFILE_DIR="$2";;
        --work) WORK_DIR="$2";;
        --out) OUT_DIR="$2";;
        --embed-source) EMBED_SOURCE="$2";;
        --local-repo) LOCAL_REPO_DIR="$2";;
        --gpg-dir) GPG_DIR="$2";;
      esac
      shift 2;;
    --extra-source)
      (( $# >= 3 )) || die "--extra-source requires NAME PATH"
      [[ $2 =~ ^solace-[a-z0-9-]+$ ]] || die "Invalid extra source name"
      for name in "${EXTRA_NAMES[@]}"; do [[ $name != "$2" ]] || die "Duplicate extra source"; done
      EXTRA_NAMES+=("$2"); EXTRA_PATHS+=("$3"); shift 3;;
    -h|--help) usage; exit 0;;
    *) die "Unknown option: $1";;
  esac
done
for cmd in mkarchiso rsync realpath git tar; do command -v "$cmd" >/dev/null || die "Missing $cmd"; done
PROFILE_DIR="$(realpath -e "$PROFILE_DIR")"
EMBED_SOURCE="$(realpath -e "$EMBED_SOURCE")"
WORK_DIR="$(realpath -m "$WORK_DIR")"
OUT_DIR="$(realpath -m "$OUT_DIR")"
[[ -f "$PROFILE_DIR/profiledef.sh" && -f "$EMBED_SOURCE/install.sh" ]] || die "Invalid profile or Solace source"

# Never recursively remove an arbitrary --work argument or a parent of inputs.
for protected in / /etc /usr /var /boot /opt /home /tmp /run /sys /proc /dev "$HOME" "$REPO_ROOT" "$PROFILE_DIR" "$EMBED_SOURCE" "$OUT_DIR"; do
  [[ $WORK_DIR != "$protected" && $protected != "$WORK_DIR/"* ]] || die "Unsafe work directory: $WORK_DIR"
done
if [[ -d $WORK_DIR && ! -f "$WORK_DIR/.solace-build-work" && -n $(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -print -quit) ]]; then
  die "Existing unmarked work directory requires manual review"
fi
if (( CLEAN )); then
  [[ -f "$WORK_DIR/.solace-build-work" ]] || die "Refusing to clean an unmarked work directory"
  sudo rm -rf -- "$WORK_DIR"
fi
mkdir -p "$WORK_DIR" "$OUT_DIR"
touch "$WORK_DIR/.solace-build-work"

STAGING="$(mktemp -d -t solace-archiso-profile.XXXXXXXX)"
trap 'rm -rf -- "$STAGING"' EXIT
cp -a "$PROFILE_DIR/." "$STAGING/"

embed_source() {
  local src="$1" name="$2"
  [[ -d $src ]] || die "Missing embedded source: $src"
  mkdir -p "$STAGING/airootfs/opt/$name"
  if (( ! ALLOW_DIRTY_SOURCES )); then
    [[ $(git -C "$src" rev-parse --show-toplevel 2>/dev/null) == "$(realpath -e "$src")" ]] || die "Release sources must be Git repository roots"
    [[ -z $(git -C "$src" status --porcelain) ]] || die "Modified source requires --allow-dirty-sources (not a release build)"
    git -C "$src" archive HEAD | tar -x -C "$STAGING/airootfs/opt/$name"
    return
  fi
  echo "WARNING: embedding development source for $name" >&2
  rsync -a --delete \
    --exclude '/.git/' --exclude '/.deps/' --exclude '/.work/' --exclude '/out/' \
    --exclude '/archiso/out/' --exclude '/archiso/work/' --exclude '/archiso/upstream/' \
    --exclude '/archiso/localrepo/' --exclude '__pycache__/' \
    --exclude '/.venv/' --exclude '/.keys/' --exclude '.env' \
    --exclude '*.key' --exclude '*.pem' --exclude '*.keyring' \
    --exclude '*.iso' --exclude '*.img' \
    "$src/" "$STAGING/airootfs/opt/$name/"
}
embed_source "$EMBED_SOURCE" solace
for i in "${!EXTRA_NAMES[@]}"; do embed_source "${EXTRA_PATHS[$i]}" "${EXTRA_NAMES[$i]}"; done

if [[ -n $GPG_DIR ]]; then
  GPG_DIR="$(realpath -e "$GPG_DIR")"
  [[ -f "$GPG_DIR/pubring.gpg" || -f "$GPG_DIR/pubring.kbx" ]] || die "Build keyring is not populated"
  [[ $GPG_DIR != *$'\n'* ]] || die "Invalid keyring path"
  sed -i "/^\[options\]/a GPGDir = $GPG_DIR" "$STAGING/pacman.conf"
fi
shopt -s nullglob
packages=("$LOCAL_REPO_DIR"/*.pkg.tar.zst "$LOCAL_REPO_DIR"/*.pkg.tar.xz "$LOCAL_REPO_DIR"/*.pkg.tar.gz)
if (( ${#packages[@]} )); then
  [[ -n $GPG_DIR ]] || die "Local packages require --gpg-dir with explicitly trusted signing keys"
  [[ -f "$LOCAL_REPO_DIR/solace-local.db" || -f "$LOCAL_REPO_DIR/solace-local.db.tar.gz" ]] || die "Missing solace-local repository database"
  for package in "${packages[@]}"; do [[ -f "$package.sig" ]] || die "Unsigned local package: $package"; done
  # Pacman performs the actual cryptographic verification, not just this file check.
  cat >> "$STAGING/pacman.conf" <<EOF

[solace-local]
SigLevel = Required TrustedOnly
Server = file://$(realpath -e "$LOCAL_REPO_DIR")
EOF
fi
printf 'Profile: %s\nEmbedded Solace: %s\nWork: %s\nOutput: %s\n' "$PROFILE_DIR" "$EMBED_SOURCE" "$WORK_DIR" "$OUT_DIR"
sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$STAGING"
