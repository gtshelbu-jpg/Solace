# Package groups

`pacman.txt` and `aur.txt` install the shared desktop and core workflow. Kernel,
microcode, graphics drivers, bootloader and network configuration belong to the
base Arch install. The base includes tmux and editor helper dependencies, but not
the daily-driver's complete personal software inventory.

Select optional groups with repeated `--with NAME`:

| Group | Scope |
| --- | --- |
| `apps` | Music, notes, OBS, extra browsers, LocalSend, chat, file-manager integration |
| `development` | VSCode binary, Zed, Docker package, Java and extra terminal tools |
| `displaylink` | DKMS/evdi/DisplayLink; matching kernel headers required separately |
| `security` | Selected Arch/AUR security/network tools; no BlackArch bootstrap |
| `sdr` | SDR/decoder tools and serial/USB utilities |
| `gaming` | Streaming, Wine and VR; GPU-specific/multilib prerequisites are separate |

Drawing tablet support remains separately selectable with `--tablet`.
Optional services are not enabled by Solace unless explicitly documented
(DisplayLink is enabled when its group is selected). Package hooks/presets still
run during normal Arch/AUR package installation, so inspect packages as usual.

Debug packages, inactive tuned configuration, source-machine drivers, VPN accounts,
printing definitions and the daily-driver's incidental dependencies are not copied.
These are package selections, not bit-for-bit version-locked system manifests.
Optional AUR groups need build/availability testing before deployment.
