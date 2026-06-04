# Installing Solace configs (post-install)

Run the installer from this repository to install packages and user configs.

Dry-run (safe):
```bash
./install/install.sh --dry-run
```

Run full install (will call `sudo pacman -Syu` for system packages):
```bash
./install/install.sh
```

Run only packages or configs:
```bash
./install/install.sh --only packages
./install/install.sh --only configs
```

Backups of overwritten files are stored in `~/.config-backups/solace-TIMESTAMP/`.

Notes:
- AUR packages require an AUR helper (paru or yay). If one is present, the installer will attempt to use it.
- Monitor-specific configs are left under `machine/thinkpad/` and are not applied automatically.
