echo "Ensure all indexes and packages are up to date"

solace-update-keyring
solace-refresh-pacman
sudo pacman -Syu --noconfirm
