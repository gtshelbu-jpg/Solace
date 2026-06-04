echo "Add UWSM env"

export SOLACE_PATH="$HOME/.local/share/solace"
export PATH="$SOLACE_PATH/bin:$PATH"

mkdir -p "$HOME/.config/uwsm/"
cat <<EOF | tee "$HOME/.config/uwsm/env"
export SOLACE_PATH=$HOME/.local/share/solace
export PATH=$SOLACE_PATH/bin/:$PATH
EOF

# Ensure we have the latest repos and are ready to pull
solace-update-keyring
solace-refresh-pacman
sudo systemctl restart systemd-timesyncd
sudo pacman -Sy # Normally not advisable, but we'll do a full -Syu before finishing

mkdir -p ~/.local/state/solace/migrations
touch ~/.local/state/solace/migrations/1751134560.sh

# Remove old AUR packages to prevent a super lengthy build on old Solace installs
solace-pkg-drop zoom qt5-remoteobjects wf-recorder wl-screenrec

# Get rid of old AUR packages
bash $SOLACE_PATH/migrations/1756060611.sh
touch ~/.local/state/solace/migrations/1756060611.sh

bash solace-update-perform
