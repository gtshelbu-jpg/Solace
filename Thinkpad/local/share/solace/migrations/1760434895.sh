echo "Change to solace-nvim package"
solace-pkg-drop solace-lazyvim
solace-pkg-add solace-nvim

# Will trigger to overwrite configs or not to pickup new hot-reload themes
solace-nvim-setup
