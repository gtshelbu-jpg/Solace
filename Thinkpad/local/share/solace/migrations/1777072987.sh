echo "Fix disable-while-typing on ASUS ROG Flow Z13 detachable keyboard"

source $SOLACE_PATH/install/config/hardware/asus/fix-z13-touchpad.sh

if [[ -f /etc/udev/rules.d/99-solace-asus-z13-touchpad.rules ]]; then
  solace-state set reboot-required
fi
