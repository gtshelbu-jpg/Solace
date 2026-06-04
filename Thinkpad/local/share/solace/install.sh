#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define Solace locations
export SOLACE_PATH="$HOME/.local/share/solace"
export SOLACE_INSTALL="$SOLACE_PATH/install"
export SOLACE_INSTALL_LOG_FILE="/var/log/solace-install.log"
export PATH="$SOLACE_PATH/bin:$PATH"

# Install
source "$SOLACE_INSTALL/helpers/all.sh"
source "$SOLACE_INSTALL/preflight/all.sh"
source "$SOLACE_INSTALL/packaging/all.sh"
source "$SOLACE_INSTALL/config/all.sh"
source "$SOLACE_INSTALL/login/all.sh"
source "$SOLACE_INSTALL/post-install/all.sh"
