# Reference notes from `Thinkpad/`

This folder holds extracted notes and references from the `Thinkpad/` snapshot. It should not contain active configuration used by the installer; rather, copy or adapt files from `Thinkpad/` into `config/` or `machine/thinkpad/` when they are verified safe and generic.

Next steps:
- Review `Thinkpad/` and classify files into reusable vs machine-specific.
- Move generic Hyprland/Waybar/launcher configs into `config/`.
- Keep monitor and dock display profiles under `machine/thinkpad/` to avoid applying them blindly.

Warnings:
- Monitor/display configurations can black-screen systems if applied blindly. Keep them machine-specific and require confirmation before use.
- Do not reintroduce Omarchy repos, mirrors, or branding.
