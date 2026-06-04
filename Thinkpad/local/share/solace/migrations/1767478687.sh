echo "Add opencode with system theming"

solace-pkg-add opencode

# Add config using solace theme by default
if [[ ! -f ~/.config/opencode/opencode.json ]]; then
  mkdir -p ~/.config/opencode
  cp $SOLACE_PATH/config/opencode/opencode.json ~/.config/opencode/opencode.json
fi
