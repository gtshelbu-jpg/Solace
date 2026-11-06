"""Local integration checks. No sudo, packages, services, or desktop changes."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Thinkpad/local/share/solace"


class InstallerTests(unittest.TestCase):
    def setUp(self):
        Path("/tmp/opencode").mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="solace-test-", dir="/tmp/opencode")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "another user"
        self.home.mkdir()
        self.bin = Path(self.temp.name) / "stubs"
        self.bin.mkdir()
        self.log = Path(self.temp.name) / "commands.log"
        self.env = os.environ.copy()
        self.env.update(
            HOME=str(self.home),
            XDG_CONFIG_HOME=str(self.home / ".config"),
            XDG_DATA_HOME=str(self.home / ".local/share"),
            XDG_STATE_HOME=str(self.home / ".local/state"),
            XDG_CACHE_HOME=str(self.home / ".cache"),
            PATH=str(self.bin) + ":" + os.environ["PATH"],
            SOLACE_PATH=str(self.home / ".local/share/solace"),
            SOLACE_PACKAGE_GROUPS="",
            SOLACE_REPLACE_CONFIGS="0",
            SOLACE_LID_POLICY="keep",
            SOLACE_BOOT_VISUALS="0",
            SOLACE_INSTALL_TABLET_SUPPORT="0",
            TEST_COMMAND_LOG=str(self.log),
        )
        for command in ("sudo", "systemctl", "fc-cache"):
            self.stub(command, 'printf "%s\\n" "' + command + ' $*" >> "$TEST_COMMAND_LOG"\n')

    def stub(self, name, body):
        target = self.bin / name
        target.write_text("#!/bin/bash\nset -e\n" + body)
        target.chmod(0o755)

    def run_script(self, name, *args, success=True):
        result = subprocess.run(
            ["bash", str(ROOT / name), *args],
            cwd=ROOT,
            env=self.env,
            capture_output=True,
            text=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout + result.stderr

    def test_strict_local_package_policy_stops_before_transactions(self):
        self.stub("pacman-conf", 'echo "PackageRequired PackageTrustedOnly"\n')
        output = self.run_script("install/10-packages.sh", success=False)
        self.assertIn("AUR builds require", output)
        self.assertIn("No signature policy was changed", output)
        self.assertFalse(self.log.exists())

    def test_optional_local_package_policy_reaches_package_stage(self):
        self.stub("pacman-conf", 'echo "PackageOptional PackageTrustedOnly"\n')
        self.stub("sudo", 'echo "package-stage-reached"; exit 91\n')
        output = self.run_script("install/10-packages.sh", success=False)
        self.assertIn("package-stage-reached", output)
        self.assertNotIn("AUR builds require", output)

    def test_fresh_config_then_preserving_rerun(self):
        self.run_script("install/20-configs.sh")
        config = self.home / ".config"
        current = config / "solace/current"
        self.assertEqual((current / "theme.name").read_text(), "solace\n")
        self.assertEqual(
            (current / "theme/colors.toml").read_bytes(),
            (ASSETS / "themes/solace/colors.toml").read_bytes(),
        )
        self.assertFalse((current / "theme").is_symlink())
        self.assertEqual((current / "background").resolve().name, "wallhaven-nmmvvk.jpg")
        self.assertFalse(os.readlink(current / "background").startswith("/"))
        for name in ("gum.env.conf", "gtk.css", "hyprlock.conf", "neovim.lua"):
            self.assertTrue((current / "theme" / name).is_file(), name)
        self.assertNotIn("{{ ", (current / "theme/gtk.css").read_text())
        for blueprint in (config / "aether/blueprints").glob("*.json"):
            data = blueprint.read_text()
            self.assertNotIn("@HOME@", data)
            self.assertNotIn("/home/givan1435", data)
            json.loads(data)
        self.assertFalse((config / "aether/wallhaven.json").exists())
        self.assertFalse((config / "dconf/user").exists())
        self.assertFalse((self.home / ".local/share/keyrings").exists())
        self.assertNotIn("hypridle\n", (self.home / ".local/share/solace/default/hypr/autostart.conf").read_text())
        self.assertNotIn("eDP-1", (config / "hypr/hyprland.conf").read_text())
        self.run_script("install/40-postinstall.sh")

        # Reruns preserve real preferences, credentials, wallpaper and shell startup.
        preferences = config / "hypr/input.conf"
        preferences.write_text("# a user's custom input settings\n")
        bashrc = self.home / ".bashrc"
        bashrc.write_text("# custom shell\n")
        profile = self.home / ".bash_profile"
        profile.write_text("# custom login\n")
        keyring = self.home / ".local/share/keyrings/private.keyring"
        keyring.parent.mkdir(parents=True)
        keyring.write_text("test credential marker\n")
        wallpaper = os.readlink(current / "background")
        self.run_script("install/20-configs.sh")
        self.assertEqual(preferences.read_text(), "# a user's custom input settings\n")
        self.assertEqual(bashrc.read_text(), "# custom shell\n")
        self.assertEqual(profile.read_text(), "# custom login\n")
        self.assertEqual(keyring.read_text(), "test credential marker\n")
        self.assertEqual(os.readlink(current / "background"), wallpaper)
        self.assertEqual((current / "theme.name").read_text(), "solace\n")
        self.assertNotIn("sudo ", self.log.read_text())

        # Explicit replacement backs up preferences but still never copies credentials.
        self.env["SOLACE_REPLACE_CONFIGS"] = "1"
        self.run_script("install/20-configs.sh")
        self.assertIn("sensitivity = 0", preferences.read_text())
        backups = list((self.home / ".config-backups").glob("*/.config/hypr/input.conf"))
        self.assertTrue(any(p.read_text() == "# a user's custom input settings\n" for p in backups))
        self.assertEqual(keyring.read_text(), "test credential marker\n")

    def test_default_dry_run_and_optional_groups(self):
        output = self.run_script("install.sh", "--dry-run", "--no-tablet")
        self.assertIn("Skipping boot changes", output)
        self.assertIn("Leaving the existing network stack", output)
        self.assertIn("Skipping optional DisplayLink", output)
        self.assertNotIn("AUR install spotify", output)
        self.assertNotIn("AUR install displaylink", output)
        self.assertFalse(any(self.home.iterdir()))
        output = self.run_script(
            "install.sh", "--dry-run", "--with", "displaylink", "--with", "apps",
            "--lid-policy", "awake", "--no-tablet",
        )
        self.assertIn("AUR install displaylink", output)
        self.assertIn("AUR install spotify", output)
        self.assertIn("would install lid policy 'awake'", output)
        self.assertFalse(any(self.home.iterdir()))

    def test_invalid_options_fail_before_commands(self):
        for args in (("--with", "unknown"), ("--lid-policy", "bad"), ("--only", "bad")):
            self.run_script("install.sh", "--dry-run", *args, success=False)
        self.assertFalse(self.log.exists())

    def test_services_do_not_change_networking(self):
        self.env["SOLACE_LID_POLICY"] = "awake"
        self.run_script("install/30-services.sh")
        commands = self.log.read_text()
        for forbidden in ("NetworkManager", "networkd", "resolved", "iwd", "ufw", "sshd", "restart systemd-logind"):
            self.assertNotIn(forbidden, commands)
        self.assertIn("lid-awake.conf", commands)
        self.assertIn("hypridle.service", commands)

    def test_lid_helper_only_targets_internal_panels(self):
        self.stub(
            "hyprctl",
            'if [[ $1 == monitors ]]; then\n'
            '  printf \'[ {"name":"eDP-2"}, {"name":"DVI-I-1"}, {"name":"DP-1"} ]\\n\'\n'
            'else\n  printf "%s\\n" "$*" >> "$TEST_COMMAND_LOG"\nfi\n',
        )
        self.run_script("Thinkpad/local/share/solace/bin/solace-hyprland-lid-display", "off")
        self.assertEqual(self.log.read_text(), "dispatch dpms off eDP-2\n")
        self.run_script("Thinkpad/local/share/solace/bin/solace-hyprland-lid-display", "bad", success=False)

    def test_login_never_writes_keyrings_or_pam(self):
        output = self.run_script("install/35-login.sh", "--dry-run")
        self.assertIn("Preserving all keyrings", output)
        self.assertNotIn("passwordless", output)
        self.assertNotIn("pam_gnome_keyring", output)
        self.assertFalse(any(self.home.iterdir()))

    def test_boot_requires_explicit_opt_in(self):
        self.run_script("install/36-boot-visuals.sh", "--dry-run", success=False)
        self.assertFalse(self.log.exists())

    def test_tracked_editor_json_is_valid(self):
        for name in ("lazyvim.json", "lazy-lock.json"):
            json.loads((ROOT / "Thinkpad/config/nvim" / name).read_text())


if __name__ == "__main__":
    unittest.main()
