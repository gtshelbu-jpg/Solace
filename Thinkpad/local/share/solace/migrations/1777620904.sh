echo "Add cliamp music TUI player (Super+Shift+Alt+M)"

if solace-pkg-missing cliamp; then
  solace-pkg-add cliamp

  if [[ -f ~/.config/hypr/bindings.conf ]] && ! grep -q "cliamp" ~/.config/hypr/bindings.conf; then
    sed -i '/^bindd = SUPER SHIFT, M, Music, exec, solace-launch-or-focus spotify/a bindd = SUPER SHIFT ALT, M, Music TUI, exec, solace-launch-or-focus-tui cliamp' ~/.config/hypr/bindings.conf
  fi
fi
