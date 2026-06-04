echo "Move Solace Package Repository after Arch core/extra/multilib and remove AUR"

solace-refresh-pacman
sudo pacman -Syu --noconfirm
