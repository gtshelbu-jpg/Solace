echo "Rename screen recording command"

WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"

if [[ -f $WAYBAR_CONFIG ]] && grep -q 'solace-capture-screencording' "$WAYBAR_CONFIG"; then
  sed -i 's/solace-capture-screencording/solace-capture-screenrecording/g' "$WAYBAR_CONFIG"
  solace-restart-waybar
fi
