# Handles changes since 3.1.0-RC

echo "Add shift+insert for kitty"
# Add shift+insert paste keybinding to kitty.conf if it doesn't exist
KITTY_CONF="$HOME/.config/kitty/kitty.conf"

if ! grep -q "map shift+insert paste_from_clipboard" "$KITTY_CONF"; then
  sed -i '/map ctrl+insert copy_to_clipboard/a map shift+insert paste_from_clipboard' "$KITTY_CONF"
fi

echo "Copy hooks examples"
cp -r $SOLACE_PATH/config/solace/* $HOME/.config/solace/

echo "Add packages for updated solace-capture-screenshot"
solace-pkg-add grim slurp

echo "Add nfs support by default to Nautilus"
solace-pkg-add gvfs-nfs

if [[ ! -d $HOME/.config/nvim ]]; then
  echo "Add missing nvim config"
  solace-nvim-setup
fi
