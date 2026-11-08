"""Publish reviewed portable Lua build outputs; never convert user configs at login.

Input is the reviewed JSON output of the strict modular staging/build process.
This is a maintainer code-generation step, not an installer/runtime dependency.
"""
import argparse
import hashlib
import json
from pathlib import Path


def generate(native, originals, output, replace_reviewed=False):
    native = {name: body.rstrip() + "\n" for name, body in native.items()}
    if output.exists():
        if not replace_reviewed:
            raise ValueError("Existing native defaults must be reviewed, not overwritten")
        previous = json.loads((output / "manifest.json").read_text())
        if set(previous["modules"]) != set(native):
            raise ValueError("Module set changed; preserve the old output for review")
        for name, digest in previous["modules"].items():
            if hashlib.sha256((output / "home" / name).read_bytes()).hexdigest() != digest:
                raise ValueError("A generated module was locally edited; preserve it")
    for name, body in native.items():
        path = Path(name)
        if path.is_absolute() or ".." in path.parts or path.suffix != ".lua":
            raise ValueError("Invalid native module path")
        if not (name.startswith(".config/hypr/") or name.startswith(".local/share/solace/default/hypr/")):
            raise ValueError("Module outside the reviewed default graph")
        if "/home/" in body or "/tmp/" in body or "hl.source(" in body:
            raise ValueError("Native defaults contain machine paths or legacy source calls")
    if ".config/hypr/hyprland.lua" not in native:
        raise ValueError("Missing native entry point")
    for name, body in native.items():
        path = output / "home" / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body)
    manifest = {
        "converter_commit": "86f47ab0c895f10e81175953b5792caee10c5760",
        "converter_sha256": "18d1ebf9b87f8f37fb450ee8b826139eae2746b9fd5aa096f419067395b08712",
        "sources": {name: hashlib.sha256(body.encode()).hexdigest() for name, body in originals.items()},
        "modules": {name: hashlib.sha256(body.encode()).hexdigest() for name, body in native.items()},
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--native-json", type=Path, required=True)
    parser.add_argument("--originals-json", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--replace-reviewed", action="store_true", help="Regenerate only if all existing module hashes match their manifest")
    args = parser.parse_args()
    generate(json.loads(args.native_json.read_text()), json.loads(args.originals_json.read_text()), args.output, args.replace_reviewed)
