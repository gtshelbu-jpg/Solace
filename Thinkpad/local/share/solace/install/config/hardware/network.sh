# systemd-networkd owns addressing/routes. iwd provides Wi-Fi state for impala.
sudo install -d -m 0755 /etc/systemd/network

sudo tee /etc/systemd/network/20-ethernet.network >/dev/null <<'EOF'
[Match]
Type=ether
Kind=!*

[Link]
RequiredForOnline=routable

[Network]
DHCP=yes
MulticastDNS=yes

[DHCPv4]
RouteMetric=100

[IPv6AcceptRA]
RouteMetric=100
EOF

sudo tee /etc/systemd/network/20-wlan.network >/dev/null <<'EOF'
[Match]
Type=wlan

[Link]
RequiredForOnline=routable

[Network]
DHCP=yes
MulticastDNS=yes

[DHCPv4]
RouteMetric=600

[IPv6AcceptRA]
RouteMetric=600
EOF

sudo tee /etc/systemd/network/20-wwan.network >/dev/null <<'EOF'
[Match]
Type=wwan

[Link]
RequiredForOnline=routable

[Network]
DHCP=yes

[DHCPv4]
RouteMetric=700

[IPv6AcceptRA]
RouteMetric=700
EOF

sudo systemctl disable --now NetworkManager.service wpa_supplicant.service dhcpcd.service 2>/dev/null || true
sudo systemctl enable --now iwd.service systemd-networkd.service systemd-resolved.service

# Prevent systemd-networkd-wait-online timeout on boot
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service
