# Copy over Solace configs
mkdir -p ~/.config
cp -R ~/.local/share/solace/config/* ~/.config/

# Use default bashrc from Solace
cp ~/.local/share/solace/default/bashrc ~/.bashrc
