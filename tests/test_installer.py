"""Local integration checks. No sudo, packages, services, or desktop changes."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
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
        for name in ("gum.env.conf", "gum.env.lua", "hyprland.lua", "gtk.css", "hyprlock.conf", "neovim.lua"):
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

    def test_bash_prompt_opt_in_preserves_customizations_and_is_idempotent(self):
        rc = self.home / ".bashrc"
        original = "# Personal aliases\nalias ll='ls -l'\n"
        rc.write_text(original)
        self.stub("starship", "exit 0\n")
        self.run_script("config/scripts/solace-setup-bash-prompt")
        content = rc.read_text()
        self.assertTrue(content.startswith(original))
        self.assertIn('eval "$(starship init bash)"', content)
        self.assertTrue(any(p.read_text() == original for p in (self.home / ".config-backups").glob("*/.bashrc")))
        self.run_script("config/scripts/solace-setup-bash-prompt")
        self.assertEqual(rc.read_text(), content)

    def test_bash_prompt_preserves_symlinked_startup(self):
        target = self.home / "my-bashrc"
        target.write_text("# Personal shell config\n")
        (self.home / ".bashrc").symlink_to(target)
        self.run_script("config/scripts/solace-setup-bash-prompt", success=False)
        self.assertEqual(target.read_text(), "# Personal shell config\n")

    def test_bash_prompt_installer_dry_run_is_write_free(self):
        output = self.run_script("install.sh", "--dry-run", "--only", "configs", "--bash-prompt")
        self.assertIn("would back up .bashrc and enable Starship", output)
        self.assertFalse(any(self.home.iterdir()))

    def test_theme_appearance_only_avoids_privileged_and_preference_integrations(self):
        share = self.home / ".local/share/solace"
        theme = share / "themes/demo"
        theme.mkdir(parents=True)
        (theme / "colors.toml").write_text('background = "#101017"\n')
        (self.home / ".config/solace/current").mkdir(parents=True)
        self.env["SOLACE_PATH"] = str(share)
        for name in ("solace-theme-set-templates", "solace-theme-bg-next", "solace-restart-swayosd",
                     "solace-restart-terminal", "solace-restart-hyprctl", "solace-restart-btop",
                     "solace-restart-opencode", "solace-restart-mako", "solace-restart-helix",
                     "solace-theme-set-foot", "solace-theme-set-gnome"):
            self.stub(name, 'echo "' + name + ' $*" >> "$TEST_COMMAND_LOG"\n')
        self.stub("pgrep", 'exit 1\n')
        self.run_script("Thinkpad/local/share/solace/bin/solace-theme-set", "--appearance-only", "demo")
        calls = self.log.read_text()
        self.assertIn("solace-theme-set-gnome --appearance-only", calls)
        self.assertNotIn("sudo", calls)
        self.assertEqual((self.home / ".config/solace/current/theme.name").read_text(), "demo\n")
        (theme / "appearance-only").write_text("Preserve application preferences\n")
        self.log.write_text("")
        self.run_script("Thinkpad/local/share/solace/bin/solace-theme-set", "demo")
        self.assertIn("solace-theme-set-gnome --appearance-only", self.log.read_text())

    def test_stock_bash_startup_gets_shared_defaults_without_duplicate_prompt(self):
        shared = self.home / ".local/share/solace/default/bash/rc"
        shared.parent.mkdir(parents=True)
        shared.write_text("# Shared shell settings\n")
        rc = self.home / ".bashrc"
        rc.write_text("# Arch stock startup\n[[ $- != *i* ]] && return\nalias ls='ls --color=auto'\nalias grep='grep --color=auto'\n" + r"PS1='[\u@\h \W]\$ '" + "\n")
        self.stub("starship", "exit 0\n")
        self.run_script("config/scripts/solace-setup-bash-prompt")
        self.run_script("config/scripts/solace-setup-bash-defaults", "--if-stock")
        result = rc.read_text()
        self.assertIn('source "$HOME/.local/share/solace/default/bash/rc"', result)
        self.assertNotIn("alias ls='ls --color=auto'", result)
        self.assertNotIn("starship init bash", result)
        self.run_script("config/scripts/solace-setup-bash-defaults", "--if-stock")
        self.assertEqual(rc.read_text(), result)

    def test_custom_bash_startup_requires_explicit_defaults_integration(self):
        shared = self.home / ".local/share/solace/default/bash/rc"
        shared.parent.mkdir(parents=True)
        shared.write_text("# Shared shell settings\n")
        rc = self.home / ".bashrc"
        rc.write_text("alias ls='my-personal-ls'\nexport MY_SETTING=kept\n")
        original = rc.read_text()
        self.run_script("config/scripts/solace-setup-bash-defaults", "--if-stock")
        self.assertEqual(rc.read_text(), original)
        self.run_script("config/scripts/solace-setup-bash-defaults")
        self.assertTrue(rc.read_text().endswith(original))

    def test_btop_stock_default_is_connected_but_custom_theme_is_preserved(self):
        conf = self.home / ".config/btop/btop.conf"
        conf.parent.mkdir(parents=True)
        conf.write_text('color_theme = "Default"\nupdate_ms = 1200\n')
        self.run_script("install/20-configs.sh")
        self.assertEqual(conf.read_text(), 'color_theme = "current"\nupdate_ms = 1200\n')
        conf.write_text('color_theme = "my-own-theme"\nupdate_ms = 1200\n')
        self.run_script("install/20-configs.sh")
        self.assertEqual(conf.read_text(), 'color_theme = "my-own-theme"\nupdate_ms = 1200\n')

    def test_impala_palette_overlay_preserves_config_and_cleans_up(self):
        theme = self.home / ".config/solace/current/theme"
        theme.mkdir(parents=True)
        (theme / "impala.toml").write_text('[theme]\nborder = "#b4a1e8"\nbackground = "#101017"\n')
        user = self.home / ".config/impala/config.toml"
        user.parent.mkdir(parents=True)
        original = 'switch = "m"\n[theme] # my prior colors\nborder = "red"\n[station.known_network]\nremove = "x"\n'
        user.write_text(original)
        runtime = self.home / "runtime"
        runtime.mkdir()
        self.env["XDG_RUNTIME_DIR"] = str(runtime)
        self.stub("impala", 'cat "$XDG_CONFIG_HOME/impala/config.toml"\n')
        output = self.run_script("Thinkpad/local/share/solace/bin/solace-tui-theme", "impala")
        actual = tomllib.loads(output)
        self.assertEqual(actual["theme"]["border"], "#b4a1e8")
        self.assertEqual(actual["switch"], "m")
        self.assertEqual(actual["station"]["known_network"]["remove"], "x")
        self.assertEqual(user.read_text(), original)
        self.assertFalse(list(runtime.glob("solace-impala.*")))

    def test_impala_selection_template_recomputes_cached_derived_color(self):
        folder = self.home / ".config/solace/current/next-theme"
        folder.mkdir(parents=True)
        (folder / "colors.toml").write_text('background = "#101017"\nforeground = "#dddde7"\naccent = "#b4a1e8"\nimpala_selection_background = "#101017"\n')
        self.env["SOLACE_PATH"] = str(ASSETS)
        self.run_script("Thinkpad/local/share/solace/bin/solace-theme-set-templates")
        result = tomllib.loads((folder / "impala.toml").read_text())
        self.assertNotEqual(result["theme"]["background"], "#101017")
        self.assertEqual(result["theme"]["text_color"], "#dddde7")

    def test_tui_adapter_passes_other_commands_without_invented_options(self):
        self.stub("btop", 'printf "%s\\n" "$*"\n')
        output = self.run_script("Thinkpad/local/share/solace/bin/solace-tui-theme", "btop", "--debug")
        self.assertEqual(output.strip(), "--debug")

    def test_bluetooth_adapter_non_tty_does_not_emit_escape_sequences(self):
        theme = self.home / ".config/solace/current/theme"
        theme.mkdir(parents=True)
        (theme / "colors.toml").write_text('accent = "#b4a1e8"\n')
        self.stub("bluetui", 'echo pass-through\n')
        output = self.run_script("Thinkpad/local/share/solace/bin/solace-tui-theme", "bluetui")
        self.assertEqual(output.strip(), "pass-through")

    def test_welcome_lists_derivative_learn_pages_without_executing_them(self):
        docs = self.home / "learn"
        docs.mkdir()
        (docs / "black.md").write_text('# Solace Black\n\nExample only: touch "$HOME/must-not-run"\n')
        self.env["SOLACE_LEARN_DIR"] = str(docs)
        result = subprocess.run(
            ["bash", str(ASSETS / "bin/solace-welcome"), "--plain", "--display", "--force"],
            env=self.env, input="\n", text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Additional topic: Solace Black", result.stdout)
        self.assertFalse((self.home / "must-not-run").exists())

    def test_tui_launch_keeps_app_identity_and_uses_palette_adapter(self):
        self.assertTrue(os.access(ASSETS / "bin/solace-tui-theme", os.X_OK))
        self.stub("setsid", 'exec "$@"\n')
        self.stub("uwsm-app", 'shift\nexec "$@"\n')
        self.stub("xdg-terminal-exec", 'printf "%s\\n" "$@" >> "$TEST_COMMAND_LOG"\n')
        self.run_script("Thinkpad/local/share/solace/bin/solace-launch-tui", "impala", "--ascii")
        args = self.log.read_text().splitlines()
        self.assertEqual(args, ["--app-id=org.solace.impala", "-e", "solace-tui-theme", "impala", "--ascii"])

    def test_displaylink_defers_start_if_running_kernel_has_no_built_module(self):
        self.env["SOLACE_PACKAGE_GROUPS"] = "displaylink"
        self.stub("systemctl", 'if [[ $1 == "list-unit-files" ]]; then echo "displaylink.service enabled"; fi\n')
        self.stub("modinfo", 'exit 1\n')
        output = self.run_script("install/31-displaylink.sh")
        self.assertIn("Reboot into the installed kernel", output)
        calls = self.log.read_text()
        self.assertIn("sudo systemctl enable displaylink.service", calls)
        self.assertNotIn("systemctl start", calls)
        self.assertNotIn("sudo modprobe", calls)

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
