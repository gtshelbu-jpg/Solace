# NetworkManager owns connection state, but iwd is the explicit Wi-Fi backend.
sudo install -d -m 0755 /etc/NetworkManager/conf.d
printf '[device]\nwifi.backend=iwd\n' | sudo tee /etc/NetworkManager/conf.d/wifi_backend.conf >/dev/null
sudo systemctl disable --now wpa_supplicant.service 2>/dev/null || true
sudo systemctl enable --now iwd.service NetworkManager.service
sudo systemctl restart NetworkManager.service

# Prevent systemd-networkd-wait-online timeout on boot
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service
