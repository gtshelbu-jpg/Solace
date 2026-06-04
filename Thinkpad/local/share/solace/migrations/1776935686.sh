echo "Recover the internal monitor at login when no external display is connected"

SERVICE=solace-recover-internal-monitor.service

mkdir -p ~/.config/systemd/user
cp $SOLACE_PATH/config/systemd/user/$SERVICE ~/.config/systemd/user/$SERVICE

systemctl --user daemon-reload
systemctl --user enable $SERVICE
