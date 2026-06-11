# Displays And Docks

Monitor setup lives in:

`~/.config/hypr/monitors.conf`

## Hyprmon

Use the DisplayLink Waybar indicator or open Hyprmon directly to configure
monitor layouts from a TUI.

## DisplayLink

DisplayLink support is installed and enabled when the `evdi-dkms` and
`displaylink` packages are present. The Waybar DisplayLink indicator shows dock
state and monitor count.

## Quick fallback

If a monitor layout gets weird, leave only the generic fallback active:

```conf
monitor=,preferred,auto,1
```

