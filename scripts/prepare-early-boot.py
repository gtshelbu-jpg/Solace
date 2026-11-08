"""Prepare and inspect target early input BEFORE its first encrypted reboot.

Run from the live installer, not from the first-login desktop bootstrap. Does not
partition/unlock disks, install kernels, sign EFI files or enroll firmware keys.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


USB = ["xhci_pci", "xhci_hcd", "usbhid", "hid_generic"]
SAM = ["surface_aggregator", "surface_aggregator_registry", "surface_aggregator_hub", "surface_hid_core"]


def run(argv, **kwargs):
    return subprocess.check_output(argv, text=True, **kwargs).strip()


def module_name(filename):
    return re.sub(r"\.(?:zst|xz|gz|lz4)$", "", Path(filename).name)


def target_path(root, name):
    if not name.startswith(("/boot/", "/efi/")):
        raise ValueError("Boot output is not below /boot or /efi; review its mount layout")
    path = root / name.lstrip("/")
    if not path.resolve().is_relative_to(root):
        raise ValueError("Boot output escapes the target root")
    return path


def input_modules(surface, product, loaded):
    modules = []
    if surface:
        pinctrl = sorted(name for name in loaded if re.fullmatch(r"pinctrl_[a-z0-9_]+", name))
        if not pinctrl:
            raise ValueError("Surface pinctrl driver was not detected in the working live kernel; use an external keyboard and review hardware support before reboot")
        modules += pinctrl
        if "pinctrl_amd" not in pinctrl:
            modules += ["intel_lpss", "intel_lpss_pci"]
        modules += ["8250_dw", *SAM]
        modules += ["surface_kbd" if product in ("Surface Laptop", "Surface Laptop 2") else "surface_hid"]
    return list(dict.fromkeys([*modules, *USB]))


def ordered_hooks(hooks):
    hooks = list(hooks)
    if not {"encrypt", "sd-encrypt"}.intersection(hooks):
        return hooks
    if "encrypt" in hooks and "sd-encrypt" in hooks:
        raise ValueError("Mixed encrypt/sd-encrypt hooks require manual review")
    if "sd-encrypt" in hooks and "systemd" not in hooks:
        raise ValueError("sd-encrypt needs the systemd initramfs hook")
    if "encrypt" in hooks and "udev" not in hooks:
        raise ValueError("encrypt needs the udev initramfs hook")
    for required in ("keyboard", "block", "filesystems"):
        if required not in hooks:
            raise ValueError("Encrypted boot lacks required hook: " + required)
    hooks.remove("keyboard")
    boundary = min(hooks.index(name) for name in ("autodetect", "encrypt", "sd-encrypt") if name in hooks)
    hooks.insert(boundary, "keyboard")
    encryption = hooks.index("sd-encrypt" if "sd-encrypt" in hooks else "encrypt")
    if hooks.index("block") > encryption or hooks.index("filesystems") < encryption:
        raise ValueError("Block/encryption/filesystem hook order requires review")
    return hooks


def prepare(root, apply=False):
    root = root.resolve(strict=True)
    if root == Path("/") or os.geteuid() != 0:
        raise ValueError("Run as root from the live ISO against a mounted target, never /")
    if not os.path.ismount(root) or not (root / "etc/arch-release").exists():
        raise ValueError("Expected a mounted Arch target root")
    if not any(os.path.ismount(root / part) for part in ("boot", "efi")):
        raise ValueError("Mount the target ESP at target/boot or target/efi before preparing boot")
    state = root / "var/lib/solace"
    pending = state / "early-boot.pending"
    if apply:
        state.mkdir(parents=True, exist_ok=True)
        pending.write_text("Early-input verification is incomplete; do not reboot or enable Secure Boot.\n")
    vendor = Path("/sys/class/dmi/id/sys_vendor").read_text().strip()
    product = Path("/sys/class/dmi/id/product_name").read_text().strip()
    surface = vendor == "Microsoft Corporation" and product.startswith("Surface")
    # /sys/module includes unused builtin drivers. Only a driver actually bound
    # to a controller identifies the pinctrl path needed by this machine.
    bound = {p.resolve().name for bus in ("platform", "pci")
             for p in (Path("/sys/bus") / bus / "devices").glob("*/driver/module")}
    modules = input_modules(surface, product, bound)
    hooks = run(["arch-chroot", str(root), "bash", "-c",
                 'set -e; source /etc/mkinitcpio.conf; for f in /etc/mkinitcpio.conf.d/*.conf; do [[ ! -f $f ]] || source "$f"; done; printf "%s\\n" "${HOOKS[@]}"']).splitlines()
    new_hooks = ordered_hooks(hooks)
    if not all(re.fullmatch(r"[a-zA-Z0-9_-]+", hook) for hook in new_hooks):
        raise ValueError("Unexpected initramfs hook names")
    kernels = sorted(p.parent.name for p in (root / "usr/lib/modules").glob("*/pkgbase"))
    if not kernels:
        raise ValueError("Target has no installed kernel module trees")
    expected = {}
    for kernel in kernels:
        expected[kernel] = []
        for module in modules:
            filename = run(["arch-chroot", str(root), "modinfo", "-k", kernel, "-F", "filename", module])
            if not filename:
                raise ValueError(f"Missing target input driver {module} for {kernel}")
            if filename != "(builtin)":
                expected[kernel].append(Path(filename).name)
    content = ("# Solace: early input, prepared before first boot. Existing MODULES are retained.\n"
               + "MODULES+=(" + " ".join(modules) + ")\n"
               + "HOOKS=(" + " ".join(new_hooks) + ")\n")
    dropin = root / "etc/mkinitcpio.conf.d/zz-solace-early-input.conf"
    if dropin.is_symlink():
        raise ValueError("Existing early-input drop-in is a symlink; preserve for review")
    if dropin.exists() and not dropin.read_text().startswith("# Solace: early input,"):
        raise ValueError("Existing custom early-input drop-in is preserved")
    print(json.dumps({"surface": surface, "kernels": kernels, "modules": modules,
                      "hooks": new_hooks, "apply": apply}, indent=2))
    if not apply:
        return
    if dropin.exists() and dropin.read_text() != content:
        backup = dropin.with_suffix(".conf.before-solace")
        if backup.exists():
            raise ValueError("An earlier early-input backup exists; review before replacing")
        backup.write_bytes(dropin.read_bytes())
    dropin.parent.mkdir(parents=True, exist_ok=True)
    dropin.write_text(content)
    subprocess.run(["arch-chroot", str(root), "mkinitcpio", "-P"], check=True)
    # Query real presets, not guessed EFI filenames. Never execute target files
    # on the host; all shell evaluation is confined to the installed target.
    outputs = run(["arch-chroot", str(root), "bash", "-c", '''
for f in /etc/mkinitcpio.d/*.preset; do
  ( source "$f"
    for p in "${PRESETS[@]}"; do
      for suffix in uki image; do
        key="${p}_${suffix}"; [[ -z ${!key:-} ]] || printf '%s\\t%s\\n' "$suffix" "${!key}"
      done
    done )
done''']).splitlines()
    if not outputs:
        raise ValueError("No initramfs/UKI outputs declared by the installed presets")
    images = []
    with tempfile.TemporaryDirectory(prefix="solace-initramfs-check-") as temp:
        for index, output in enumerate(outputs):
            kind, name = output.split("\t", 1)
            path = target_path(root, name)
            if not path.is_file():
                raise ValueError("Missing generated boot image: " + name)
            archive = path
            if kind == "uki":
                archive = Path(temp) / f"{index}.initrd"
                subprocess.run(["objcopy", "--dump-section", f".initrd={archive}", str(path),
                                str(Path(temp) / f"{index}.efi")], check=True)
            listing = run(["lsinitcpio", "--nocolor", "-l", str(archive)])
            included = {module_name(line) for line in listing.splitlines() if ".ko" in line}
            # The kernel version is present in each modules path. Require every
            # applicable explicit driver, except ones modinfo identified builtin.
            versions = [version for version in kernels if version in listing]
            if len(versions) != 1:
                raise ValueError("Cannot identify exactly one kernel in boot image: " + name)
            for filename in expected[versions[0]]:
                if module_name(filename) not in included:
                    raise ValueError(f"Generated {name} lacks required early-input module {filename}")
            images.append({"path": name, "kernel": versions[0], "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    if set(kernels) != {image["kernel"] for image in images}:
        raise ValueError("Not every installed kernel has a verified boot image")
    state.mkdir(parents=True, exist_ok=True)
    (state / "early-boot.json").write_text(json.dumps({"modules": modules, "hooks": new_hooks, "images": images}, indent=2) + "\n")
    pending.unlink()
    print("Early-input images inspected. Secure Boot remains a separate sign/verify/enrollment step.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", type=Path, required=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    try:
        prepare(args.target, args.apply)
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        raise SystemExit(f"EARLY BOOT NOT READY: {error}. Do not reboot the encrypted target yet.")
