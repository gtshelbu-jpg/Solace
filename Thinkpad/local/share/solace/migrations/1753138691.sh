echo "Install swayOSD to show volume status"

if solace-cmd-missing swayosd-server; then
  solace-pkg-add swayosd
  setsid uwsm-app -- swayosd-server &>/dev/null &
fi
