import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("lua_stage", ROOT / "scripts/stage-hyprland-lua.py")
lua_stage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lua_stage)


class LuaStageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir="/tmp/opencode", prefix="solace-lua-stage-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.entry = self.home / ".config/hypr/hyprland.conf"
        self.entry.parent.mkdir(parents=True)
        self.output = self.home / "stage"

    def stage(self):
        result = lua_stage.Stage(self.home, self.output)
        result.visit(self.entry)
        return result

    def test_preview_graph_is_read_only_and_preserves_module_order(self):
        child = self.entry.with_name("personal.conf")
        child.write_text("# personal settings\n")
        self.entry.write_text("source = personal.conf\n# after personal settings\n")
        stage = self.stage()
        stage.check_variables()
        source, injections = stage.reviewed(self.entry)
        self.assertEqual(len(stage.sources), 2)
        self.assertIn(str(stage.module_path(child)), next(iter(injections.values())))
        self.assertIn("# after personal settings", source)
        self.assertFalse(self.output.exists())

    def test_cycles_missing_and_outside_home_sources_fail_closed(self):
        for source in ("source = hyprland.conf\n", "source = missing.conf\n", "source = /etc/passwd\n", "source = $UNKNOWN/settings.conf\n"):
            self.entry.write_text(source)
            with self.subTest(source=source), self.assertRaises(ValueError):
                self.stage()
        self.assertFalse(self.output.exists())

    def test_cross_module_variables_require_review(self):
        child = self.entry.with_name("child.conf")
        child.write_text("$shared = abc\n")
        self.entry.write_text("source = child.conf\n$other = $shared\n")
        with self.assertRaisesRegex(ValueError, "Cross-module"):
            self.stage().check_variables()

    def test_lua_paths_preserve_utf8_and_reject_control_characters(self):
        self.assertEqual(lua_stage.lua_quote("配置/entrée.lua"), '"配置/entrée.lua"')
        with self.assertRaises(ValueError):
            lua_stage.lua_quote("path\nwith-control")

    def test_native_palette_and_toggle_state_stay_dynamic(self):
        theme = self.home / ".config/solace/current/theme"
        theme.mkdir(parents=True)
        (theme / "hyprland.lua").write_text("-- existing native palette\n")
        flags = self.home / ".local/share/solace/default/hypr/toggles"
        flags.mkdir(parents=True)
        (flags / "window-no-gaps.conf").write_text("# toggle preset\n")
        self.entry.write_text("source = ~/.config/solace/current/theme/hyprland.conf\nsource = ~/.local/state/solace/toggles/hypr/*.conf\n")
        stage = self.stage()
        _, injections = stage.reviewed(self.entry)
        code = "\n".join(injections.values())
        self.assertIn(str(theme / "hyprland.lua"), code)
        self.assertIn("io.open", code)
        self.assertIn("window-no-gaps.conf", code)
        self.assertNotIn("io.popen", code)

    def test_reviewed_unbind_and_boolean_special_cases(self):
        self.entry.write_text("unbind = SUPER SHIFT, SPACE\n  enabled = yes, please :)\nlayerrule = no_anim on, match:namespace walker\n")
        stage = self.stage()
        source, injections = stage.reviewed(self.entry)
        self.assertIn('hl.unbind("SUPER + SHIFT + SPACE")', injections.values())
        self.assertIn("enabled = true", source)
        self.assertIn("no_anim = true", source)

    def test_checksum_failure_does_not_execute_or_create_stage(self):
        self.entry.write_text("# root\n")
        converter = self.home / "converter"
        converter.write_bytes(b"not executed")
        with patch.object(lua_stage.subprocess, "run") as run, self.assertRaisesRegex(ValueError, "checksum"):
            self.stage().write(self.entry, converter, "0" * 64)
        run.assert_not_called()
        self.assertFalse(self.output.exists())

    def test_staging_preserves_originals_and_verifies_in_isolated_runtime(self):
        self.entry.write_text("# root\n")
        original = self.entry.read_bytes()
        converter = self.home / "converter"
        converter.write_bytes(b"reviewed fixture")
        digest = hashlib.sha256(converter.read_bytes()).hexdigest()
        def fake_run(args, **kwargs):
            if args[0] == str(converter):
                return subprocess.CompletedProcess(args, 0, kwargs["input"].replace("# ", "-- "), "fixture converter report")
            self.assertEqual(args[:2], ["Hyprland", "--verify-config"])
            self.assertNotIn("HYPRLAND_INSTANCE_SIGNATURE", kwargs["env"])
            self.assertEqual(kwargs["env"]["XDG_RUNTIME_DIR"], str(self.output / "verify-runtime"))
            return subprocess.CompletedProcess(args, 0, "verified", "")
        with patch.object(lua_stage.subprocess, "run", side_effect=fake_run):
            top = self.stage().write(self.entry, converter, digest)
        self.assertTrue(top.is_file())
        self.assertEqual(self.entry.read_bytes(), original)
        manifest = json.loads((self.output / "manifest.json").read_text())
        self.assertTrue(manifest["verified"])
        self.assertFalse(manifest["activated"])
        with self.assertRaisesRegex(ValueError, "Existing stage"):
            self.stage().write(self.entry, converter, digest)


if __name__ == "__main__":
    unittest.main()
