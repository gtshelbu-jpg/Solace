echo "Make hackerman available as new theme"

if [[ ! -L ~/.config/solace/themes/hackerman ]]; then
  rm -rf ~/.config/solace/themes/hackerman
  ln -nfs ~/.local/share/solace/themes/hackerman ~/.config/solace/themes/
fi
