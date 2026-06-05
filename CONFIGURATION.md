# Solace Configuration Guide

This repo is meant to recreate the desktop from the captured `Thinkpad/`
snapshot. For UI, UX, desktop, theme, and application config, treat
`Thinkpad/` as the source of truth unless a file is explicitly overridden by
the installer.

## Install Map

The config installer is [install/20-configs.sh](install/20-configs.sh). These
are the important source-to-destination mappings:

| Repo source | Installed destination | Purpose |
| --- | --- | --- |
| `Thinkpad/config/<name>` | `~/.config/<name>` | User config for Hyprland, Waybar, terminals, GTK, Walker, etc. |
| `Thinkpad/local/share/solace/applications` | `~/.local/share/solace/applications` | Desktop entries and app icons managed by Solace helpers. |
| `Thinkpad/local/share/solace/config` | `~/.local/share/solace/config` | Default config templates used by refresh helpers. |
| `Thinkpad/local/share/solace/default` | `~/.local/share/solace/default` | Shared defaults, Hyprland modules, Waybar scripts, and SDDM assets. |
| `Thinkpad/local/share/solace/themes` | `~/.local/share/solace/themes` | Bundled themes and wallpapers. |
| `Thinkpad/local/share/solace/bin` | `~/.local/share/solace/bin` | Solace helper scripts. Most are symlinked into `~/.local/bin`. |
| `Thinkpad/local/share/fonts` | `~/.local/share/fonts` | Bundled local fonts, including `solace.ttf`. |
| `packages/pacman.txt` | Installed with pacman | Official Arch packages. |
| `packages/aur.txt` | Installed with AUR helper | AUR packages only. |

The installer intentionally overwrites the captured monitor config with
[config/hypr/monitors.conf](config/hypr/monitors.conf), because the ThinkPad
snapshot contains hardware-specific display names.

## Hyprland

Main source file:

- `Thinkpad/config/hypr/hyprland.conf` -> `~/.config/hypr/hyprland.conf`

The main config sources both Solace defaults and user overrides:

- `Thinkpad/local/share/solace/default/hypr/*.conf` -> shared defaults
- `Thinkpad/config/hypr/*.conf` -> installed user overrides

Common edits:

| What to change | Edit this repo file |
| --- | --- |
| Keybindings | `Thinkpad/config/hypr/bindings.conf` |
| Startup apps | `Thinkpad/config/hypr/autostart.conf` |
| Gaps, borders, opacity, blur | `Thinkpad/config/hypr/looknfeel.conf` |
| Keyboard, mouse, touchpad | `Thinkpad/config/hypr/input.conf` |
| Window rules | `Thinkpad/config/hypr/hyprland.conf` or `Thinkpad/local/share/solace/default/hypr/windows.conf` |
| Generic monitor fallback | `config/hypr/monitors.conf` |

Avoid putting machine-specific monitor descriptors into the default Solace
config. Put those in a machine profile instead.

## Waybar

Source files:

- `Thinkpad/config/waybar/config.jsonc` -> `~/.config/waybar/config.jsonc`
- `Thinkpad/config/waybar/style.css` -> `~/.config/waybar/style.css`
- `Thinkpad/local/share/solace/default/waybar` -> `~/.local/share/solace/default/waybar`

Waybar icons depend on:

- `ttf-jetbrains-mono-nerd` from `packages/pacman.txt`
- `Thinkpad/local/share/fonts/solace.ttf` for the Solace logo glyph

If icons render as boxes, check the font package list and that
`~/.local/share/fonts/solace.ttf` exists after install.

## Themes

Bundled themes live here:

- `Thinkpad/local/share/solace/themes/<theme-name>`

The currently selected captured theme lives here:

- `Thinkpad/config/solace/current/theme`
- `Thinkpad/config/solace/current/theme.name`

Installed paths:

- `~/.local/share/solace/themes/<theme-name>`
- `~/.config/solace/current/theme`
- `~/.config/solace/current/theme.name`

Theme files commonly include:

- `colors.toml`
- `waybar.css`
- `hyprland.conf`
- `hyprlock.conf`
- `kitty.conf`
- `ghostty.conf`
- `alacritty.toml`
- `walker.css`
- `swayosd.css`
- `backgrounds/*`

To change the default first-boot theme, update
`Thinkpad/config/solace/current/theme.name` and replace
`Thinkpad/config/solace/current/theme` with the desired theme files.

## Wallpapers

Hyprland starts the desktop background from:

- `~/.config/solace/current/background`

That is expected to be a symlink to an image. The installer seeds it from:

- `Thinkpad/config/solace/current/theme/backgrounds/wallhaven-dpepjo.jpg`

To change the default wallpaper, either:

1. Replace `Thinkpad/config/solace/current/theme/backgrounds/wallhaven-dpepjo.jpg`.
2. Or edit `seed_desktop_background` in [install/20-configs.sh](install/20-configs.sh) to point at a different bundled image.

Additional theme wallpapers live under:

- `Thinkpad/local/share/solace/themes/<theme-name>/backgrounds`

The helper commands installed on the target system are:

