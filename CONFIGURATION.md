# Solace configuration and portability

Solace distributes reviewed desktop preferences, **not a copy of a home directory**.
See [INSTALL.md](INSTALL.md) for installation, preservation and recovery policy.

## Active sources

For now, `Thinkpad/` is a historical directory name: its reviewed desktop content
is shared, not an instruction to apply ThinkPad hardware settings. The active
entry points are root `install.sh` and top-level `install/*.sh`. Nested installer
and migration sources under `Thinkpad/local/share/solace/install` are legacy
reference material and are not installed or executed by the desktop bootstrap.

| Source | Destination / policy |
| --- | --- |
| Selected `Thinkpad/config/<app>` | `~/.config/<app>`, preserved if already present |
| `Thinkpad/config/Code/User/settings.json` | That settings file only; no account/history/storage |
| `Thinkpad/config/solace/{branding,extensions,hooks,themed}` | Reviewed preferences/templates; excludes captured current theme state |
| `Thinkpad/config/aether/{blueprints,custom,theme}` | Reviewed presets/assets; no API/account/webview state |
| `Thinkpad/local/share/solace/{applications,config,default,themes,bin}` | Solace-managed runtime assets; updated with backups |
| `Thinkpad/local/share/aether/wallpapers` | Wallpaper assets only |
| `Thinkpad/local/share/fonts/*.{ttf,otf}` | Local Solace fonts, no generated font UUID |
| `config/scripts/*` | Compatibility wrappers in `~/.local/bin` |
| `config/hypr/monitors.conf` | Generic monitor fallback, not the source laptop's layout |
| `config/login/*` | SDDM and UWSM/Solace session definitions |
| `config/power/*` | Chosen lid policy and desktop power-key handling |

The exact app allowlist lives in `install/20-configs.sh`. Do not add a whole
application directory until its contents have been reviewed for credentials,
machine paths, caches, account/device identity and personal history.

## Everyday edits

- Hyprland overrides: `Thinkpad/config/hypr/{bindings,input,looknfeel,autostart}.conf`.
- Shared bindings/window rules/environment: `Thinkpad/local/share/solace/default/hypr`.
- Lid panel handling: `Thinkpad/config/hypr/lid.conf` plus
  `solace-hyprland-lid-display`; suspend policy belongs to logind, not the lock helper.
- Lock layout/auth preferences: `Thinkpad/config/hypr/hyprlock.conf`.
- Idle timeout: `Thinkpad/config/hypr/hypridle.conf`.
- Lock behavior: `Thinkpad/local/share/solace/bin/solace-system-lock`.
- Active Waybar defaults: `Thinkpad/config/waybar`; refresh defaults:
  `Thinkpad/local/share/solace/config/waybar`. Keep both intentional and consistent.
- Shell defaults: `Thinkpad/local/share/solace/default/bashrc` and `default/bash`.
  Existing `.bashrc` is preserved unless replacement is explicitly selected.
- Terminal/launcher/editor settings: the corresponding reviewed snapshot app.
- Neovim: `Thinkpad/config/nvim`, including plugin lockfile and the generated-palette
  loader at `lua/plugins/theme.lua`. Never append Lua to JSON configuration.
- Package choices: base manifests and optional groups under `packages/`.

Some compatibility files elsewhere in `config/` are legacy and not used by the
current copy flow. Trace `install/20-configs.sh` before editing a duplicate.

## Theme and wallpaper defaults

Fresh installs seed the **Solace** theme from
`Thinkpad/local/share/solace/themes/solace` and select
`backgrounds/wallhaven-nmmvvk.jpg`. Its palette matches the audited live system.
Required theme outputs are generated from the existing shared/user templates
without launching or restarting desktop applications during config copying.
GTK CSS imports the selected palette; Solace uses Adwaita icons.

The installer no longer forces an Aether bridge over the user's selection.
Existing `~/.config/solace/current/{theme,theme.name,background}` is preserved,
even with `--replace-configs`. Change themes explicitly using Solace's theme menu.
Bundled Aether blueprints use `@HOME@` placeholders expanded only when installed;
they must not capture an author's absolute home path. One old preset whose image
was not bundled now points at the bundled default image instead.

`Thinkpad/config/solace/current` remains a legacy captured reference, **not an
installation source**. Update named themes/templates rather than copying new
generated runtime files into that directory.

The selected theme is refreshed through existing desktop startup/theme helpers.
VSCode's generated theme extension follows those helpers when VSCode is installed.
No editor login, extension authentication, workspace database or browser profile
is distributed. Additional editor extensions can be installed independently.

## Exclusions

No source-machine Wi-Fi, NetworkManager, iwd, VPN, firewall, SSH, device identity,
or networkd configuration is captured. The installer leaves the target's chosen
network stack and services alone. Impala is an iwd-oriented UI; if the target uses
NetworkManager, keep using its own tools rather than switching managers implicitly.

No source monitor serials, workspace-to-connector mappings, MACs, partition UUIDs,
AMD-specific drivers or boot signing material are installed. Configure scaling,
graphics and firmware on the target. `machine/thinkpad/` is reserved for explicitly
reviewed opt-in hardware profiles, not automatically applied settings.

Do not commit keyrings, private keys, `.env`, webview databases/salts, Syncthing
identity, browser/editor account state, logs, backups, caches or full dconf binary
databases. `.gitignore` is a safety net, not a substitute for review or a secret
scan. Previously tracked session/font/printer/runtime state was removed in the
portability reconciliation; this does not rewrite existing Git history.

## Verification

Run `python -m unittest discover -s tests -v` for disposable-home config installation,
preservation/replacement backups, option validation, mocked service operations,
lid output targeting and dry-run checks. Run Bash/Lua/JSON syntax checks and
`git diff --check` before review. Physical lid/suspend/DisplayLink and first-login
visual checks still require a fresh target; repository-only changes are not
applied to the working laptop for screenshots.
