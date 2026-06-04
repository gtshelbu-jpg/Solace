# Thinkpad Snapshot Classification

`Thinkpad/` is a snapshot of the current system and is the source capture for the Solace desktop experience. The goal is to deploy that experience onto fresh Arch installs while filtering out host-specific and distro-overlay behavior.

## Promote Into `config/`

These are UX/UI/GUI oriented and should be direct crossover candidates after a quick syntax/path audit:

- `Thinkpad/config/hypr/` except monitor profiles and hardware recovery toggles
- `Thinkpad/config/waybar/`
- `Thinkpad/config/walker/`
- `Thinkpad/config/alacritty/`, `ghostty/`, `kitty/`, and terminal defaults
- `Thinkpad/config/mako`, `swayosd`, notification, launcher, and app UI config
- `Thinkpad/config/gtk-3.0/`, `gtk-4.0/`, `fontconfig/`, `fastfetch/`, `btop/`, `imv/`
- `Thinkpad/local/share/solace/themes/`
- `Thinkpad/local/share/solace/default/hypr/`, `default/mako/`, `default/waybar/`, `default/themed/`, and app/window-rule defaults that do not assume hardware
- desktop files and icons for preferred apps, once paths and package names are verified

## Keep Machine-Specific

These belong in `machine/thinkpad/` or another explicit host profile, not general `config/`:

- explicit monitor descriptors, dock/display layouts, scaling profiles, and disabled outputs
- GPU, DisplayLink/EVDI, lid, suspend, backlight, keyboard firmware, udev, hwdb, and power quirks
- host recovery services such as internal-monitor recovery
- hostnames, user-local tokens, cache/state files, and generated DBus/session artifacts

## Do Not Install Automatically

These conflict with Solace's upstream-Arch and post-install-bootstrap boundaries:

- pacman repo files, mirrorlists, or scripts that overwrite `/etc/pacman.conf` or `/etc/pacman.d/mirrorlist`
- Omarchy/Solace overlay repo channel switching
- bootloader, UKI, limine, partitioning, encryption, or disk selection logic
- migrations that call `$OMARCHY_PATH` or assume an Omarchy install tree
- full snapshot overlays into `~/.config` or `~/.local/share/solace` without filtering

## Current Known Risks

- `Thinkpad/config/hypr/monitors.conf` contains an explicit Acer monitor descriptor and must not be installed globally.
- `Thinkpad/local/share/solace/default/pacman/` contains custom repo and mirror configuration and must remain excluded.
- `Thinkpad/local/share/solace/bin/solace-refresh-pacman` overwrites pacman config and mirrorlist and must remain excluded.
- `config/hypr/input.conf` currently contains a suspicious `scroll_touchpad` window rule and should be replaced with verified input syntax.
