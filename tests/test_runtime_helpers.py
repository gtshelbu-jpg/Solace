import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "Thinkpad/local/share/solace/bin/solace-hyprland-workspace-layout-toggle"


class RuntimeHelperTests(unittest.TestCase):
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
