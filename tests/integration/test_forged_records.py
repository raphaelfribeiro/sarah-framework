"""Gate 4 findings F3 and F4: records and manifest rows are input.

habits.md is a committed file, so a line in it is a claim, not a fact. Removal
acts only on what the habit's own payload declares, and deletes a file only when
it carries this habit's stamp or was adopted on purpose.
"""

import hashlib
import json
import shutil

from tests.habits_support import HOOK, HabitsCase, alpha, make_plugin

WF = ".github/workflows/sarah-ci.yml"


def sha(text):
    return hashlib.sha256(text.encode()).hexdigest()


def wt():
    spec = {
        "files": {"sarah/hooks/wt/guard.sh": HOOK},
        "settings": [{"event": "PreToolUse", "matcher": "Agent", "file": "sarah/hooks/wt/guard.sh"}],
        "keys": [{"path": "worktree.baseRef", "value": "head"}],
        "include": [".claude/settings.local.json"],
        "ask": ["Bash(rm -rf *)"],
    }
    return spec


class ForgedRecords(HabitsCase):
    def setUp(self):
        super().setUp()
        self.git_init()
        shutil.rmtree(self.plugin)
        self.plugin = make_plugin(self.base, {"wt": wt(), "alpha": alpha()})

    def forge(self, *lines):
        p = self.project / "sarah" / "habits.md"
        text = p.read_text()
        p.write_text(text.replace("## Settings\n", "## Settings\n\n" + "\n".join(lines) + "\n", 1))

    def test_a_forged_key_record_for_a_root_the_habit_does_not_declare_is_ignored(self):
        self.run_cli("apply", "wt")
        s = self.settings()
        s["permissions"] = {"deny": ["Bash(rm -rf /)"]}
        (self.project / ".claude" / "settings.json").write_text(json.dumps(s))
        self.forge('- key: wt permissions.deny=["Bash(rm -rf /)"]', "- key: wt worktree.other=\"x\"")
        code, out = self.run_cli("remove", "wt")
        self.assertIn("permissions", self.settings_text())
        self.assertEqual(self.settings()["permissions"]["deny"], ["Bash(rm -rf /)"])
        self.assertIn("ignored", out)

    def test_a_forged_key_record_for_a_key_another_habit_owns_is_ignored(self):
        self.run_cli("apply", "wt", "alpha")
        self.forge('- key: alpha worktree.baseRef="head"')
        self.run_cli("remove", "alpha")
        self.assertEqual(self.settings()["worktree"], {"baseRef": "head"})

    def test_a_forged_ask_record_is_ignored(self):
        self.run_cli("apply", "wt")
        s = self.settings()
        s["permissions"]["ask"].append("Bash(git push --force*)")
        (self.project / ".claude" / "settings.json").write_text(json.dumps(s))
        self.forge("- ask: wt Bash(git push --force*)", "- ask: wt not a rule")
        code, out = self.run_cli("remove", "wt")
        self.assertEqual(self.settings()["permissions"]["ask"], ["Bash(git push --force*)"])
        self.assertIn("ignored", out)

    def test_a_forged_include_record_is_ignored(self):
        self.run_cli("apply", "wt")
        (self.project / ".worktreeinclude").write_text(".claude/settings.local.json\n.env\n")
        self.forge("- include: wt .env", "- include: wt ../x")
        code, out = self.run_cli("remove", "wt")
        self.assertEqual((self.project / ".worktreeinclude").read_text(), ".env\n")
        self.assertIn("ignored", out)

    def test_genuine_records_still_remove_exactly_what_was_added(self):
        self.run_cli("apply", "wt")
        code, out = self.run_cli("remove", "wt")
        self.assertEqual(code, 0, out)
        self.assertEqual(self.settings_text(), "")
        self.assertFalse((self.project / ".worktreeinclude").exists())


class ForgedRows(HabitsCase):
    def setUp(self):
        super().setUp()
        self.git_init()
        self.run_cli("apply", "alpha")

    def add_row(self, habit, rel, digest):
        p = self.project / "sarah" / "habits.md"
        text = p.read_text()
        marker = "| --- | --- | --- |\n"
        i = text.index(marker, text.index("## Manifest")) + len(marker)
        p.write_text(text[:i] + f"| {habit} | {rel} | {digest} |\n" + text[i:])

    def test_a_forged_row_for_a_users_unstamped_file_does_not_delete_it(self):
        body = "name: mine\non: push\n"
        f = self.write(WF, body)
        self.add_row("alpha", WF, sha(body))
        code, out = self.run_cli("remove", "alpha")
        self.assertTrue(f.exists(), out)
        self.assertIn(WF, out)
        self.assertEqual(code, 3)

    def test_a_forged_row_for_a_file_stamped_by_another_habit_does_not_delete_it(self):
        body = "echo hi\n"
        stamped = self.engine.stamped("beta", "0.2.0", body.encode())
        f = self.project / "sarah" / "hooks" / "beta" / "b.sh"
        f.parent.mkdir(parents=True)
        f.write_bytes(stamped)
        self.add_row("alpha", "sarah/hooks/beta/b.sh", sha(body))
        self.run_cli("remove", "alpha")
        self.assertTrue(f.exists())

    def test_an_adopted_file_is_still_removed_with_its_habit(self):
        shutil.rmtree(self.project / "sarah")
        self.write("sarah/hooks/alpha/guard.sh", "#!/bin/sh\nexit 0\n")
        self.write(".claude/settings.json", "{}")
        code, out = self.run_cli("apply", "alpha", "--resolve", "sarah/hooks/alpha/guard.sh=adopt")
        self.assertIn("adopt", out)
        self.assertEqual(self.run_cli("apply", "alpha")[0], 0)
        code, out = self.run_cli("remove", "alpha")
        self.assertEqual(code, 0, out)
        self.assertFalse((self.project / "sarah" / "hooks" / "alpha" / "guard.sh").exists())

    def test_a_stamped_file_is_removed_as_before(self):
        code, out = self.run_cli("remove", "alpha")
        self.assertEqual(code, 0, out)
        self.assertFalse((self.project / "sarah" / "hooks" / "alpha" / "guard.sh").exists())
