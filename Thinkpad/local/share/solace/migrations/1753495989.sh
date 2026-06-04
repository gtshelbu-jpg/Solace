echo "Allow updating of timezone by right-clicking on the clock (or running solace-cmd-tzupdate)"

if solace-cmd-missing tzupdate; then
  bash "$SOLACE_PATH/install/config/timezones.sh"
  solace-refresh-waybar
fi
