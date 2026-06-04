echo "Add new matte black theme"

if [[ ! -L $HOME/.config/solace/themes/matte-black ]]; then
  ln -snf ~/.local/share/solace/themes/matte-black ~/.config/solace/themes/
fi
