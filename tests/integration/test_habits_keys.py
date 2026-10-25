"""IN15 and the settings keys / worktree include lines of a payload (R17, D5).

A payload may add scalar keys under an allowed root to .claude/settings.json and
lines to .worktreeinclude. The engine records what it added in Settings, so that
remove takes out exactly that, and a value of the user's own is a conflict.
"""

import json
import shutil

from tests.habits_support import HOOK, HabitsCase, alpha, make_plugin, tree

KEYS = [{"path": "worktree.baseRef", "value": "head"}]
INCLUDE = [".claude/settings.local.json"]


def wt(keys=KEYS, include=INCLUDE):
    spec = {
        "files": {"sarah/hooks/wt/guard.sh": HOOK},
        "settings": [{"event": "PreToolUse", "matcher": "Agent", "file": "sarah/hooks/wt/guard.sh"}],
    }
    spec["keys"] = keys
    spec["include"] = include
    return spec


class Keys(HabitsCase):
    def setUp(self):
        super().setUp()
        self.git_init()
        shutil.rmtree(self.plugin)
        self.plugin = make_plugin(self.base, {"wt": wt(), "alpha": alpha()})

    def apply(self, *extra):
        return self.run_cli("apply", *extra, "wt")

    def test_apply_adds_the_key_and_the_include_line_and_records_them(self):
        code, out = self.apply()
        self.assertEqual(code, 0, out)
        self.assertEqual(self.settings()["worktree"], {"baseRef": "head"})
        self.assertEqual((self.project / ".worktreeinclude").read_text(), ".claude/settings.local.json\n")
        habits = (self.project / "sarah" / "habits.md").read_text()
        self.assertIn("- key: wt worktree.baseRef=\"head\"", habits)
        self.assertIn("- include: wt .claude/settings.local.json", habits)

    def test_plan_names_both_and_writes_nothing(self):
        before = tree(self.project)
        code, out = self.run_cli("plan", "wt")
        self.assertEqual(code, 0, out)
        self.assertIn("settings add key worktree.baseRef", out)
        self.assertIn("worktreeinclude add .claude/settings.local.json", out)
        self.assertEqual(tree(self.project), before)

    def test_rerun_changes_nothing(self):
        self.apply()
        before = tree(self.project)
        code, out = self.apply()
        self.assertEqual(code, 0, out)
        self.assertEqual(tree(self.project), before)
        self.assertNotIn("settings add key", out)

    def test_in15_a_different_user_value_is_a_conflict_and_is_never_overwritten(self):
        self.write(".claude/settings.json", json.dumps({"worktree": {"baseRef": "fresh"}}))
        code, out = self.apply()
        self.assertEqual(code, 3, out)
        self.assertIn("conflict", out)
        self.assertEqual(self.settings()["worktree"]["baseRef"], "fresh")
        self.assertNotIn("key: wt", (self.project / "sarah" / "habits.md").read_text())
        # the rest of the habit still installs
        self.assertTrue((self.project / "sarah" / "hooks" / "wt" / "guard.sh").exists())

    def test_a_user_value_equal_to_ours_is_not_ours_and_remove_keeps_it(self):
        self.write(".claude/settings.json", json.dumps({"worktree": {"baseRef": "head"}}))
        code, out = self.apply()
        self.assertEqual(code, 0, out)
        self.assertNotIn("key: wt", (self.project / "sarah" / "habits.md").read_text())
        self.run_cli("remove", "wt")
        self.assertEqual(self.settings()["worktree"], {"baseRef": "head"})

    def test_existing_include_lines_are_kept_and_not_recorded_twice(self):
        self.write(".worktreeinclude", ".env\n.claude/settings.local.json\n")
        self.apply()
        self.assertEqual((self.project / ".worktreeinclude").read_text(), ".env\n.claude/settings.local.json\n")
        self.assertNotIn("- include:", (self.project / "sarah" / "habits.md").read_text())
        self.run_cli("remove", "wt")
        self.assertEqual((self.project / ".worktreeinclude").read_text(), ".env\n.claude/settings.local.json\n")

    def test_a_missing_final_newline_is_repaired_not_glued(self):
        self.write(".worktreeinclude", ".env")
        self.apply()
        self.assertEqual((self.project / ".worktreeinclude").read_text(), ".env\n.claude/settings.local.json\n")

    def test_remove_restores_a_bare_project(self):
        before = tree(self.project)
        self.apply()
        code, out = self.run_cli("remove", "wt")
        self.assertEqual(code, 0, out)
        after = tree(self.project)
        habits = after.pop("sarah/habits.md").decode()
        after.pop("sarah")
        self.assertEqual(after, before)
        self.assertNotIn("- key:", habits)
        self.assertNotIn("- include:", habits)

    def test_remove_takes_out_only_what_was_added(self):
        self.write(".claude/settings.json", json.dumps({"worktree": {"other": 1}, "theme": "x"}))
        self.write(".worktreeinclude", ".env\n")
        self.apply()
        self.run_cli("remove", "wt")
        self.assertEqual(self.settings(), {"worktree": {"other": 1}, "theme": "x"})
        self.assertEqual((self.project / ".worktreeinclude").read_text(), ".env\n")

    def test_remove_keeps_a_value_the_user_changed_since(self):
        self.apply()
        s = self.settings()
        s["worktree"]["baseRef"] = "fresh"
        self.write(".claude/settings.json", json.dumps(s))
        code, out = self.run_cli("remove", "wt")
        self.assertEqual(code, 3, out)
        self.assertEqual(self.settings()["worktree"]["baseRef"], "fresh")
        self.assertNotIn("key: wt", (self.project / "sarah" / "habits.md").read_text())

    def test_removing_another_habit_leaves_ours(self):
        self.run_cli("apply", "wt", "alpha")
        self.run_cli("remove", "alpha")
        self.assertEqual(self.settings()["worktree"], {"baseRef": "head"})
        self.assertIn(".claude/settings.local.json", (self.project / ".worktreeinclude").read_text())

    def test_status_reports_a_missing_key(self):
        self.apply()
        s = self.settings()
        del s["worktree"]
        self.write(".claude/settings.json", json.dumps(s))
        code, out = self.run_cli("status")
        self.assertEqual(code, 1, out)
        self.assertIn("worktree.baseRef", out)

    def test_status_is_clean_after_apply(self):
        self.apply()
        code, out = self.run_cli("status")
        self.assertEqual(code, 0, out)

    def test_a_malformed_user_settings_file_is_refused_and_nothing_written(self):
        self.write(".claude/settings.json", "{not json")
        before = tree(self.project)
        code, out = self.apply()
        self.assertEqual(code, 1, out)
        self.assertEqual(tree(self.project), before)

    def test_a_worktree_key_that_is_not_an_object_is_a_conflict(self):
        self.write(".claude/settings.json", json.dumps({"worktree": "x"}))
        code, out = self.apply()
        self.assertEqual(code, 3, out)
        self.assertEqual(self.settings()["worktree"], "x")


class Containment(HabitsCase):
    def refused(self, spec):
        shutil.rmtree(self.plugin)
        self.plugin = make_plugin(self.base, {"bad": spec})
        before = tree(self.project)
        code, out = self.run_cli("apply", "bad")
        self.assertEqual(code, 1, out)
        self.assertEqual(tree(self.project), before)

    def test_keys_outside_the_allowed_roots_are_refused(self):
        for path in ("hooks.x", "permissions.allow", "env.PATH", "enabledPlugins", "worktree.a.b", "../x", "a b"):
            with self.subTest(path):
                spec = alpha()
                spec["keys"] = [{"path": path, "value": "x"}]
                self.refused(spec)

    def test_keys_must_be_scalars(self):
        for value in ({"a": 1}, ["x"], None):
            with self.subTest(value):
                spec = alpha()
                spec["keys"] = [{"path": "worktree.baseRef", "value": value}]
                self.refused(spec)

    def test_include_lines_must_be_plain_project_paths(self):
        for line in ("/etc/passwd", "../x", "a/../b", "!keep", "#c", "a\nb", "", "a\\b", "~/x"):
            with self.subTest(line):
                spec = alpha()
                spec["include"] = [line]
                self.refused(spec)
