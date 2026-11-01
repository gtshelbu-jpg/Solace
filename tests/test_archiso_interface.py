import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class ArchisoInterfaceTests(unittest.TestCase):
    def setUp(self):
        Path("/tmp/opencode").mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="solace-build-test-", dir="/tmp/opencode")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.capture = self.root / "captured-pacman.conf"
        for name, body in {
            "sudo": 'exec "$@"\n',
            "rsync": 'exit 0\n',
            "mkarchiso": 'for profile; do :; done\ncp "$profile/pacman.conf" "$TEST_CAPTURE"\n',
        }.items():
            p = self.bin / name; p.write_text("#!/bin/bash\nset -e\n" + body); p.chmod(0o755)
        self.source = self.root / "source"
        self.profile = self.root / "profile"
        self.source.mkdir(); self.profile.mkdir()
        (self.source / "install.sh").write_text("#!/bin/bash\n")
        (self.profile / "profiledef.sh").write_text('iso_name="test"\n')
        (self.profile / "pacman.conf").write_text("[options]\nSigLevel = Required DatabaseOptional\n")
        self.env = {**os.environ, "PATH": str(self.bin) + ":" + os.environ["PATH"], "TEST_CAPTURE": str(self.capture)}

    def build(self, *args):
        return subprocess.run([
            "bash", str(ROOT / "archiso/build.sh"), "--profile", str(self.profile),
            "--embed-source", str(self.source), "--work", str(self.root / "work"),
            "--out", str(self.root / "out"), "--allow-dirty-sources", *args,
        ], env=self.env, capture_output=True, text=True)

    def test_base_interface_and_mock_build(self):
        self.assertEqual(json.loads((ROOT / "archiso/interface.json").read_text())["version"], 1)
        p = self.build()
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertTrue(self.capture.is_file())
        self.assertTrue((self.root / "work/.solace-build-work").is_file())

    def test_dangerous_clean_path_is_rejected_before_sudo(self):
        p = self.build("--work", "/", "--clean")
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("Unsafe work directory", p.stderr)
        self.assertFalse(self.capture.exists())

    def test_unsigned_local_packages_fail_closed(self):
        repo = self.root / "repo"; repo.mkdir()
        (repo / "test.pkg.tar.zst").write_text("test")
        (repo / "solace-local.db.tar.gz").write_text("test")
        keyring = self.root / "keyring"; keyring.mkdir()
        (keyring / "pubring.gpg").write_text("test-only fixture, not a trusted key")
        p = self.build("--local-repo", str(repo), "--gpg-dir", str(keyring))
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("Unsigned local package", p.stderr)
        self.assertFalse(self.capture.exists())

    def test_signed_repo_configuration_requires_trust(self):
        repo = self.root / "repo"; repo.mkdir()
        (repo / "test.pkg.tar.zst").write_text("test")
        (repo / "test.pkg.tar.zst.sig").write_text("test-only signature fixture")
        (repo / "solace-local.db.tar.gz").write_text("test")
        keyring = self.root / "keyring"; keyring.mkdir()
        (keyring / "pubring.gpg").write_text("test-only keyring fixture")
        p = self.build("--local-repo", str(repo), "--gpg-dir", str(keyring))
        self.assertEqual(p.returncode, 0, p.stderr)
        config = self.capture.read_text()
        self.assertIn("Required TrustedOnly", config)
        self.assertNotIn("TrustAll", config)
        # Real cryptographic verification belongs to Pacman; mkarchiso is mocked.

    def test_unmarked_nonempty_work_directory_is_preserved(self):
        work = self.root / "work"; work.mkdir(); (work / "mine").write_text("data")
        p = self.build("--clean")
        self.assertNotEqual(p.returncode, 0)
        self.assertEqual((work / "mine").read_text(), "data")


if __name__ == "__main__": unittest.main()
