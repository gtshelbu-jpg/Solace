echo "Add flags sourcing to hyprland.conf"

HYPR_CONF=~/.config/hypr/hyprland.conf

source "$SOLACE_PATH/install/config/solace-toggles.sh"

if [[ -f $HYPR_CONF ]] && ! grep -q "toggles/hypr/\*\.conf" "$HYPR_CONF"; then
  echo -e "\n# Toggle config flags dynamically\nsource = ~/.local/state/solace/toggles/hypr/*.conf" >> "$HYPR_CONF"
fi
