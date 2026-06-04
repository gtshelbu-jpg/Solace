# Solace

Solace is my personal Arch Linux + Hyprland bootstrap/configuration repo.

The goal is to recreate the parts of my current Solace-based setup that I actually like, while removing dependency on Solace repositories, mirrors, branding, and update cadence. Solace should configure a normal upstream Arch install into my preferred Hyprland workstation environment.

This repo is not intended to be a full operating system installer. It should assume Arch Linux is already installed and bootable, then apply packages, configs, services, themes, and workflow preferences.

## Goals

- Use upstream Arch repositories only: `core`, `extra`, and optionally `multilib`
- Do not use Solace package mirrors or repositories
- Do not depend on `stable-mirror.solace.org`
- Preserve the current Hyprland workflow, keybinds, theme behavior, launcher setup, terminal setup, and useful helper scripts
- Keep machine-specific configuration separated from general configuration
- Make setup scripts safe, readable, and repeatable
- Back up existing config files before replacing them
- Avoid destructive disk/partition/install behavior

## Repository Layout

```text
Solace/
├── Thinkpad/
│   ├── config/
│   ├── local/
│   └── reference files from the current ThinkPad setup
├── config/
│   ├── hypr/
│   ├── waybar/
│   ├── nwg-displays/
│   ├── terminal/
│   ├── launcher/
│   └── other reusable user configs
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