echo "Make ethereal available as new theme"

if [[ ! -L ~/.config/solace/themes/ethereal ]]; then
  rm -rf ~/.config/solace/themes/ethereal
  ln -nfs ~/.local/share/solace/themes/ethereal ~/.config/solace/themes/
fi
