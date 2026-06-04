echo "Rename lock screen command in Hypridle config"

if grep -q 'solace-lock-screen' ~/.config/hypr/hypridle.conf; then
  sed -i 's/solace-lock-screen/solace-system-lock/g' ~/.config/hypr/hypridle.conf
  solace-restart-hypridle
fi
