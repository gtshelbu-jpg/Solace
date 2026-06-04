echo "Use explicit timezone selector when right-clicking on clock"

sed -i 's/solace-cmd-tzupdate/solace-launch-floating-terminal-with-presentation solace-tz-select/g' ~/.config/waybar/config.jsonc
