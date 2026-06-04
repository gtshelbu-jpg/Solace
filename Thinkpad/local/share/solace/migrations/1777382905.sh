echo "Use interactive unlock (Plymouth) selector menu"

mkdir -p ~/.config/elephant/menus
ln -snf $SOLACE_PATH/default/elephant/solace_unlocks.lua ~/.config/elephant/menus/solace_unlocks.lua
solace-restart-walker
