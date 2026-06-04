# Configure pacman
sudo cp -f ~/.local/share/solace/default/pacman/pacman-${SOLACE_MIRROR:-stable}.conf /etc/pacman.conf
sudo cp -f ~/.local/share/solace/default/pacman/mirrorlist-${SOLACE_MIRROR:-stable} /etc/pacman.d/mirrorlist

if lspci -nn | grep -q "106b:180[12]"; then
  cat <<EOF | sudo tee -a /etc/pacman.conf >/dev/null

[arch-mact2]
Server = https://github.com/NoaHimesaka1873/arch-mact2-mirror/releases/download/release
SigLevel = Never
EOF
fi
