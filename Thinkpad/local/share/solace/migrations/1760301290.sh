echo "Add the new Flexoki Light theme"

if [[ ! -L ~/.config/solace/themes/flexoki-light ]]; then
  ln -nfs ~/.local/share/solace/themes/flexoki-light ~/.config/solace/themes/
fi
