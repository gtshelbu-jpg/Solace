echo "Add Tmux as an option with themed styling"

solace-pkg-add tmux

if [[ ! -f ~/.config/tmux/tmux.conf ]]; then
  mkdir -p ~/.config/tmux
  cp $SOLACE_PATH/config/tmux/tmux.conf ~/.config/tmux/tmux.conf
  solace-theme-refresh
fi
