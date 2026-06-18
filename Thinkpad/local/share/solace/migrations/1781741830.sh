echo "Repair Limine and Plymouth boot splash setup"

ensure_helper_available() {
  local helper="$1"
  local src="$SOLACE_PATH/bin/$helper"
  local dest="$HOME/.local/share/solace/bin/$helper"

  if command -v "$helper" >/dev/null 2>&1; then
    return 0
  fi

  if [[ ! -x "$dest" && -f "$src" ]]; then
    mkdir -p "$HOME/.local/share/solace/bin" "$HOME/.local/bin"
    cp "$src" "$dest"
    chmod +x "$dest"
    ln -sfn "$dest" "$HOME/.local/bin/$helper"
  fi
}

run_helper() {
  local helper="$1"

  ensure_helper_available "$helper"

  if command -v "$helper" >/dev/null 2>&1; then
    "$helper"
  elif [[ -x "$HOME/.local/share/solace/bin/$helper" ]]; then
    "$HOME/.local/share/solace/bin/$helper"
  elif [[ -x "$SOLACE_PATH/bin/$helper" ]]; then
    "$SOLACE_PATH/bin/$helper"
  else
    echo "Error: $helper is not available" >&2
    return 1
  fi
}

run_helper solace-refresh-limine
run_helper solace-refresh-plymouth
