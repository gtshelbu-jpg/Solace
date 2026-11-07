# Native Lua migration staging

Hyprland versions that no longer parse legacy `.conf` files need a real native
configuration, not merely renamed files. The shared installer still needs final
native-session promotion work; a working staging session does not establish
fresh-install readiness. Do not upgrade a working legacy compositor solely on
the strength of conversion or unit tests.

## Separate, reversible candidate

`scripts/stage-hyprland-lua.py` builds a **separate modular candidate** from the
reachable `~/.config/hypr/hyprland.conf` source graph. It does not install files
into the active config tree, reload a compositor, switch sessions, install a
converter, download anything or alter packages, boot configuration or display
manager settings. Use it as the desktop user, with a reviewed converter binary.

```bash
# Read-only graph/compatibility preview. No converter/compositor execution.
python3 scripts/stage-hyprland-lua.py --output "$HOME/.local/state/solace/lua-candidate"

# Explicit staging/verification. Supply the independently reviewed binary hash,
# not a checksum taken from an untrusted download in the same step.
python3 scripts/stage-hyprland-lua.py --apply \
  --output "$HOME/.local/state/solace/lua-candidate" \
  --converter /path/to/reviewed/hyprlang2lua \
  --converter-sha256 REVIEWED_64_CHARACTER_SHA256
```

The converter interface uses `--check --report --no-merge --no-polyfill`. An
upstream converter is [hyprlang2lua](https://github.com/EIonTusk/hyprlang2lua);
review and pin its source/build separately. A matching binary hash proves which
executable was used, not that it is trustworthy or correct.

## Preservation and dynamic layers

- Each reachable source gets an original copy and SHA256 in the private stage.
  Existing output paths are refused, never deleted or overwritten.
- Includes remain separate Lua modules in source order. Missing includes, cycles,
  paths outside the home tree and cross-module/forward legacy variables require
  explicit review instead of silently changing their meaning.
- The current native `hyprland.lua` and `gum.env.lua` palette outputs stay live
  bridges, rather than being frozen into a converted palette snapshot.
- Shared toggle presets are staged as native modules. Existing `.conf` toggle
  presence remains the state marker, checked on every config load without shell
  glob execution. Unknown or customized enabled toggles require manual review.
- Static unbinds use `hl.unbind` in their original order. The known legacy boolean
  spelling and old no-animation layer-rule form are normalized and recorded.
- All other leaf modules are staged snapshots, not an automatic replacement for
  editable user/native config files. Changing their original `.conf` files after
  staging does not update the candidate. Restage deliberately and inspect diffs.

After conversion, the installed compositor runs `--verify-config` with an
isolated runtime directory and no inherited active-instance identifiers. Output
and reports stay local. The manifest records `verified` and always leaves
`activated: false`. Verification evaluates Lua; it is **not a sandbox** for
untrusted hand-written Lua palette files or third-party converter executables.

## Promotion remains a separate test

Audit effective bindings, descriptions, flags and startup commands. Test toggle
combinations, theme changes and monitor policy without modifying live state.
Then use a separate test session with the original session retained. Verify real
startup, keybindings, lock/unlock, app launching, display hotplug, reloads and
runtime helpers before promoting native defaults into the regular installer.
`--verify-config` does not prove those interactive behaviors.
