echo "Add Catppuccin Latte light theme"

if [[ ! -L $HOME/.config/solace/themes/catppuccin-latte ]]; then
  ln -snf ~/.local/share/solace/themes/catppuccin-latte ~/.config/solace/themes/
fi
