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
- The login step enables SDDM autologin, installs a Solace Wayland session, updates initramfs for Plymouth support, and adds Plymouth kernel flags to supported bootloader/kernel-cmdline files.
- The login step also installs and sets the bundled `solace` Plymouth theme.
- The `Thinkpad/` snapshot is the source capture for the desired UX/UI/GUI experience, but it is filtered before promotion into active install paths.
- Plymouth splash depends on the active boot entry using the normal splash-friendly flags. The installer handles common Arch boot setups automatically.

## Plymouth kernel flags

For Plymouth, the active kernel command line should include:

```text
quiet splash
```

The login installer automatically adds those flags when it finds one of these supported locations:

- Limine: `cmdline:` lines in `/boot/limine.conf`, `/efi/limine.conf`, or `/boot/efi/limine.conf`
- systemd-boot: `options` lines under `/boot/loader/entries/*.conf`, `/efi/loader/entries/*.conf`, or `/boot/efi/loader/entries/*.conf`
- GRUB: `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`, followed by `grub-mkconfig` when available
- UKI/kernel-install flows: `/etc/kernel/cmdline`

The login installer also ensures `/etc/mkinitcpio.conf` includes the `plymouth` hook and reruns:

```bash
sudo mkinitcpio -P
```
