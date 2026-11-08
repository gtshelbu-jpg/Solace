"""Prepare target-owned Secure Boot signatures; NEVER enroll firmware keys.

Run inside the installed target (or arch-chroot), after early-input preparation.
The installation medium itself remains unsigned and needs Secure Boot disabled.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess


def digest(path):
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def files(root=Path("/")):
    if (root / "var/lib/solace/early-boot.pending").exists():
        raise ValueError("Early-input verification is incomplete; finish it before signing")
    state = json.loads((root / "var/lib/solace/early-boot.json").read_text())
    images = [row for row in state["images"] if row["path"].endswith(".efi")]
    if not images:
        raise ValueError("Verified unified kernel images are required for this Secure Boot path")
    for row in images:
        path = root / row["path"].lstrip("/")
        if digest(path) != row["sha256"]:
            raise ValueError("Boot image changed after early-input verification; rerun prepare-early-boot first")
    bootloaders = [root / "boot/EFI/systemd/systemd-bootx64.efi", root / "boot/EFI/BOOT/BOOTX64.EFI"]
    if not all(path.is_file() for path in bootloaders):
        raise ValueError("Expected systemd-boot and fallback loader on the mounted ESP")
    return state, [*bootloaders, *(root / row["path"].lstrip("/") for row in images)]


def prepare(apply=False):
    if os.geteuid() != 0 or not Path("/etc/arch-release").exists():
        raise ValueError("Run as root inside the installed Arch target, not on the build host")
    # arch-chroot bind-mounts /run from the live environment; /run/archiso
    # therefore remains visible INSIDE a legitimate installed target.
    if Path("/usr/lib/initcpio/hooks/archiso").exists():
        raise ValueError("Enter the installed target with arch-chroot; never generate keys on the live ISO")
    if not os.path.ismount("/boot"):
        raise ValueError("The target ESP must be mounted at /boot")
    state, paths = files()
    print("Sign and independently verify: " + ", ".join(str(path) for path in paths))
    print("No firmware key enrollment or Secure Boot switch is performed.")
    if not apply:
        return
    keydir = Path("/var/lib/sbctl/keys")
    cert = keydir / "db/db.pem"
    if not keydir.exists():
        subprocess.run(["sbctl", "create-keys"], check=True)
    if not cert.is_file():
        raise ValueError("Incomplete existing sbctl keys; preserve and repair them manually")
    for path in paths:
        subprocess.run(["sbctl", "sign", "--save", str(path)], check=True)
        subprocess.run(["sbverify", "--cert", str(cert), str(path)], check=True)
    # bootctl prefers the .signed source during future loader updates. Register
    # its input/output pair too, so the package hook can refresh that signed copy.
    loader_source = Path("/usr/lib/systemd/boot/efi/systemd-bootx64.efi")
    signed_source = loader_source.with_suffix(".efi.signed")
    if not loader_source.is_file():
        raise ValueError("Missing installed systemd-boot source; cannot prepare safe loader updates")
    subprocess.run(["sbctl", "sign", "--save", "--output", str(signed_source), str(loader_source)], check=True)
    subprocess.run(["sbverify", "--cert", str(cert), str(signed_source)], check=True)
    paths.append(signed_source)
    # Saved paths make sbctl's package hooks responsible for future re-signing.
    # This verifies real files instead of assuming sign-all's exit code proves it.
    for row in state["images"]:
        row["sha256"] = digest(Path(row["path"]))
    Path("/var/lib/solace/early-boot.json").write_text(json.dumps(state, indent=2) + "\n")
    Path("/var/lib/solace/secure-boot-prepared.json").write_text(json.dumps({
        "firmware_enrolled": False, "files": {str(path): digest(path) for path in paths}}, indent=2) + "\n")
    print("Target EFI signatures verified. Firmware enrollment is a separate manual step; keep recovery media and an external keyboard available.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    try:
        prepare(args.apply)
    except (ValueError, OSError, KeyError, subprocess.SubprocessError) as error:
        raise SystemExit(f"SECURE BOOT NOT READY: {error}. Do not enable Secure Boot yet.")
