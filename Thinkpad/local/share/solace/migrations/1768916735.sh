echo "Fix microphone gain and audio mixing on Asus ROG laptops"

source "$SOLACE_PATH/install/config/hardware/asus/fix-mic.sh"
source "$SOLACE_PATH/install/config/hardware/asus/fix-audio-mixer.sh"

if solace-hw-asus-rog; then
  solace-restart-pipewire
fi
