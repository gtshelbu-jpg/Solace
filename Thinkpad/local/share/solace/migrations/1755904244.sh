echo "Update fastfetch config with new Solace logo"

solace-refresh-config fastfetch/config.jsonc

mkdir -p ~/.config/solace/branding
cp $SOLACE_PATH/icon.txt ~/.config/solace/branding/about.txt
