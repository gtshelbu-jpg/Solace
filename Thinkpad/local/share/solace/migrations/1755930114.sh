echo "Add new Solace Menu icon to Waybar"

mkdir -p ~/.local/share/fonts
cp ~/.local/share/solace/config/solace.ttf ~/.local/share/fonts/
fc-cache
