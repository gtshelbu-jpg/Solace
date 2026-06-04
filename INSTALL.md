# Installing Solace configs (post-install)

Run the installer from this repository to install packages, configs, and a small set of safe services on an already-installed Arch Linux system.

Dry-run (safe):
```bash
./install.sh --dry-run
```

Run full install (will call `sudo pacman -Syu` for system packages):
```bash
./install.sh
```

Run only packages, configs, or login setup:
```bash
./install.sh --only packages
./install.sh --only configs
./install.sh --only login
```

The root wrapper makes every script in `install/` executable before handing off to the inner installer.

Backups of overwritten files are stored in `~/.config-backups/solace-TIMESTAMP/`.

- AUR packages require an AUR helper. If neither `paru` nor `yay` is present, the installer will bootstrap `yay` from the AUR.
- Monitor-specific configs are left under `machine/thinkpad/` and are not applied automatically.
- This repo does not partition disks, install bootloaders, or add Omarchy repos/mirrors.
- The login step enables SDDM, installs a Solace Wayland session, and updates initramfs for Plymouth support.
- Plymouth splash still depends on your bootloader cmdline already exposing the normal splash-friendly flags; this repo does not change bootloader config.
