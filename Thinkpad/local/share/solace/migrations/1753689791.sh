echo "Add the new ristretto theme as an option"

if [[ ! -L ~/.config/solace/themes/ristretto ]]; then
  ln -nfs ~/.local/share/solace/themes/ristretto ~/.config/solace/themes/
fi
