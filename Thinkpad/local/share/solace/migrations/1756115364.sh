echo "Replace buggy native Zoom client with webapp"

if solace-pkg-present zoom; then
  solace-pkg-drop zoom
  solace-webapp-install "Zoom" https://app.zoom.us/wc/home https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/zoom.png
fi
