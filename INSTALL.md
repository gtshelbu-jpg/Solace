# Installing Solace

Solace is a desktop bootstrap for an **already bootable Arch installation**.
It does not partition disks, configure encryption, enroll Secure Boot keys, or
configure your network. Base installation and network connectivity are your
responsibility. Run as your regular sudo-capable user, **not** `sudo ./install.sh`.

## Before installation

- Back up existing data and configuration. Have bootable Arch recovery media.
- Install Arch with your chosen kernel, microcode, graphics, bootloader, filesystems
  and working internet access. Configure Wi-Fi/networking on the target; no saved
  network connection or credential from the source laptop is distributed.
- Confirm the base system boots. For encrypted/Secure-Boot installs, verify unlock,
  recovery and signed update behavior before installing a desktop.
- Clone the reviewed Solace revision. AUR packages require build access and are
  not pinned to an immutable release; review their build recipes.

## Preview and install

```bash
./install.sh --dry-run
./install.sh
```

Near the start, the installer asks about **lid-close behavior** and optional drawing
tablet support, before packages or system settings are changed. Lid choices:

| Choice | Behavior |
| --- | --- |
| `docked` | Suspend undocked; keep running with external displays (interactive default) |
| `suspend` | Suspend whenever the lid closes |
| `awake` | Stay running; only blank the internal laptop panel |
| `keep` | Do not change the existing system lid/suspend policy |

The Hyprland lid handler detects the internal connector; it does not assume
`eDP-1` or power down external displays. Lid policy is written to a logind drop-in
and takes effect after **reboot**; the installer does not restart logind in your
active session. Existing later-sorting administrator drop-ins/inhibitors may
override this policy. Locking alone always keeps the Solace lock screen visible.

Explicit/non-interactive example:

```bash
./install.sh --lid-policy docked --no-tablet
```

Without a terminal, an install that includes services requires an explicit lid
choice. Dry-runs never prompt and default to `keep` unless specified.

## Optional applications and hardware

The base desktop intentionally omits personal apps, VSCode/Zed, Docker, SDR,
security tooling, VR and DisplayLink. Repeat `--with` to select groups:

```bash
./install.sh --with apps --with development
./install.sh --with displaylink --lid-policy awake
./install.sh --only packages --with security --with sdr --no-tablet
```

See [packages/README.md](packages/README.md) for manifests. Optional apps' keybinds
are retained, but launch successfully only when those apps are installed. Packages
may ship their own service presets/hooks; Solace itself does not enable tool
daemons, SSH, VPNs, Docker or discovery services just because a group is selected.

For DisplayLink, install **headers matching your chosen installed kernel(s)**
first. Do not substitute stock `linux-headers` for a Surface/LTS/custom kernel.
Secure Boot additionally requires an approved module-signing/trust policy; that
is not configured by Solace. Avoid the group until those prerequisites are met.

## Existing configurations and updates

- Existing user configs, shell startup, selected theme and wallpaper are preserved
  by default. Missing defaults are seeded; Solace-managed runtime assets are updated.
- To deliberately replace captured user preferences, use `--replace-configs`.
  This replaces whole managed config directories, not individual settings. Review
  and back up first; do not use it casually on a daily-driver installation.
- Existing keyrings and PAM configuration are never replaced. Keyring setup/unlock
  follows the distribution and user account configuration.
- Exactly one hypridle lifecycle is installed: `hypridle.service`. When migrating
  an old installation, an already-running duplicate may remain until logout/reboot;
  the installer does not kill session processes.
- Runtime `~/.local/share/solace` is copied content, not a Git checkout. Update the
  **source checkout**, inspect its diff, then rerun the reviewed installer. The
  legacy Git update helper now explains this instead of attempting a pull/reset.

```bash
./install.sh --dry-run --only configs
./install.sh --only configs
# Only after explicitly reviewing which existing preferences will be replaced:
./install.sh --only configs --replace-configs
```

Other stages: `packages`, `services`, `login`, `boot`, `postinstall`.
If an existing `.bashrc` was preserved and you want Solace's Starship prompt,
opt in with `./install.sh --only configs --bash-prompt`. This backs up `.bashrc`
and adds only guarded Starship initialization, without changing your login shell
or replacing aliases. Symlinked startup files require manual integration. New
interactive Bash shells pick up the prompt; already-configured Solace Bash
startup is left unchanged. The installed `solace-setup-bash-prompt` helper provides
the same explicit operation without rerunning the configuration stage.

The login stage installs SDDM/Solace, disables the known autologin drop-in, and
enables graphical login. Inspect custom display-manager/autologin setups first.

The Solace SDDM theme includes a **Session** selector below the password field.
Click it to cycle installed sessions, or focus it with Tab and use the arrow keys.
Enter in the password field logs into the displayed session. The exact standard
`Solace (Hyprland uwsm)` entry is the initial default when available; additional
Solace-named test sessions do not silently take precedence.

The selector's Qt Quick tests can run without a display or real authentication
when Qt 6 development/test tools and SDDM's QML components are installed:

```bash
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  /usr/lib/qt6/bin/qmltestrunner -input tests/tst_sddm_session.qml
```

## Boot visuals are separate and opt-in

The default installer **does not touch boot files**. Optional legacy boot theming:

```bash
./install.sh --dry-run --only boot --boot-visuals
```

For a real run, install Plymouth separately first. This stage changes mkinitcpio,
Plymouth and supported Limine configuration and may rebuild boot artifacts.
It is **not supported on encrypted-root or Secure-Boot-enabled systems**; guards
reject those cases. No signing/encryption integration is implemented. Leave this
stage disabled for the planned Solace Black deployment.

## Validation and recovery

```bash
python -m unittest discover -s tests -v
git diff --check
```

Tests use disposable homes below `/tmp/opencode`, with system operations mocked.
They are not a substitute for a fresh VM/install or physical hardware testing.

Real installs save replaced targets under
`~/.config-backups/solace-TIMESTAMP-PID/`, preserving their relative paths.
Restore only the reviewed affected target, not the entire home or `/etc`.
Backups are not an automatic rollback of pacman transactions or service state;
record those before a real deployment. For boot recovery, use the independent
base-OS recovery procedure and known-good boot media. Never put LUKS recovery
material, signing keys or backups containing secrets into this repository.

After installation, reboot and check SDDM login, lock/unlock, lid behavior,
idle locking, selected theme, networking, sound and display hotplug.
