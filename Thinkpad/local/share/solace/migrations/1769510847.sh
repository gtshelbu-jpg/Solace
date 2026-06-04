echo "Switch back to mainline chromium now that it supports full live theming"

if solace-pkg-present solace-chromium; then
  if gum confirm "Ready to switch to mainstream chromium? (Will close Chromium + reset settings)"; then
    pkill -x chromium
    solace-pkg-drop solace-chromium
    solace-pkg-add chromium
    solace-theme-set-browser
  fi
fi
