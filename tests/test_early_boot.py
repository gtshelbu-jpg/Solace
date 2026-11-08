"""Pre-reboot policy fixtures. No disks, firmware variables or keys are changed."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), ROOT / "scripts" / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


early = load("prepare-early-boot")
secure = load("prepare-secure-boot")


class EarlyBootTests(unittest.TestCase):
    def test_module_validation_accepts_compressed_and_decompressed_files(self):
        for filename in ("surface_hid.ko", "surface_hid.ko.zst", "surface_hid.ko.xz"):
            self.assertEqual(early.module_name("kernel/drivers/" + filename), "surface_hid.ko")

    def test_usb_and_bound_surface_drivers_not_all_loaded_builtins(self):
        self.assertEqual(early.input_modules(False, "Other", set()), early.USB)
        modules = early.input_modules(True, "Surface Laptop 4", {"pinctrl_tigerlake", "intel_lpss_pci"})
        self.assertEqual(modules[0], "pinctrl_tigerlake")
        self.assertIn("surface_hid", modules)
        self.assertNotIn("surface_kbd", modules)
        self.assertIn("usbhid", modules)
        self.assertIn("surface_kbd", early.input_modules(True, "Surface Laptop 2", {"pinctrl_sunrisepoint"}))
        with self.assertRaises(ValueError):
            early.input_modules(True, "Surface Unknown", set())

    def test_encrypted_keyboard_hook_precedes_autodetect_and_unlock(self):
        for systemd in (True, False):
            hooks = ["base", "systemd" if systemd else "udev", "autodetect", "microcode", "modconf",
                     "keyboard", "sd-vconsole" if systemd else "keymap", "block",
                     "sd-encrypt" if systemd else "encrypt", "filesystems", "fsck"]
            result = early.ordered_hooks(hooks)
            self.assertEqual(set(result), set(hooks))
            self.assertLess(result.index("keyboard"), result.index("autodetect"))
            self.assertEqual(early.ordered_hooks(result), result)
        with self.assertRaises(ValueError):
            early.ordered_hooks(["base", "systemd", "keyboard", "block", "filesystems", "sd-encrypt"])

    def test_signing_requires_unchanged_verified_ukis_and_both_bootloaders(self):
        Path("/tmp/opencode").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir="/tmp/opencode", prefix="early-boot-") as temp:
            root = Path(temp)
            state = root / "var/lib/solace/early-boot.json"
            state.parent.mkdir(parents=True)
            image = root / "boot/EFI/Linux/test.efi"
            image.parent.mkdir(parents=True)
            image.write_bytes(b"fixture, not an executable")
            state.write_text(json.dumps({"images": [{"path": "/boot/EFI/Linux/test.efi", "sha256": secure.digest(image)}]}))
            for name in ("systemd/systemd-bootx64.efi", "BOOT/BOOTX64.EFI"):
                path = root / "boot/EFI" / name
                path.parent.mkdir(parents=True)
                path.write_bytes(b"fixture")
            self.assertEqual(len(secure.files(root)[1]), 3)
            pending = state.with_name("early-boot.pending")
            pending.write_text("validation interrupted")
            with self.assertRaisesRegex(ValueError, "incomplete"):
                secure.files(root)
            pending.unlink()
            image.write_bytes(b"changed")
            with self.assertRaises(ValueError):
                secure.files(root)
            with self.assertRaises(ValueError):
                early.target_path(root, "/etc/passwd")

    def test_live_staging_prepares_input_before_prompt_or_reboot(self):
        text = (ROOT / "archiso/profile/airootfs/usr/local/bin/solace-install").read_text()
        stage = text.split("stage_solace_target() {", 1)[1].split("\n}", 1)[0]
        self.assertLess(stage.index("prepare-early-boot.py"), stage.index("install_first_login_prompt"))
        config = json.loads((ROOT / "archiso/profile/airootfs/usr/share/solace/archinstall/solace-user_configuration.json").read_text())
        self.assertEqual(config["bootloader_config"]["bootloader"], "Systemd-boot")
        self.assertTrue(config["bootloader_config"]["uki"])
        self.assertIn("sbctl", config["packages"])
        self.assertIn("sbsigntools", config["packages"])
