echo "Replace bluetooth GUI with TUI"

solace-pkg-add bluetui
solace-pkg-drop blueberry

if ! grep -q "solace-launch-bluetooth" ~/.config/waybar/config.jsonc; then
  sed -i 's/blueberry/solace-launch-bluetooth/' ~/.config/waybar/config.jsonc
fi
