# Encrypted installation and Secure Boot preparation

This path uses **systemd-boot + unified kernel images (UKIs)**. A UKI includes the
kernel, command line and initramfs; signing only a standalone kernel does not
authenticate a separate initramfs. The live ISO is **not firmware-signed**: boot
it with Secure Boot disabled. Do not enroll a build/ISO signing key in firmware.

## Before erasing an installed system

Back up personal files and keep a wired USB keyboard and recovery medium available.
Review firmware recovery/key-restoration options. The installer never enrolls or
clears firmware keys and does not choose a physical disk for you. Select the disk,
LUKS password, filesystem and account yourself in archinstall. Do not put the LUKS
password in shell arguments, saved project configuration or screenshots.

## Correct order

1. Boot the ISO with Secure Boot disabled; confirm both onboard and USB input.
2. Run `solace-install`, choose the Arch installation path, and select **LUKS**
   for the intended root partition. Keep the default **systemd-boot + UKI** path.
   An unencrypted ESP mounted at `/boot` is required by this prepared signing path.
   No partition table, encryption password or disk selection is prefilled.
3. Exit archinstall with the target and ESP still mounted. The Solace wrapper
   stages its pinned sources and runs `prepare-early-boot.py` **before reboot**.
   It checks the installed kernel module trees (not the live kernel's `uname`),
   preserves existing `MODULES`, adds early USB input, detects the bound Surface
   pinctrl driver where applicable, and adds the SAM keyboard chain. It retains
   the encryption hook family and moves `keyboard` before `autodetect`/unlock.
4. The wrapper rebuilds the target images and inspects their actual contents,
   extracting `.initrd` from UKIs without modifying the EFI input. Every installed
   kernel must have a checked image with its required non-builtin drivers. Failure
   stops staging/reboot. **Do not reboot past a failed early-input check.**
5. If you approve local Secure Boot preparation, the wrapper enters the target,
   generates **target-owned** sbctl keys, signs and registers the actual UKIs plus
   systemd-boot/fallback EFI loaders, and independently verifies each signature
   using `sbverify`. It does not enroll any key or enable Secure Boot. Images
   changed since input validation are rejected until rechecked.
6. First boot with Secure Boot still disabled. Confirm that the onboard keyboard
   can enter the LUKS passphrase and that the expected system/UKI boots. Then run
   the optional desktop bootstrap. Never depend on first-login hardware fixes for
   the first LUKS prompt. Fresh homes receive verified native modular Hyprland Lua;
   existing homes are not automatically migrated or reset.
7. Before enabling Secure Boot, review `sbctl status`, key/recovery backups and
   signatures. Firmware enrollment is a **separate manual decision**. If approved,
   follow current sbctl/firmware documentation, retaining needed Microsoft/vendor
   trust. Do not blindly clear platform keys or copy another machine's keys.
8. After enrollment, enable Secure Boot in firmware and verify a cold boot, LUKS
   input and `bootctl status`/`sbctl status` from the installed system. Also test a
   subsequent kernel/bootloader update: saved sbctl paths support re-signing, but
   inspect the actual files and verify signatures rather than assuming a hook ran.
   Third-party DKMS modules (including optional display drivers) need their own
   signing/lockdown review; EFI signing alone does not make them loadable.

## Recovery/retry from the ISO

Unlock and mount the intended installed root and its ESP yourself, then:

```bash
# /mnt must be the explicitly mounted installed target, not the live root.
python3 /mnt/opt/solace/scripts/prepare-early-boot.py --target /mnt
python3 /mnt/opt/solace/scripts/prepare-early-boot.py --target /mnt --apply
arch-chroot /mnt python3 /opt/solace/scripts/prepare-secure-boot.py
arch-chroot /mnt python3 /opt/solace/scripts/prepare-secure-boot.py --apply
```

Preview does not write configuration or create keys, but reads trusted target
configuration inside the chroot. Reports are stored under target
`/var/lib/solace/`; private keys stay under target `/var/lib/sbctl/`, never in the
ISO or source repository. Preserve them securely. Keep Secure Boot disabled if
preparation or verification fails. A missing stock-kernel driver requires a
reviewed kernel/support decision; this workflow does not silently add a third-party
kernel repository or accept an unverified package key.

## References and scope

- Chris McLeod, [Installing Arch Linux with Secure Boot on a Microsoft Surface
  Laptop Studio](https://chrismcleod.dev/blog/installing-arch-linux-with-secure-boot-on-a-microsoft-surface-laptop-studio/).
  Its early-keyboard warning and explicit EFI-file signing checks inform this
  ordering. Do not transplant its model-specific driver list or plain-kernel
  signing layout into a different hardware/UKI configuration.
- [linux-surface: Disk Encryption](https://github.com/linux-surface/linux-surface/wiki/Disk-Encryption)
  and [installation](https://github.com/linux-surface/linux-surface/wiki/Installation-and-Setup).
- [ArchWiki: Secure Boot](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot)
  and [mkinitcpio](https://wiki.archlinux.org/title/Mkinitcpio).

Unit/VM checks do not prove onboard keyboard operation or firmware compatibility.
The first physical encrypted boot and Secure Boot cold boot remain required tests.
