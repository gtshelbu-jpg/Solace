"""Seed reviewed Lua modules for a NEW home only. Never migrate existing users."""
import json
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile


def install(source, home):
    home = home.resolve()
    state = home / ".local/state/solace"
    pending = state / "native-defaults.pending"
    if pending.exists():
        raise ValueError("A previous native-default validation failed; review retained modules before retrying")
    manifest = json.loads((source / "manifest.json").read_text())
    for name, digest in manifest["sources"].items():
        path = home / name
        if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise ValueError("Legacy defaults differ from reviewed native inputs: " + name)
    for name, digest in manifest["modules"].items():
        path = source / "home" / name
        if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise ValueError("Native module build integrity failure: " + name)
        target = home / name
        if target.exists() or target.is_symlink() or not target.resolve().is_relative_to(home):
            raise ValueError("Existing/unconfined native module preserved: " + name)
    # All conflicts/integrity checks finish before creating any native modules.
    state.mkdir(parents=True, exist_ok=True)
    pending.write_text("Native defaults are staged but compositor verification is incomplete.\n")
    for name in manifest["modules"]:
        target = home / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes((source / "home" / name).read_bytes())
        if name.startswith(".config/hypr/"):
            default = home / ".local/share/solace/config/hypr" / Path(name).name
            default.parent.mkdir(parents=True, exist_ok=True)
            default.write_bytes(target.read_bytes())
    with tempfile.TemporaryDirectory(prefix="solace-native-verify-") as runtime:
        env = {key: value for key, value in os.environ.items() if key not in {"WAYLAND_DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE"}}
        env["HOME"] = str(home)
        env["XDG_RUNTIME_DIR"] = runtime
        subprocess.run(["Hyprland", "--verify-config", "-c", str(home / ".config/hypr/hyprland.lua")],
                       env=env, check=True, timeout=30)
    (state / "native-defaults.json").write_text(json.dumps(manifest, indent=2) + "\n")
    pending.unlink()


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    install(root / "config/hypr-native", Path.home())
