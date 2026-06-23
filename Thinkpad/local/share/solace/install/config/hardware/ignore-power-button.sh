# Disable logind's default shutdown action so Hyprland can bind the power key
# to the Solace system menu.
sudo install -Dm644 /dev/stdin /etc/systemd/logind.conf.d/10-solace-power-key.conf <<'CONF'
[Login]
HandlePowerKey=ignore
CONF
