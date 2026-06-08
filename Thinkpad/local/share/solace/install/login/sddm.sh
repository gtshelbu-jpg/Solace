# Install Solace SDDM theme
solace-refresh-sddm

# Setup SDDM login service
sudo mkdir -p /usr/local/share/wayland-sessions
sudo cp "$SOLACE_PATH/default/wayland-sessions/solace.desktop" /usr/local/share/wayland-sessions/solace.desktop

sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/10-wayland.conf >/dev/null
[General]
DisplayServer=wayland

[Wayland]
# Keep the greeter compositor independent from the user Hyprland session.
# The selected Solace session still launches Hyprland through uwsm/start-hyprland.
CompositorCommand=weston --shell=kiosk
EOF

sudo rm -f /etc/sddm.conf.d/autologin.conf
cat <<EOF | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
[Theme]
Current=solace
EOF

# Prevent password-based SDDM logins from creating an encrypted login keyring
# (which conflicts with the passwordless Default_keyring used for auto-unlock)
sudo sed -i '/-auth.*pam_gnome_keyring\.so/d' /etc/pam.d/sddm
sudo sed -i '/-password.*pam_gnome_keyring\.so/d' /etc/pam.d/sddm

# Don't use chrootable here as --now will cause issues for manual installs
sudo systemctl set-default graphical.target
sudo systemctl enable sddm.service
