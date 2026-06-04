echo "Change solace-screenrecord to use gpu-screen-recorder"
solace-pkg-drop wf-recorder wl-screenrec

# Add slurp in case it hadn't been picked up from an old migration
solace-pkg-add slurp gpu-screen-recorder
