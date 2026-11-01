# Desktop portability review — November 2026

This reconciliation captures the audited working desktop without transferring
the source laptop's accounts, network connections, hardware identity or full
personal software collection. It is a reviewable change set, not a tested Surface
image, and has not been applied to the running source laptop.

## Preserved experience

- Existing shared keybindings and active Waybar/VPN widget configuration.
- Solace palette, bundled current wallpaper and visible lock screen on every output.
- Actual lock-state/stale-lock handling from the running helper.
- Adwaita icons, generated GTK palette and reviewed VSCode preferences.
- Current Neovim theme loader/transparency behavior and plugin lockfile.
- Input/btop preferences and an optional SDR decoding alias.
- Local VPN indicator improvement, plus GitHub's opencode package addition.

## Deliberate portability/safety changes

- Generic displays, no source-monitor/workspace/MAC/UUID/network profiles.
- Lid behavior selected early in the installer, with an internal-panel-only helper.
- One hypridle lifecycle, rather than both compositor autostart and a service.
- Existing user configs preserved by default; replacement is explicit and backed up.
- No keyring overwrite, PAM edits, network-manager switch or unsolicited tool services.
- Boot visuals off by default and rejected on encrypted/Secure-Boot systems.
- Four base AUR packages; personal apps, development, DisplayLink, security, SDR
  and gaming packages are optional groups. Headers follow the target's kernel.
- Account/session/cache files removed, home paths made portable, captured current
  theme output no longer used as a fresh-install source.
- Legacy copied-assets update/first-run paths guarded; invalid Neovim JSON fixed;
  absent Elephant Lua menus no longer create a wildcard symlink.

## Not copied

Wi-Fi/VPN/account profiles; browser/editor storage; keyrings or private keys;
Syncthing identity; firewall/printer definitions; ThinkPad monitor layout and AMD
drivers; debug builds; untracked machine binaries. Additional personal applications
can be selected independently; their entire state directories are not defaults.

## Review and deployment gates

Automated tests cover isolated config installation under another home path,
rerun preservation, explicit replacement/backup, dry-run/argument handling,
mocked service boundaries, editor JSON and internal-only DPMS targeting.
They never run real sudo/systemctl operations or apply the desktop to this laptop.

Remaining checks: fresh Arch VM installation; current AUR builds; graphical login,
theme rendering, lock/unlock and suspend; physical DisplayLink/hotplug; Surface
hardware and the separately approved encrypted/signed boot design. Optional apps'
keybinds need their selected packages. GTK/theme screenshots should be checked on
the fresh test installation, not by replacing the working laptop's settings.

Review `git diff` and untracked additions on `reconcile/desktop-portability` before
any commit or push. The branch starts from the local VPN-fix commit; GitHub's
opencode addition is incorporated as content, not yet as a merge commit. Recheck
remote history before publishing; no force push is necessary or intended.
