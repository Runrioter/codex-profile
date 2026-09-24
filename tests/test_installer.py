import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "bin" / "codex-profile"
ROOT = SCRIPT.parents[1]


class InstallerTest(unittest.TestCase):
    def run_installer(self, home, *arguments, codex_home=None):
        environment = {**os.environ, "HOME": str(home)}
        environment.pop("CODEX_HOME", None)
        if codex_home is not None:
            environment["CODEX_HOME"] = str(codex_home)
        return subprocess.run(
            ["python3", str(SCRIPT), *arguments],
            env=environment,
            capture_output=True,
            text=True,
        )

    def test_installs_using_current_home_and_is_idempotent(self):
        with tempfile.TemporaryDirectory(prefix="profile test ") as directory:
            home = Path(directory)
            first = self.run_installer(home, "install", "qwen38")
            self.assertEqual(first.returncode, 0, first.stderr)
            config = (home / ".codex" / "qwen38.config.toml").read_text()
            catalog = home / ".codex" / "qwen38-model-catalog.json"
            parsed = tomllib.loads(config)
            self.assertEqual(parsed["model_catalog_json"], str(catalog))
            self.assertEqual(parsed["model_provider"], "lmstudio")
            self.assertEqual(parsed["oss_provider"], "lmstudio")
            self.assertEqual(json.loads(catalog.read_text())["models"][0]["slug"], "qwen/qwen3.8-27b")
            second = self.run_installer(home, "install", "qwen38")
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertIn("Unchanged:", second.stdout)

    def test_conflicts_require_force_before_any_write(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            target = home / ".codex"
            target.mkdir()
            config = target / "qwen38.config.toml"
            config.write_text("custom config\n")
            blocked = self.run_installer(home, "install", "qwen38")
            self.assertEqual(blocked.returncode, 1)
            self.assertEqual(config.read_text(), "custom config\n")
            self.assertFalse((target / "qwen38-model-catalog.json").exists())
            forced = self.run_installer(home, "install", "qwen38", "--force")
            self.assertEqual(forced.returncode, 0, forced.stderr)
            self.assertIn("model_catalog_json", config.read_text())

    def test_list(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_installer(Path(directory), "list")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), "lmstudio")

    def test_custom_profile_name_uses_lmstudio_template(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            result = self.run_installer(home, "install", "local-qwen")
            self.assertEqual(result.returncode, 0, result.stderr)
            config = tomllib.loads((home / ".codex" / "local-qwen.config.toml").read_text())
            self.assertEqual(config["model"], "qwen/qwen3.8-27b")
            self.assertEqual(config["model_provider"], "lmstudio")
            self.assertEqual(config["model_catalog_json"], str(home / ".codex" / "local-qwen-model-catalog.json"))
            self.assertFalse((home / ".codex" / "qwen38.config.toml").exists())

    def test_rejects_invalid_profile_and_unknown_provider(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            invalid = self.run_installer(home, "install", "../other")
            self.assertEqual(invalid.returncode, 1)
            missing = self.run_installer(home, "install", "newprofile", "--provider", "missing")
            self.assertEqual(missing.returncode, 1)
            self.assertFalse((home / ".codex").exists())

    def test_make_install_accepts_a_different_profile_name(self):
        with tempfile.TemporaryDirectory() as directory:
            environment = {**os.environ, "CODEX_HOME": str(Path(directory) / "codex")}
            result = subprocess.run(
                ["make", "install", "PROFILE=my-qwen"],
                cwd=ROOT,
                env=environment,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((Path(directory) / "codex" / "my-qwen.config.toml").is_file())

    def test_codex_home_override(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory) / "home"
            custom = Path(directory) / "custom codex"
            result = self.run_installer(home, "install", "qwen38", codex_home=custom)
            self.assertEqual(result.returncode, 0, result.stderr)
            config = tomllib.loads((custom / "qwen38.config.toml").read_text())
            self.assertEqual(config["model_catalog_json"], str(custom.resolve() / "qwen38-model-catalog.json"))
            self.assertFalse((home / ".codex").exists())

if __name__ == "__main__":
    unittest.main()
