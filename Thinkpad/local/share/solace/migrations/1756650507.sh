echo "Fix JetBrains font setting"

if [[ $(solace-font-current) == JetBrains* ]]; then
  solace-font-set "JetBrainsMono Nerd Font"
fi
