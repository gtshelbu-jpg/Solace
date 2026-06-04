echo "Use Solace UWSM session without graphical.target startup wait"

sudo mkdir -p /usr/local/share/wayland-sessions
sudo cp "$SOLACE_PATH/default/wayland-sessions/solace.desktop" /usr/local/share/wayland-sessions/solace.desktop

if [[ -f /etc/sddm.conf.d/autologin.conf ]]; then
  sudo sed -i 's/^Session=hyprland-uwsm$/Session=solace/' /etc/sddm.conf.d/autologin.conf
fi
