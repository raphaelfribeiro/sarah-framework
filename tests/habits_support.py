"""Shared helpers for the habits installer tests.

The engine is loaded from scripts/ by path (scripts/ is not a package), and
every test builds its own throwaway plugin root and project under a temp
directory, so nothing here touches the real repository tree.
"""

import contextlib
import importlib.util
import io
import json
import os
import socket
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "habits.py"


def load_engine():
    spec = importlib.util.spec_from_file_location("habits_under_test", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


HOOK = "#!/bin/sh\n# payload body\nexit 0\n"


def make_plugin(base, habits=None, version="0.2.0"):
    """Build a plugin root holding the given habits.

    habits maps a name to {"files": {rel: text}, "settings": [...], "requires": [...], "ask": [...]}.
    """
    plugin = Path(base) / "plugin"
    (plugin / ".claude-plugin").mkdir(parents=True)
    (plugin / ".claude-plugin" / "plugin.json").write_text(json.dumps({"name": "sarah", "version": version}))
    for name, spec in (habits or {}).items():
        payload = plugin / "skills" / "sarah-init" / "habits" / name
        payload.mkdir(parents=True, exist_ok=True)
        for rel, text in spec.get("files", {}).items():
            target = payload / "files" / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text)
            if rel.endswith(".sh"):
                target.chmod(0o755)
        meta = {"description": "test habit", "requires": spec.get("requires", []), "settings": spec.get("settings", [])}
        for extra in ("ask", "keys", "include"):
            if extra in spec:
                meta[extra] = spec[extra]
        (payload / "habit.json").write_text(json.dumps(meta))
    return plugin


def alpha(extra_files=None):
    """A habit with one hook script registered on PreToolUse Bash."""
    files = {"sarah/hooks/alpha/guard.sh": HOOK}
    files.update(extra_files or {})
    return {
        "files": files,
        "settings": [{"event": "PreToolUse", "matcher": "Bash", "file": "sarah/hooks/alpha/guard.sh"}],
    }


def tree(root):
    """Map every path under root (except .git) to its bytes, or None for a directory."""
    out = {}
    root = Path(root)
    for p in sorted(root.rglob("*")):
        rel = p.relative_to(root).as_posix()
        if rel == ".git" or rel.startswith(".git/"):
            continue
        out[rel] = None if p.is_dir() and not p.is_symlink() else (os.readlink(p) if p.is_symlink() else p.read_bytes())
    return out


def mtimes(root):
    root = Path(root)
    return {
        p.relative_to(root).as_posix(): p.lstat().st_mtime_ns
        for p in sorted(root.rglob("*"))
        if ".git" not in p.relative_to(root).parts
    }


class HabitsCase(unittest.TestCase):
    """A temp project, a temp plugin root, the engine, and no network."""

    def setUp(self):
        self.engine = load_engine()
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.base = Path(tmp.name).resolve()
        self.project = self.base / "project"
        self.project.mkdir()
        self.plugin = make_plugin(self.base, {"alpha": alpha(), "beta": {"files": {"sarah/hooks/beta/b.sh": HOOK}}})
        guard = mock.patch.object(socket.socket, "connect", side_effect=AssertionError("network used"))
        guard.start()
        self.addCleanup(guard.stop)

    def git_init(self):
        subprocess.run(["git", "init", "-q", str(self.project)], check=True)

    def run_cli(self, *argv, plugin=None):
        out, err = io.StringIO(), io.StringIO()
        full = ["--project", str(self.project), "--plugin-root", str(plugin or self.plugin), *argv]
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = self.engine.main(full)
        return code, out.getvalue() + err.getvalue()

    def write(self, rel, text):
        p = self.project / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)
        return p

    def settings(self):
        return json.loads((self.project / ".claude" / "settings.json").read_text())

    def settings_text(self):
        """The settings file as text, or "" when removal deleted the emptied file."""
        p = self.project / ".claude" / "settings.json"
        return p.read_text() if p.exists() else ""
