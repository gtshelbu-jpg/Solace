# Installing Solace configs (post-install)

Run the installer from this repository to install packages, configs, and a small set of safe services on an already-installed Arch Linux system.

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

- AUR packages require an AUR helper. If neither `paru` nor `yay` is present, the installer will bootstrap `yay` from the AUR.
- Monitor-specific configs are left under `machine/thinkpad/` and are not applied automatically.
- This repo does not partition disks, install bootloaders, or add Omarchy repos/mirrors.
