if [[ -n ${SOLACE_ONLINE_INSTALL:-} ]]; then
  # Install build tools
  solace-pkg-add base-devel

  # Keep Solace on upstream Arch repositories only.
  sudo pacman -Syu --noconfirm
fi
