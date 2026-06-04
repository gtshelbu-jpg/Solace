echo "Link new theme picker config"

mkdir -p ~/.config/elephant/menus
ln -snf $SOLACE_PATH/default/elephant/solace_themes.lua ~/.config/elephant/menus/solace_themes.lua
sed -i '/"menus",/d' ~/.config/walker/config.toml
solace-restart-walker
