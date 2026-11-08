import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "Thinkpad/local/share/solace/bin/solace-hyprland-workspace-layout-toggle"


class RuntimeHelperTests(unittest.TestCase):
    def test_native_scale_cycle_persists_only_generic_monitor_layout(self):
        import json
        Path("/tmp/opencode").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir="/tmp/opencode", prefix="native-scale-") as temp:
            home = Path(temp)
            config = home / ".config/hypr"
            config.mkdir(parents=True)
            (config / "hyprland.lua").write_text("-- native fixture\n")
            monitor = config / "monitors.lua"
            monitor.write_text((ROOT / "config/hypr-native/home/.config/hypr/monitors.lua").read_text())
            stubs = home / "bin"
            stubs.mkdir()
            data = json.dumps([{"focused": True, "name": "HEADLESS-1", "scale": 1,
                                "width": 1920, "height": 1080, "refreshRate": 60}])
            client = stubs / "hyprctl"
            client.write_text("#!/bin/bash\nif [[ $1 == monitors ]]; then printf '%s\\n' '" + data +
                              "'; else printf '%s\\n' \"$*\" >> \"$CALLS\"; fi\n")
            client.chmod(0o755)
            notify = stubs / "notify-send"
            notify.write_text("#!/bin/bash\nexit 0\n")
            notify.chmod(0o755)
            log = home / "calls"
            env = {**os.environ, "HOME": str(home), "PATH": str(stubs) + ":" + os.environ["PATH"], "CALLS": str(log)}
            helper = ROOT / "Thinkpad/local/share/solace/bin/solace-hyprland-monitor-scaling-cycle"
            subprocess.run(["bash", str(helper)], env=env, check=True)
            self.assertIn('scale = "1.25"', monitor.read_text())
            self.assertIn("eval hl.monitor", log.read_text())
            custom = monitor.read_text() + '\nhl.monitor({output = "DP-1", mode = "preferred", scale = "2"})\n'
            monitor.write_text(custom)
            subprocess.run(["bash", str(helper)], env=env, check=True)
            self.assertEqual(monitor.read_text(), custom)

    def test_native_and_legacy_layout_routes_and_dry_run(self):
        with tempfile.TemporaryDirectory(dir="/tmp/opencode", prefix="solace-runtime-") as temp:
            root = Path(temp)
            for name, body in {
                "hyprctl": '''if [[ $1 == activeworkspace ]]; then echo '{"id": 3, "tiledLayout": "dwindle"}';
elif [[ $1 == repl && $2 == 'return type(hl.workspace_rule)' ]]; then echo "$NATIVE_PROBE";
else printf '%s\\n' "$*" >> "$CALLS"; fi''',
                "notify-send": 'echo notify >> "$CALLS"',
            }.items():
                path = root / name
                path.write_text("#!/bin/bash\n" + body + "\n")
                path.chmod(0o755)
            log = root / "calls"
            env = {**os.environ, "PATH": str(root) + ":" + os.environ["PATH"], "CALLS": str(log)}
            for native in ("function", "unknown request"):
                env["NATIVE_PROBE"] = native
                for dry in (True, False):
                    log.unlink(missing_ok=True)
                    result = subprocess.run(["bash", str(HELPER), *(["--dry-run"] if dry else [])], env=env, text=True, capture_output=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    if dry:
                        self.assertFalse(log.exists())
                        self.assertIn("scrolling", result.stdout)
                    else:
                        calls = log.read_text()
                        self.assertIn('eval hl.workspace_rule({workspace = "3", layout = "scrolling"})' if native == "function" else "keyword workspace 3, layout:scrolling", calls)
                        self.assertIn("notify", calls)


if __name__ == "__main__":
    unittest.main()
