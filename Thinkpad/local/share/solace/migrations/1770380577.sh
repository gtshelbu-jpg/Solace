echo "Use interactive background selector menu"

mkdir -p ~/.config/elephant/menus
ln -snf $SOLACE_PATH/default/elephant/solace_background_selector.lua ~/.config/elephant/menus/solace_background_selector.lua
solace-restart-walker
