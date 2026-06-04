echo "Add right-click terminal action to waybar solace menu icon"

WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"

if [[ -f $WAYBAR_CONFIG ]] && ! grep -A5 '"custom/solace"' "$WAYBAR_CONFIG" | grep -q '"on-click-right"'; then
  sed -i '/"on-click": "solace-menu",/a\    "on-click-right": "solace-launch-terminal",' "$WAYBAR_CONFIG"
fi
