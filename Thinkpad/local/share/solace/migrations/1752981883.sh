echo "Replace wofi with walker as the default launcher"

if solace-cmd-missing walker; then
  solace-pkg-add walker-bin libqalculate

  solace-pkg-drop wofi
  rm -rf ~/.config/wofi

  mkdir -p ~/.config/walker
  cp -r ~/.local/share/solace/config/walker/* ~/.config/walker/
fi
