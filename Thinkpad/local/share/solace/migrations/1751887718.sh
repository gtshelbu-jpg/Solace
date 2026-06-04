echo "Install Impala as new wifi selection TUI"

if solace-cmd-missing impala; then
  solace-pkg-add impala
  solace-refresh-waybar
fi
