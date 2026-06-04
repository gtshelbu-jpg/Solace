echo "Replace volume control GUI with a TUI"

if solace-cmd-missing wiremix; then
  solace-pkg-add wiremix
  solace-pkg-drop pavucontrol
  solace-refresh-applications
  solace-refresh-waybar
fi
