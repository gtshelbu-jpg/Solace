# Review notes from `Thinkpad/`

This folder holds review notes derived from the `Thinkpad/` snapshot. The snapshot is the source capture of the desired Solace desktop experience; UX/UI/GUI config should be promoted into active install paths after filtering out hardware-specific, distro-overlay, mirror, bootloader, and machine recovery pieces.

Next steps:
- Review `Thinkpad/` and classify files into reusable UX vs machine-specific or unsafe system behavior.
- Promote generic Hyprland/Waybar/launcher/theme/app configs into `config/`.
- Keep monitor and dock display profiles under `machine/thinkpad/` to avoid applying them blindly.

Warnings:
- Monitor/display configurations can black-screen systems if applied blindly. Keep them machine-specific and require confirmation before use.
- Do not reintroduce Omarchy repos, mirrors, or branding.
