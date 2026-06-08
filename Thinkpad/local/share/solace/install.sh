#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define Solace locations
export SOLACE_PATH="$HOME/.local/share/solace"
export SOLACE_INSTALL="$SOLACE_PATH/install"
export SOLACE_INSTALL_LOG_FILE="/var/log/solace-install.log"
export PATH="$SOLACE_PATH/bin:$PATH"

# Compatibility aliases for inherited Omarchy scripts that have not been
# renamed yet. Keep these pointed at Solace so the snapshot installer remains
# usable while the repo is gradually cleaned up.
export OMARCHY_PATH="$SOLACE_PATH"
export OMARCHY_INSTALL="$SOLACE_INSTALL"
export OMARCHY_INSTALL_LOG_FILE="$SOLACE_INSTALL_LOG_FILE"
export OMARCHY_ONLINE_INSTALL="${SOLACE_ONLINE_INSTALL:-false}"

# Install
source "$SOLACE_INSTALL/helpers/all.sh"
source "$SOLACE_INSTALL/preflight/all.sh"
source "$SOLACE_INSTALL/packaging/all.sh"
source "$SOLACE_INSTALL/config/all.sh"
source "$SOLACE_INSTALL/login/all.sh"
source "$SOLACE_INSTALL/post-install/all.sh"
