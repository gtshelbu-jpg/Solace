echo "Add minimal starship prompt to terminal"

if solace-cmd-missing starship; then
  solace-pkg-add starship
  cp $SOLACE_PATH/config/starship.toml ~/.config/starship.toml
fi
