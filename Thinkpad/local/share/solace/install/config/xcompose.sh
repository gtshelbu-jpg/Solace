# Set default XCompose that is triggered with CapsLock
tee ~/.XCompose >/dev/null <<EOF
# Run solace-restart-xcompose to apply changes

# Include fast emoji access
include "%H/.local/share/solace/default/xcompose"

# Identification
<Multi_key> <space> <n> : "$SOLACE_USER_NAME"
<Multi_key> <space> <e> : "$SOLACE_USER_EMAIL"
EOF
