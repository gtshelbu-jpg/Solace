echo "Migrate to proper packages for localsend and asdcontrol"

if solace-pkg-present localsend-bin; then
  solace-pkg-drop localsend-bin
  solace-pkg-add localsend
fi

if solace-pkg-present asdcontrol-git; then
  solace-pkg-drop asdcontrol-git
  solace-pkg-add asdcontrol
fi
