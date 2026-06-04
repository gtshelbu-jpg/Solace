#!/bin/bash

# Set install mode to online since boot.sh is used for curl installations
export SOLACE_ONLINE_INSTALL=true

ansi_art='                 ▄▄▄
 ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀
                                       ███   █▀                                  '

clear
echo -e "\n$ansi_art\n"

# Use custom branch if instructed, otherwise default to master
SOLACE_REF="${SOLACE_REF:-master}"

# Set mirror based on branch
if [[ $SOLACE_REF == "dev" ]]; then
  export SOLACE_MIRROR=edge
  echo 'Server = https://mirror.solace.org/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
elif [[ $SOLACE_REF == "rc" ]]; then
  export SOLACE_MIRROR=rc
  echo 'Server = https://rc-mirror.solace.org/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
else
  export SOLACE_MIRROR=stable
  echo 'Server = https://stable-mirror.solace.org/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
fi

sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to basecamp/solace
SOLACE_REPO="${SOLACE_REPO:-basecamp/solace}"

echo -e "\nCloning Solace from: https://github.com/${SOLACE_REPO}.git"
rm -rf ~/.local/share/solace/
git clone "https://github.com/${SOLACE_REPO}.git" ~/.local/share/solace >/dev/null

echo -e "\e[32mUsing branch: $SOLACE_REF\e[0m"
cd ~/.local/share/solace
git fetch origin "${SOLACE_REF}" && git checkout "${SOLACE_REF}"
cd -

echo -e "\nInstallation starting..."
source ~/.local/share/solace/install.sh
