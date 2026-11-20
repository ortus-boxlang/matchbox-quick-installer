#!/usr/bin/env python3
"""Offline install checks: MATCHBOX_BIN=/path/to/matchbox python3 tests/integration/test_release_install.py."""
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile
import threading
import unittest

ROOT = Path(__file__).resolve().parents[2]


class ReleaseInstallTest(unittest.TestCase):
    def test_metadata_refresh_and_verified_replacement(self):
        sibling = ROOT.parent / "matchbox/target/release/matchbox"
        compiler = os.environ.get("MATCHBOX_BIN") or (str(sibling) if sibling.is_file() else shutil.which("matchbox"))
        self.assertTrue(compiler, "Set MATCHBOX_BIN to a MatchBox executable")
        system = {"Linux": "linux", "Darwin": "macos", "Windows": "windows"}[platform.system()]
        arch = {"x86_64": "x64", "AMD64": "x64", "aarch64": "arm64", "arm64": "arm64",
                "i386": "x86", "i686": "x86", "armv7l": "armv7"}[platform.machine()]
        binary_name = "matchbox.exe" if system == "windows" else "matchbox"
        asset = f"matchbox-{system}-{arch}" + (".exe" if system == "windows" else "")
        state = {"build": "101", "revision": "a" * 40, "binary": b"first build\x00\xff",
                 "downloads": 0, "corrupt": False, "tag": "snapshot", "omit_checksum": False}

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                version = "0.12.0-snapshot" if state["tag"] == "snapshot" else "0.11.0"
                info = {"version": version, "build_version": version + "+" + state["build"],
                        "build_id": state["build"], "revision": state["revision"], "tag": state["tag"],
                        "artifacts": [] if state["omit_checksum"] else [
                            {"file": asset, "sha256": hashlib.sha256(state["binary"]).hexdigest()}]}
                origin = f"http://127.0.0.1:{self.server.server_port}"
                release = {"tag_name": state["tag"], "prerelease": state["tag"] == "snapshot",
                           "assets": [{"name": asset, "browser_download_url": origin + "/binary"},
                                      {"name": "version.json", "browser_download_url": origin + "/version.json"}]}
                if self.path == "/binary":
                    state["downloads"] += 1
                    data = b"tampered" if state["corrupt"] else state["binary"]
                elif self.path == "/version.json":
                    data = json.dumps(info).encode()
                elif self.path.startswith("/releases?"):
                    data = json.dumps([release]).encode()
                else:
                    data = json.dumps(release).encode()
                self.send_response(200)
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)

            def log_message(self, *args):
                pass

        with tempfile.TemporaryDirectory(prefix="mvm's release ") as temporary:
            home = Path(temporary)
            server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            self.addCleanup(server.server_close)
            self.addCleanup(server.shutdown)
            script = home / "mvm.bxs"
            script.write_text((ROOT / "src/mvm.bxs").read_text().replace(
                'MATCHBOX_GITHUB_API = "https://api.github.com/repos/ortus-boxlang/matchbox";',
                f'MATCHBOX_GITHUB_API = "http://127.0.0.1:{server.server_port}";'))

            executable = home / ("mvm.exe" if system == "windows" else "mvm")
            build = subprocess.run([compiler, "--target", "native", "--output", str(executable), str(script)],
                                   capture_output=True, text=True, timeout=180)
            self.assertEqual(build.returncode, 0, build.stdout + build.stderr)

            def run(*args, success=True):
                result = subprocess.run([str(executable), *args], capture_output=True, text=True,
                                        timeout=30, env={**os.environ, "MVM_HOME": str(home / "home")})
                self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
                return result.stdout + result.stderr

            slot = home / "home/versions/snapshot"
            run("install", "snapshot")
            self.assertEqual((slot / "bin" / binary_name).read_bytes(), state["binary"])
            self.assertEqual(json.loads((slot / "version.json").read_text())["revision"], "a" * 40)
            self.assertIn("0.12.0-snapshot+101", run("list-remote"))
            self.assertIn("0.12.0-snapshot+101", run("list"))
            run("use", "snapshot")
            self.assertIn("0.12.0-snapshot+101", run("current"))
            self.assertIn("already installed", run("install", "snapshot"))
            self.assertEqual(state["downloads"], 1)

            # Either build ID or revision changing must trigger a refresh.
            state["build"] = "102"
            state["binary"] = b"second build\x00\xfe"
            run("install", "snapshot")
            self.assertEqual(state["downloads"], 2)
            state["revision"] = "b" * 40
            run("install", "snapshot")
            self.assertEqual(state["downloads"], 3)
            before_binary = (slot / "bin" / binary_name).read_bytes()
            before_metadata = (slot / "version.json").read_bytes()

            state["build"] = "103"
            state["corrupt"] = True
            self.assertIn("checksum mismatch", run("install", "snapshot", success=False))
            self.assertEqual((slot / "bin" / binary_name).read_bytes(), before_binary)
            self.assertEqual((slot / "version.json").read_bytes(), before_metadata)
            self.assertEqual((home / "home/current").read_text().strip(), "snapshot")
            self.assertEqual(list((home / "home/cache").iterdir()), [])
            state["omit_checksum"] = True
            self.assertIn("checksum", run("install", "snapshot", success=False))
            self.assertEqual(state["downloads"], 4)

            state.update(corrupt=False, omit_checksum=False, tag="v0.11.0")
            run("install", "latest")
            self.assertIn("already installed", run("install", "0.11.0"))
            self.assertEqual(state["downloads"], 5)
            run("install", "0.11.0", "--force")
            self.assertEqual(state["downloads"], 6)


if __name__ == "__main__":
    unittest.main()
