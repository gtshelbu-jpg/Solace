echo "Add sample post-boot hook"

mkdir -p ~/.config/solace/hooks/post-boot.d

if [[ ! -f ~/.config/solace/hooks/post-boot.d/weather.sample ]]; then
  cp "$SOLACE_PATH/config/solace/hooks/post-boot.d/weather.sample" ~/.config/solace/hooks/post-boot.d/weather.sample
fi
