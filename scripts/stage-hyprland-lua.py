"""Stage modular native Lua from reviewed legacy sources; never activate/reload."""

import argparse
import glob
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess


SOURCE = re.compile(r"^\s*source\s*=\s*(.*?)\s*(?:#.*)?$")
VARIABLE = re.compile(r"\$([A-Za-z_][A-Za-z0-9_-]*)")
DEFINITION = re.compile(r"^\s*\$([A-Za-z_][A-Za-z0-9_-]*)\s*=")


def lua_quote(value):
    if any(ord(char) < 32 or ord(char) == 127 for char in value):
        raise ValueError("Control characters in Lua paths/keys require manual review")
    # Lua accepts UTF-8 strings, not JSON's \uXXXX escapes.
    return json.dumps(value, ensure_ascii=False)


class Stage:
    def __init__(self, home, output):
        self.home = Path(home).resolve()
        self.output = Path(output).absolute()
        self.sources = {}
        self.bridge = {}
        self.replacements = {}
        self.adjustments = []
        self.toggle_dir = self.home / ".local/state/solace/toggles/hypr"
        self.toggle_defaults = self.home / ".local/share/solace/default/hypr/toggles"

    def confined(self, path):
        path = Path(os.path.abspath(path))
        lua_quote(str(path))
        if not path.is_relative_to(self.home) or not path.resolve().is_relative_to(self.home):
            raise ValueError(f"Source outside the home directory requires manual review: {path}")
        return path

    def module_path(self, path):
        return self.output / "modules" / path.relative_to(self.home).with_suffix(".lua")

    def include_paths(self, value, parent):
        value = value.replace("${HOME}", str(self.home)).replace("$HOME", str(self.home))
        if value.startswith("~/"):
            value = str(self.home / value[2:])
        if "$" in value or any(c in value for c in "\r\n\0"):
            raise ValueError("Dynamic include paths require manual review")
        path = self.confined(value if value.startswith("/") else parent / value)
        return path

    def visit(self, path, stack=()):
        path = self.confined(path)
        if path in stack:
            raise ValueError(f"Include cycle: {path}")
        if path in self.sources:
            return
        if len(self.sources) >= 256 or path.suffix != ".conf":
            raise ValueError("Only bounded legacy .conf include graphs can be staged")
        data = path.read_bytes()
        if len(data) > 262144:
            raise ValueError("Configuration source is too large; review it manually")
        self.sources[path] = data
        links = {}
        for index, line in enumerate(data.decode().splitlines()):
            match = SOURCE.match(line)
            if not match:
                continue
            target = self.include_paths(match[1], path.parent)
            theme = self.home / ".config/solace/current/theme"
            if target in (theme / "hyprland.conf", theme / "gum.env.conf"):
                native = target.with_suffix(".lua")
                self.confined(native)
                if not native.is_file():
                    raise ValueError("Install the shared native Lua palette templates before staging")
                self.bridge[native] = hashlib.sha256(native.read_bytes()).hexdigest()
                links[index] = f"dofile({lua_quote(str(native))})"
            elif target == self.toggle_dir / "*.conf":
                flags = sorted(self.toggle_defaults.glob("*.conf"))
                if not flags:
                    raise ValueError("Native toggle staging requires the shared toggle presets")
                known = {flag.name for flag in flags}
                if any(flag.name not in known for flag in self.toggle_dir.glob("*.conf")):
                    raise ValueError("Unknown enabled toggle requires manual review")
                blocks = []
                for flag in flags:
                    active = self.toggle_dir / flag.name
                    if active.exists() and active.read_bytes() != flag.read_bytes():
                        raise ValueError("Customized enabled toggle requires manual review")
                    self.visit(flag, (*stack, path))
                    blocks.append("do local flag = io.open(" + lua_quote(str(active)) + ', "r"); if flag then flag:close(); dofile(' + lua_quote(str(self.module_path(flag))) + ") end end")
                links[index] = "\n".join(blocks)
            else:
                children = [self.confined(child) for child in sorted(glob.glob(str(target)))]
                if not children and not glob.has_magic(str(target)):
                    raise ValueError(f"Missing include: {target}")
                for child in children:
                    self.visit(child, (*stack, path))
                links[index] = "\n".join(f"dofile({lua_quote(str(self.module_path(child)))})" for child in children)
        self.replacements[path] = links

    def check_variables(self):
        # Independent Lua modules do not share legacy variable scope. Do not
        # silently reinterpret a known config variable as a shell environment var.
        known = {match[1] for data in self.sources.values() for line in data.decode().splitlines()
                 if (match := DEFINITION.match(line))}
        for path, data in self.sources.items():
            local = set()
            for line in data.decode().splitlines():
                if line.lstrip().startswith("#"):
                    continue
                definition = DEFINITION.match(line)
                refs = set(VARIABLE.findall(line))
                if definition:
                    refs.discard(definition[1])
                if (refs & known) - local:
                    raise ValueError(f"Cross-module or forward variable reference requires manual review: {path}")
                if definition:
                    local.add(definition[1])

    def reviewed(self, path):
        lines, injections = [], {}
        for index, line in enumerate(self.sources[path].decode().splitlines()):
            injection = self.replacements[path].get(index)
            unbind = re.match(r"^\s*unbind\s*=\s*([^,]*),\s*([^#]+?)\s*(?:#.*)?$", line)
            if unbind:
                modifiers, key = (part.strip() for part in unbind.groups())
                if modifiers and any(mod not in {"SUPER", "SHIFT", "CTRL", "ALT", "MOD2", "MOD3", "MOD5"} for mod in modifiers.split()):
                    raise ValueError("Unknown unbind modifier requires manual review")
                chord = " + ".join([*modifiers.split(), key])
                injection = f"hl.unbind({lua_quote(chord)})"
                self.adjustments.append({"source": str(path.relative_to(self.home)), "line": index + 1, "kind": "native-unbind"})
            if injection is not None:
                marker = "SOLACE_STAGE_" + hashlib.sha256((str(path) + ":" + str(index)).encode()).hexdigest()
                lines.append("# " + marker)
                injections["-- " + marker] = injection
                continue
            if line.strip() == "enabled = yes, please :)":
                line = "  enabled = true"
                self.adjustments.append({"source": str(path.relative_to(self.home)), "line": index + 1, "kind": "boolean-normalization"})
            layer = re.match(r"^\s*layerrule\s*=\s*no_anim on,\s*match:namespace\s+(\S+)\s*$", line)
            if layer:
                lines.extend(["layerrule {", "  no_anim = true", "  match:namespace = " + layer[1], "}"])
                self.adjustments.append({"source": str(path.relative_to(self.home)), "line": index + 1, "kind": "layer-rule-normalization"})
            else:
                lines.append(line)
        return "\n".join(lines) + "\n", injections

    def write(self, entry, converter, converter_sha256, compositor="Hyprland"):
        converter = Path(converter).resolve()
        if not re.fullmatch(r"[a-f0-9]{64}", converter_sha256) or hashlib.sha256(converter.read_bytes()).hexdigest() != converter_sha256:
            raise ValueError("Converter binary checksum mismatch; no code was executed")
        if self.output.exists() or self.output.is_symlink():
            raise ValueError("Existing stage output is preserved; choose a fresh path")
        self.check_variables()
        self.output.mkdir(parents=True, mode=0o700)
        manifest = {"activated": False, "verified": False, "converter_sha256": converter_sha256,
                    "sources": {str(path.relative_to(self.home)): hashlib.sha256(data).hexdigest() for path, data in self.sources.items()},
                    "live_palette_bridges": {str(path): digest for path, digest in self.bridge.items()}, "adjustments": self.adjustments}
        record = self.output / "manifest.json"
        record.write_text(json.dumps(manifest, indent=2) + "\n")
        for path, data in self.sources.items():
            original = self.output / "originals" / path.relative_to(self.home)
            original.parent.mkdir(parents=True, exist_ok=True)
            original.write_bytes(data)
            source, injections = self.reviewed(path)
            result = subprocess.run([str(converter), "--check", "--report", "--no-merge", "--no-polyfill"],
                                    input=source, text=True, capture_output=True, timeout=30)
            module = self.module_path(path)
            module.parent.mkdir(parents=True, exist_ok=True)
            module.with_suffix(".report.txt").write_text(result.stderr)
            if result.returncode:
                raise ValueError(f"Converter requested review for {path}; stage retained, not activated")
            output = result.stdout
            for marker, replacement in injections.items():
                if output.count(marker) != 1:
                    raise ValueError("Converter did not preserve the module boundary marker")
                output = output.replace(marker, replacement)
            module.write_text(output)
        top = self.output / "hyprland.lua"
        top.write_text("-- Staged modular configuration. Not installed or activated automatically.\n" +
                       f"dofile({lua_quote(str(self.module_path(entry)))})\n")
        runtime = self.output / "verify-runtime"
        runtime.mkdir(mode=0o700)
        env = {key: value for key, value in os.environ.items() if key not in {"HYPRLAND_INSTANCE_SIGNATURE", "WAYLAND_DISPLAY"}}
        env["XDG_RUNTIME_DIR"] = str(runtime)
        result = subprocess.run([compositor, "--verify-config", "-c", str(top)], env=env, text=True, capture_output=True, timeout=30)
        (self.output / "verify.log").write_text(result.stdout + result.stderr)
        manifest["verified"] = result.returncode == 0
        record.write_text(json.dumps(manifest, indent=2) + "\n")
        if result.returncode:
            raise ValueError("Compositor verification failed; stage retained, original session unchanged")
        return top


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Write and verify a separate stage, never activate it")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--converter", type=Path)
    parser.add_argument("--converter-sha256")
    args = parser.parse_args()
    stage = Stage(Path.home(), args.output)
    entry = stage.home / ".config/hypr/hyprland.conf"
    stage.visit(entry)
    stage.check_variables()
    if not args.apply:
        print(f"Preview: {len(stage.sources)} legacy sources, {len(stage.bridge)} live palette bridges; no files written or processes executed")
        return
    if not args.converter or not args.converter_sha256:
        raise ValueError("Apply requires an explicitly reviewed converter executable and its SHA256")
    print(stage.write(entry, args.converter, args.converter_sha256))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        raise SystemExit(f"ERROR: {error}")