- `solace-theme-bg-set <path>`
- `solace-theme-bg-next`

## Lock Screen

Hyprlock config:

- `Thinkpad/config/hypr/hyprlock.conf` -> `~/.config/hypr/hyprlock.conf`

Theme-specific lock colors/assets:

- `Thinkpad/config/solace/current/theme/hyprlock.conf`
- `Thinkpad/local/share/solace/themes/<theme-name>/hyprlock.conf`
- `Thinkpad/local/share/solace/themes/<theme-name>/unlock.png`

The lock screen background uses the same current wallpaper symlink:

- `~/.config/solace/current/background`

## SDDM Login

Login visuals are installed by [install/35-login.sh](install/35-login.sh).
Bootloader and boot splash configuration is intentionally not managed.

Source files:

| Repo source | Installed destination |
| --- | --- |
| `Thinkpad/local/share/solace/default/sddm/solace` | `/usr/share/sddm/themes/solace` |
| `config/login/sddm/10-wayland.conf` | `/etc/sddm.conf.d/10-wayland.conf` |
| `config/login/sddm/hyprland.conf` | `/usr/share/sddm/hyprland.conf` |
| `config/login/wayland-sessions/solace.desktop` | `/usr/local/share/wayland-sessions/solace.desktop` |

To change login visuals, edit the SDDM theme source under
`Thinkpad/local/share/solace/default/sddm`.

## Terminal And App Config

Most terminal configs come from the ThinkPad snapshot:

- `Thinkpad/config/alacritty` -> `~/.config/alacritty`
- `Thinkpad/config/kitty` -> `~/.config/kitty`
- `Thinkpad/config/ghostty` -> `~/.config/ghostty`
- `Thinkpad/local/share/solace/config/foot` -> template/default for Foot

Other copied app configs include:

- `Thinkpad/config/gtk-3.0`
- `Thinkpad/config/gtk-4.0`
- `Thinkpad/config/walker`
- `Thinkpad/config/swayosd`
- `Thinkpad/config/btop`
- `Thinkpad/config/fastfetch`
- `Thinkpad/config/fcitx5`
- `Thinkpad/config/zed`
- `Thinkpad/config/tmux`
- `Thinkpad/config/wiremix`

If a UI setting should carry across fresh installs, update the matching file in
`Thinkpad/config`.

## Helper Scripts

Solace helpers live here:

- `Thinkpad/local/share/solace/bin`

The installer copies the full directory to:

- `~/.local/share/solace/bin`

Most helpers are then linked into:

- `~/.local/bin`

Some boot, drive, hibernation, snapshot, Limine, and pacman helpers are copied
but intentionally left out of `PATH` because they can be system-destructive or
hardware-specific.

Repo-local helper overrides live in:

- `config/scripts`

These are installed directly into `~/.local/bin`. Use this directory for small
Solace-owned compatibility wrappers such as `xdg-terminal-exec`.

## Fonts

Font packages are listed in:

- `packages/pacman.txt`

Important font packages:

- `ttf-jetbrains-mono-nerd`
- `noto-fonts`
- `noto-fonts-cjk`
- `noto-fonts-emoji`
- `woff2-font-awesome`

Bundled local font:

- `Thinkpad/local/share/fonts/solace.ttf` -> `~/.local/share/fonts/solace.ttf`

The installer runs `fc-cache -f ~/.local/share/fonts` after copying bundled
fonts.

## User Services

User service files come from:

- `Thinkpad/config/systemd/user`

Installed destination:

- `~/.config/systemd/user`

Services enabled by [install/30-services.sh](install/30-services.sh):

- `elephant.service`
- `solace-recover-internal-monitor.service`
- `swayosd-server.service`
- `solace-battery-monitor.timer` when a battery is present

## Package Lists

Official Arch packages:

- `packages/pacman.txt`

AUR packages:

- `packages/aur.txt`

Before adding a package to `aur.txt`, check whether it is available in official
Arch repos. Keep Omarchy-only packages out of `pacman.txt`; if Solace needs the
behavior, add a Solace-owned helper under `config/scripts` or
`Thinkpad/local/share/solace/bin`.

## Unsafe Or Filtered Snapshot Parts

The config installer skips these top-level default asset directories:

- `limine`
- `pacman`
- `plymouth`
- `snapper`
- `systemd`
- `udev`

Those are kept in the snapshot for reference, but they are not copied into
`~/.local/share/solace/default` by the default config install.

Bootloader, storage, hibernation, snapshot, Plymouth, and direct-boot helper
scripts are also removed from the installed Solace helper path.

## Test Changes

Useful dry-runs:

```bash
./install.sh --dry-run --only configs
./install.sh --dry-run --only services
./install.sh --dry-run --only login
```

After changing package lists, verify that official packages really exist in
Arch repos:

```bash
while read -r pkg; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
  pacman -Si "core/$pkg" >/dev/null 2>&1 ||
    pacman -Si "extra/$pkg" >/dev/null 2>&1 ||
    pacman -Si "multilib/$pkg" >/dev/null 2>&1 ||
    printf '%s\n' "$pkg"
done < packages/pacman.txt
```

The command should print nothing.
