echo "Uniquely identify terminal apps with custom app-ids using solace-launch-tui"

# Replace terminal -e calls with solace-launch-tui in bindings
sed -i 's/\$terminal -e \([^ ]*\)/solace-launch-tui \1/g' ~/.config/hypr/bindings.conf

# Update waybar to use solace-launch-or-focus with solace-launch-tui for TUI apps
sed -i 's|xdg-terminal-exec btop|solace-launch-or-focus-tui btop|' ~/.config/waybar/config.jsonc
sed -i 's|xdg-terminal-exec --app-id=com\.solace\.Wiremix -e wiremix|solace-launch-or-focus-tui wiremix|' ~/.config/waybar/config.jsonc
