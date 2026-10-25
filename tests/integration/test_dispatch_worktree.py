"""IN14 (R17): a worktree born from an installed project has what it needs.

Uses the shipped dispatch-guard payload. `git worktree add` is the platform's own
mechanism for a subagent copy; the hooks, the habits record and the settings are
tracked files, so they must arrive with it, and a recorded setup or check
command must run there.
"""

import json
import shutil
import subprocess
import unittest

from tests.habits_support import ROOT, HabitsCase


@unittest.skipUnless(shutil.which("git"), "git is required")
class WorktreeBornReady(HabitsCase):
    def git(self, *args, cwd=None):
        return subprocess.run(["git", "-C", str(cwd or self.project), "-c", "user.email=dev@example.invalid",
                               "-c", "user.name=Dev Example", "-c", "commit.gpgsign=false", *args],
                              capture_output=True, text=True, check=True)

    def setUp(self):
        super().setUp()
        subprocess.run(["git", "init", "-q", "-b", "develop", str(self.project)], check=True)
        self.write("README.md", "seed\n")

    def install_and_commit(self):
        code, out = self.run_cli("apply", "_lib", "dispatch-guard", plugin=ROOT)
        self.assertEqual(code, 0, out)
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "install habits")

    def test_in14_the_copy_has_the_hooks_the_record_and_the_settings(self):
        self.install_and_commit()
        copy = self.base / "copy"
        self.git("worktree", "add", "-q", "-b", "feature/x", str(copy))
        for rel in ("sarah/hooks/dispatch-guard/guard.sh", "sarah/hooks/_lib/exceptions.sh", "sarah/habits.md", ".claude/settings.json"):
            self.assertTrue((copy / rel).is_file(), rel)
        settings = json.loads((copy / ".claude" / "settings.json").read_text())
        self.assertEqual(settings["worktree"]["baseRef"], "head")
        self.assertEqual(settings["hooks"]["PreToolUse"][0]["matcher"], "Agent")
        self.assertIn(".claude/settings.local.json", (copy / ".worktreeinclude").read_text())

    def test_in14_a_recorded_setup_and_check_run_in_the_copy(self):
        self.install_and_commit()
        habits = self.project / "sarah" / "habits.md"
        text = habits.read_text().replace("## Settings\n", "## Settings\n\n- setup: touch ready.flag\n- check: test -f ready.flag\n", 1)
        habits.write_text(text)
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "record setup")
        copy = self.base / "copy"
        self.git("worktree", "add", "-q", "-b", "feature/y", str(copy))
        recorded = {}
        for line in (copy / "sarah" / "habits.md").read_text().splitlines():
            for key in ("setup", "check"):
                if line.startswith(f"- {key}: "):
                    recorded[key] = line[len(f"- {key}: "):]
        self.assertEqual(set(recorded), {"setup", "check"})
        failed = subprocess.run(["sh", "-c", recorded["check"]], cwd=copy)
        self.assertNotEqual(failed.returncode, 0, "the check fails before setup: that is the baseline")
        subprocess.run(["sh", "-c", recorded["setup"]], cwd=copy, check=True)
        subprocess.run(["sh", "-c", recorded["check"]], cwd=copy, check=True)


if __name__ == "__main__":
    unittest.main()
