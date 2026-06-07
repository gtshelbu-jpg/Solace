# Allow the user to change the branding for fastfetch and screensaver
mkdir -p ~/.config/solace/branding
[[ -f ~/.config/solace/branding/about.txt ]] || cp ~/.local/share/solace/icon.txt ~/.config/solace/branding/about.txt
[[ -f ~/.config/solace/branding/screensaver.txt ]] || cp ~/.local/share/solace/logo.txt ~/.config/solace/branding/screensaver.txt
