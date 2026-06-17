#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILE_DIR="$SCRIPT_DIR/profile"
WORK_DIR="$SCRIPT_DIR/work"
OUT_DIR="$SCRIPT_DIR/out"
LOCAL_REPO_DIR="$SCRIPT_DIR/localrepo"

usage() {
  cat <<EOF
Usage: archiso/build.sh [--clean] [--profile <path>] [--work <path>] [--out <path>]

Builds a Solace ISO with mkarchiso.

Defaults:
  profile: $PROFILE_DIR
  work:    $WORK_DIR
  out:     $OUT_DIR
EOF
}

CLEAN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean)
      CLEAN=1
      shift
      ;;
    --profile)
      [[ $# -ge 2 ]] || { echo "ERROR: --profile requires a path" >&2; exit 1; }
      PROFILE_DIR="$2"
      shift 2
      ;;
    --work)
      [[ $# -ge 2 ]] || { echo "ERROR: --work requires a path" >&2; exit 1; }
      WORK_DIR="$2"
      shift 2
      ;;
    --out)
      [[ $# -ge 2 ]] || { echo "ERROR: --out requires a path" >&2; exit 1; }
      OUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v mkarchiso >/dev/null 2>&1; then
  echo "ERROR: mkarchiso not found. Install the archiso package first." >&2
  exit 1
fi
if ! command -v rsync >/dev/null 2>&1; then
  echo "ERROR: rsync not found. Install rsync before building the ISO." >&2
  exit 1
fi

[[ -d "$PROFILE_DIR" ]] || { echo "ERROR: profile directory not found: $PROFILE_DIR" >&2; exit 1; }
[[ -f "$PROFILE_DIR/profiledef.sh" ]] || { echo "ERROR: missing profiledef.sh in $PROFILE_DIR" >&2; exit 1; }

mkdir -p "$WORK_DIR" "$OUT_DIR"

if [[ "$CLEAN" -eq 1 ]]; then
  sudo rm -rf -- "$WORK_DIR"
  mkdir -p "$WORK_DIR"
fi

BUILD_PROFILE_DIR=""
PROFILE_STAGING_DIR="$(mktemp -d --tmpdir solace-archiso-profile.XXXXXXXX)"
cp -a "$PROFILE_DIR/." "$PROFILE_STAGING_DIR/"

SOLACE_IMAGE_ROOT="$PROFILE_STAGING_DIR/airootfs/opt/solace"
mkdir -p "$(dirname "$SOLACE_IMAGE_ROOT")"
rsync -a --delete \
  --exclude '/.git/' \
  --exclude '/archiso/out/' \
  --exclude '/archiso/work/' \
  --exclude '/archiso/upstream/' \
  --exclude '/archiso/localrepo/' \
  --exclude '*.iso' \
  --exclude '*.img' \
  "$REPO_ROOT/" "$SOLACE_IMAGE_ROOT/"

BUILD_PROFILE_DIR="$PROFILE_STAGING_DIR"

if compgen -G "$LOCAL_REPO_DIR/*.pkg.tar.*" >/dev/null; then
  if [[ ! -f "$LOCAL_REPO_DIR/solace-local.db.tar.gz" && ! -f "$LOCAL_REPO_DIR/solace-local.db" ]]; then
    echo "ERROR: local packages exist, but the solace-local repo database is missing." >&2
    echo "Run: repo-add $LOCAL_REPO_DIR/solace-local.db.tar.gz $LOCAL_REPO_DIR/*.pkg.tar.*" >&2
    exit 1
  fi

  cat >> "$PROFILE_STAGING_DIR/pacman.conf" <<EOF

[solace-local]
SigLevel = Optional TrustAll
Server = file://$LOCAL_REPO_DIR
EOF
  BUILD_PROFILE_DIR="$PROFILE_STAGING_DIR"
fi

cleanup() {
  [[ -n "$PROFILE_STAGING_DIR" ]] && rm -rf -- "$PROFILE_STAGING_DIR"
}
trap cleanup EXIT

echo "Repository: $REPO_ROOT"
echo "Profile:    $PROFILE_DIR"
echo "Build copy: $BUILD_PROFILE_DIR"
echo "Embedded:  $SOLACE_IMAGE_ROOT"
[[ -d "$LOCAL_REPO_DIR" ]] && echo "Local repo: $LOCAL_REPO_DIR"
echo "Work dir:   $WORK_DIR"
echo "Output dir: $OUT_DIR"

sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$BUILD_PROFILE_DIR"
