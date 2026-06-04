echo "Install socat so we can reactivate internal display when external display is removed"

solace-pkg-add socat
uwsm-app -- solace-hyprland-monitor-watch &
