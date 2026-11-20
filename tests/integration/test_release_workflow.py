#!/usr/bin/env python3
"""Offline release CLI checks: MATCHBOX_BIN=/path/to/matchbox python3 tests/integration/test_release_workflow.py."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / ".github/scripts/release.bxs"


class ReleaseWorkflowTest(unittest.TestCase):
    def setUp(self):
        sibling = ROOT.parent / "matchbox/target/release/matchbox"
        self.matchbox = os.environ.get("MATCHBOX_BIN") or (str(sibling) if sibling.is_file() else shutil.which("matchbox"))
        self.assertTrue(self.matchbox, "Set MATCHBOX_BIN to a MatchBox executable")
        self.requests = []
        self.statuses = {"release": 404, "tag": 404, "create": 201}
        owner = self

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                owner.requests.append((self.path, None))
                key = "release" if "/releases/" in self.path else "tag"
                self.respond(owner.statuses[key])

            def do_POST(self):
                body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
                owner.requests.append((self.path, body))
                owner.assertEqual(self.headers["Authorization"], "Bearer test-token")
                self.respond(owner.statuses["create"])

            def respond(self, status):
                self.send_response(status)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b"{}")

            def log_message(self, *args):
                pass

        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        self.env = {**os.environ, "GITHUB_TOKEN": "test-token", "GITHUB_REPOSITORY": "owner/repo",
                    "GITHUB_SHA": "a" * 40, "GITHUB_API_URL": f"http://127.0.0.1:{server.server_port}"}

    def run_cli(self, *args, success=True):
        result = subprocess.run([self.matchbox, str(SCRIPT), *args], capture_output=True,
                                text=True, env=self.env, timeout=30)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result.stdout + result.stderr

    def test_reserves_new_stable_tag_at_build_commit(self):
        self.run_cli("reserve-stable", "2.0.2")
        self.assertEqual(self.requests, [
            ("/repos/owner/repo/releases/tags/v2.0.2", None),
            ("/repos/owner/repo/git/ref/tags/v2.0.2", None),
            ("/repos/owner/repo/git/refs", {"ref": "refs/tags/v2.0.2", "sha": "a" * 40}),
        ])

    def test_existing_versions_api_failures_and_reservation_races_are_rejected(self):
        for key, status in [("release", 200), ("tag", 200), ("release", 401),
                            ("tag", 500), ("create", 422)]:
            with self.subTest(key=key, status=status):
                self.requests.clear()
                self.statuses = {"release": 404, "tag": 404, "create": 201, key: status}
                self.run_cli("reserve-stable", "2.0.2", success=False)
                if key != "create":
                    self.assertTrue(all(body is None for _, body in self.requests))

    def test_development_advance_preserves_other_fields_and_already_advanced_versions(self):
        with tempfile.TemporaryDirectory(prefix="mvm release ") as directory:
            file = Path(directory) / "box.json"
            file.write_text('{\n    "version": "2.0.2-snapshot",\n    "description": "preserve me"\n}\n')
            self.run_cli("prepare-next", "2.0.2", str(file))
            self.assertEqual(json.loads(file.read_text()), {"version": "2.1.0-snapshot", "description": "preserve me"})
            prepared = file.read_bytes()
            self.run_cli("prepare-next", "2.0.2", str(file))
            self.assertEqual(file.read_bytes(), prepared)
            file.write_text('{"version":"3.0.0-snapshot"}\n')
            self.run_cli("prepare-next", "2.0.2", str(file))
            self.assertEqual(file.read_text(), '{"version":"3.0.0-snapshot"}\n')


if __name__ == "__main__":
    unittest.main()
