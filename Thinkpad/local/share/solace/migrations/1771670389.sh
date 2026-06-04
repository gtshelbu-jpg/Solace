echo "Add Logout option to system menu"

solace-refresh-sddm

if [[ -f /etc/sddm.conf.d/autologin.conf ]]; then
  sudo sed -i 's/^Current=.*/Current=solace/' /etc/sddm.conf.d/autologin.conf
fi
