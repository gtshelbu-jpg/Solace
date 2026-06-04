if sudo test -f /etc/sudoers.d/99-solace-installer-reboot; then
  sudo rm -f /etc/sudoers.d/99-solace-installer-reboot
fi
