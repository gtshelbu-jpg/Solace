echo "Add sample low battery notification hook"

mkdir -p ~/.config/solace/hooks/battery-low.d

if [[ ! -f ~/.config/solace/hooks/battery-low.d/play-warning-sound.sample ]]; then
  cp "$SOLACE_PATH/config/solace/hooks/battery-low.d/play-warning-sound.sample" ~/.config/solace/hooks/battery-low.d/play-warning-sound.sample
fi
