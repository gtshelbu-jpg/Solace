if [[ $(plymouth-set-default-theme) != "solace" ]]; then
  sudo cp -r "$HOME/.local/share/solace/default/plymouth" /usr/share/plymouth/themes/solace/
  sudo plymouth-set-default-theme solace
fi
