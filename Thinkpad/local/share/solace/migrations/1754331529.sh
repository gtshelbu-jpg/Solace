echo "Update Waybar for new Solace menu"

if ! grep -q "" ~/.config/waybar/config.jsonc; then
  solace-refresh-waybar
fi
