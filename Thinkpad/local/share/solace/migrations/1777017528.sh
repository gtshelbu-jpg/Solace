echo "Show battery status notification on right-click of the waybar battery icon"

if ! grep -q 'solace-battery-status' ~/.config/waybar/config.jsonc; then
  sed -i '/"on-click": "solace-menu power",/a\    "on-click-right": "notify-send -u low \\"$(solace-battery-status)\\"",' ~/.config/waybar/config.jsonc
  solace-restart-waybar
fi
