# Install all base packages
mapfile -t packages < <(grep -v '^#' "$SOLACE_INSTALL/solace-base.packages" | grep -v '^$')
solace-pkg-add "${packages[@]}"
