# Solace

Solace is a personal Arch Linux + Hyprland bootstrap/configuration repo.

The project recreates the parts of a preferred Hyprland workflow without tying the setup to a specific distro overlay or third-party mirrors. Solace configures a normal upstream Arch install into a Hyprland workstation environment.

This repo is not a full OS installer; it assumes Arch Linux is already installed and bootable, then applies packages, configs, services, themes, and workflow preferences for a Hyprland desktop.

## Goals

- Use upstream Arch repositories only: `core`, `extra`, and optionally `multilib`
- Avoid depending on third-party mirrors or overlay repos
- Preserve a usable Hyprland workflow, keybinds, launcher, and helper scripts
- Keep machine-specific configuration separated from general configuration
- Make setup scripts safe, readable, and repeatable
- Back up existing config files before replacing them
- Avoid destructive disk/partition/install behavior

## Repository Layout

```text
Solace/
├── config/
│   ├── hypr/
│   ├── waybar/
│   ├── launcher/
│   ├── terminal/
│   ├── notifications/
│   ├── shell/
│   └── themes/
├── machine/
│   └── thinkpad/
│       └── hardware-specific configs, monitor configs, dock/display profiles
├── packages/
│   ├── pacman.txt
│   └── aur.txt
├── install/
│   ├── install.sh
│   ├── lib.sh
│   ├── 10-packages.sh
│   ├── 20-configs.sh
│   ├── 30-services.sh
│   ├── 35-login.sh
│   └── 40-postinstall.sh
└── README.md
```

## Install Flow

This repo is a post-install bootstrap for an already-installed Arch Linux system.

1. `install/10-packages.sh` installs official repo packages from `packages/pacman.txt`, bootstraps `yay` if needed, and installs AUR packages from `packages/aur.txt`.
2. `install/20-configs.sh` backs up existing config and links or copies the reusable config into the current user account.
3. `install/30-services.sh` enables only safe, generic services.
4. `install/35-login.sh` provisions the SDDM login manager, Solace Wayland session, and Plymouth boot support.
5. `install/40-postinstall.sh` performs light finishing steps and prints follow-up guidance.

### Usage

Dry run:

```bash
./install.sh --dry-run
```

Run everything:

```bash
./install.sh
```

Run just packages or configs:

```bash
./install.sh --only packages
./install.sh --only configs
./install.sh --only login
```

Backups of overwritten files are stored under `~/.config-backups/solace-TIMESTAMP/`.

Notes:
- The installer now uses a root wrapper `./install.sh` which ensures the inner `install/` scripts are executable before running.
- The login step will install and set the `ecorp-glitch` Plymouth theme by default (package `plymouth-theme-ecorp-glitch`).
- This project borrows ideas from other popular Hyprland environments; it is not tied to any single distribution overlay.