echo "Make new Osaka Jade theme available as new default"

if [[ ! -L ~/.config/solace/themes/osaka-jade ]]; then
  rm -rf ~/.config/solace/themes/osaka-jade
  git -C ~/.local/share/solace checkout -f themes/osaka-jade
  ln -nfs ~/.local/share/solace/themes/osaka-jade ~/.config/solace/themes/osaka-jade
fi
