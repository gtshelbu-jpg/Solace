"""Power menu dependencies and profile parsing; no real power-policy changes."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Thinkpad/local/share/solace"


class PowerProfileTests(unittest.TestCase):
    def test_control_client_bindings_are_in_both_base_manifests(self):
        for path in (ROOT / "packages/pacman.txt", ASSETS / "install/solace-base.packages"):
            packages = {line.split("#", 1)[0].strip() for line in path.read_text().splitlines()}
            self.assertIn("power-profiles-daemon", packages)
            self.assertIn("python-gobject", packages)

    def test_menu_lists_profiles_without_driver_details(self):
        Path("/tmp/opencode").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir="/tmp/opencode", prefix="power-menu-") as temp:
            root = Path(temp)
            client = root / "powerprofilesctl"
            client.write_text("#!/bin/bash\n[[ $1 == list ]] || exit 1\ncat <<'EOF'\n"
                              "  performance:\n    CpuDriver: intel_pstate\n\n"
                              "* balanced:\n    PlatformDriver: platform_profile\n\n"
                              "  power-saver:\n    CpuDriver: intel_pstate\nEOF\n")
            client.chmod(0o755)
            result = subprocess.run(["bash", str(ASSETS / "bin/solace-powerprofiles-list")],
                                    env={**os.environ, "PATH": str(root) + ":" + os.environ["PATH"]},
                                    capture_output=True, text=True, check=True)
            self.assertEqual(result.stdout.splitlines(), ["power-saver", "balanced", "performance"])
