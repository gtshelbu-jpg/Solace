#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILE_DIR="$SCRIPT_DIR/profile"
WORK_DIR="$SCRIPT_DIR/work"
OUT_DIR="$SCRIPT_DIR/out"

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

[[ -d "$PROFILE_DIR" ]] || { echo "ERROR: profile directory not found: $PROFILE_DIR" >&2; exit 1; }
[[ -f "$PROFILE_DIR/profiledef.sh" ]] || { echo "ERROR: missing profiledef.sh in $PROFILE_DIR" >&2; exit 1; }

mkdir -p "$WORK_DIR" "$OUT_DIR"

if [[ "$CLEAN" -eq 1 ]]; then
  sudo rm -rf -- "$WORK_DIR"
  mkdir -p "$WORK_DIR"
fi

echo "Repository: $REPO_ROOT"
echo "Profile:    $PROFILE_DIR"
echo "Work dir:   $WORK_DIR"
echo "Output dir: $OUT_DIR"

sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"
