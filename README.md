# Solace

Solace is my personal Arch Linux + Hyprland bootstrap/configuration repo.

The goal is to recreate the parts of my current Omarchy-based setup that I actually like, while removing dependency on Omarchy repositories, mirrors, branding, and update cadence. Solace should configure a normal upstream Arch install into my preferred Hyprland workstation environment.

This repo is not intended to be a full operating system installer. It assumes Arch Linux is already installed and bootable, then applies packages, configs, services, themes, and workflow preferences.

## Goals

- Use upstream Arch repositories only: `core`, `extra`, and optionally `multilib`
- Do not use Omarchy package mirrors or repositories
- Do not depend on `stable-mirror.omarchy.org`
- Preserve the current Hyprland workflow, keybinds, theme behavior, launcher setup, terminal setup, and useful helper scripts
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
│   └── 40-postinstall.sh
└── README.md
```

## Install Flow

This repo is a post-install bootstrap for an already-installed Arch Linux system.

1. `install/10-packages.sh` installs official repo packages from `packages/pacman.txt`, bootstraps `yay` if needed, and installs AUR packages from `packages/aur.txt`.
2. `install/20-configs.sh` backs up existing config and links or copies the reusable config into the current user account.
3. `install/30-services.sh` enables only safe, generic services.
4. `install/40-postinstall.sh` performs light finishing steps and prints follow-up guidance.

### Usage

Dry run:

```bash
./install/install.sh --dry-run
```

Run everything:

```bash
./install/install.sh
```

Run just packages or configs:

```bash
./install/install.sh --only packages
./install/install.sh --only configs
```

Backups of overwritten files are stored under `~/.config-backups/solace-TIMESTAMP/`.