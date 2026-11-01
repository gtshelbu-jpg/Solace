# Solace Black: proposed downstream architecture

**Design proposal only. No Black repository, remote, installer, security policy,
repository bootstrap or firmware changes have been created/applied.**

Solace remains the shared everyday Arch/Hyprland desktop. Black is a separate
security-focused downstream project, not merely another archiso configuration.

## Recommended: a small overlay repository

The Black repository would contain its own branding/theme, curated package
manifest, optional capabilities, reviewed security settings, hardware adapters,
deployment instructions and tests. A lock file records the tested **Solace commit**.
Install the reviewed base first, then apply Black's deliberately scoped overrides.
Keep overlay ownership explicit so a later base update does not silently clobber
Black settings or user preferences.

This lets Black consume upstream Solace updates without duplicating its entire
installer/config tree. Updates are **reviewed and tested**, not automatically
pulled into a security workstation on login. An independent ISO may package the
same base-plus-overlay combination later, but is not the architecture itself.
No unreviewed remote code is executed merely to discover a newer version.

## A full fork is also possible

A GitHub fork can retain `origin` for Black and `upstream` for Solace. Base updates
would be merged onto a review branch, then tested. This is appropriate if Black
needs substantial installer changes, but theme/config edits will create repeated
merge conflicts and duplicated maintenance. Prefer the overlay until a real
divergence justifies the fork. Do not create or publish either without approval.

## Separate responsibilities

- **Arch/base provisioning:** LUKS2 root, partitioning, recovery material,
  bootloader/UKI selection, firmware trust and Secure Boot enrollment. Performed
  separately with archinstall and an explicitly approved boot/security design.
- **Solace:** shared desktop, preferences, keybindings, launcher, shell and helpers.
- **Black:** security theme, tool selections, documented opt-in policies, adapters
  for pentesting workflows, and deployment/recovery checks.
- **Surface hardware:** tested kernel/headers/firmware/input/audio/camera/power
  configuration, separate from Black policy. Verify current Surface Laptop 6
  upstream/linux-surface support rather than copying old snapshot hardware scripts.

## Security and deployment gates

1. Establish/verify a complete authenticated boot chain, protected kernel command
   line/initramfs as appropriate, recovery boot path, and update-time re-signing.
   Keep private signing keys and LUKS material outside Git.
2. Keep Solace's optional legacy boot visuals disabled. They are not a signed-boot
   integration and must not rewrite a working encrypted/signed boot setup.
3. Verify DKMS module signing/trust for evdi and other out-of-tree drivers under
   the selected kernel and Secure Boot model.
4. Add BlackArch only using its current official documented repository/keyring
   process after reviewing bootstrap trust. Preserve Arch repositories and package
   verification; install a curated list, not the whole distribution collection.
5. Default to no unsolicited network services. Ask separately about SSH, capture
   privileges, USB/SDR permissions, external Wi-Fi ownership and VPN policies.
   Never ship the ThinkPad's saved network profiles or hard-coded WLAN names.
6. Test base updates, overlay reapplication, lid choices, suspend, docking, tool
   dependencies and rollback in a disposable installation before physical rollout.

The feature ideas being developed elsewhere should be collected before choosing
the repository structure definitively or implementing Black-specific policies.
