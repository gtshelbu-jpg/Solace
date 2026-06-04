#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
shopt -s nullglob

scripts=("$ROOT_DIR"/install/*.sh)

if [[ ${#scripts[@]} -eq 0 ]]; then
  printf 'ERROR: no install scripts found in %s/install\n' "$ROOT_DIR" >&2
  exit 1
fi

chmod +x "${scripts[@]}"
exec bash "$ROOT_DIR/install/install.sh" "$@"