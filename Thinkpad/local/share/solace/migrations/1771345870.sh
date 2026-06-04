echo "Switch lmstudio -> lmstudio-bin"

if pacman -Q lmstudio &>/dev/null; then
  solace-pkg-drop lmstudio
  solace-pkg-add lmstudio-bin
fi
