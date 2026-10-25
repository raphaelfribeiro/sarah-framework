"""Integration tests for scripts/habits.py against scratch projects.

IN1-IN13, plus the tamper tests that the test plan's section 8 puts first.
"""

import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from unittest import mock

from tests.habits_support import HOOK, SCRIPT, HabitsCase, alpha, make_plugin, mtimes, tree


def sha(text):
    return hashlib.sha256(text.encode()).hexdigest()


def manifest_row(habit, path, text):
    return f"| {habit} | {path} | {sha(text)} |"


def seed_habits_md(project, rows):
    """A habits.md as the engine would write it, with arbitrary manifest rows."""
    body = "\n".join(["| habit | path | sha256 |", "| --- | --- | --- |", *rows])
    (project / "sarah").mkdir(exist_ok=True)
    (project / "sarah" / "habits.md").write_text(
        "# Habits\n\n## Chosen\n\n- alpha\n\n## Settings\n\n## Autonomy\n\n## Manifest\n\n" + body + "\n\n## Exceptions\n"
    )


class Install(HabitsCase):
    def setUp(self):
        super().setUp()
        self.git_init()

    def other_plugin(self, name, habits):
        (self.base / name).mkdir()
        return make_plugin(self.base / name, habits)

    def hook_path(self):
        return self.project / "sarah" / "hooks" / "alpha" / "guard.sh"

    def test_in1_fresh_install_writes_files_modes_stamps_settings_manifest(self):
        code, out = self.run_cli("apply", "alpha")
        self.assertEqual(code, 0, out)
        data = self.hook_path().read_text()
        first, body = data.split("\n", 1)
        self.assertEqual(first, f"# sarah-habit: alpha 0.2.0 sha256:{sha(HOOK)}")
        self.assertEqual(body, HOOK)
        self.assertTrue(os.access(self.hook_path(), os.X_OK), "mode is carried over")
        cmd = self.settings()["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
        self.assertEqual(cmd, 'sh "$CLAUDE_PROJECT_DIR/sarah/hooks/alpha/guard.sh"')
        habits = (self.project / "sarah" / "habits.md").read_text()
        self.assertIn(manifest_row("alpha", "sarah/hooks/alpha/guard.sh", HOOK), habits)
        for section in ["## Chosen", "## Settings", "## Autonomy", "## Manifest", "## Exceptions"]:
            self.assertIn(section, habits)
        code, status = self.run_cli("status")
        self.assertEqual(code, 0, status)
        self.assertIn("alpha", status)
        self.assertNotIn("beta", status)

    def test_in1_gitignore_gets_the_local_dir_once(self):
        self.write(".gitignore", "build/\n")
        self.run_cli("apply", "alpha")
        self.run_cli("apply", "beta")
        lines = (self.project / ".gitignore").read_text().splitlines()
        self.assertEqual(lines, ["build/", "sarah/.local/"])

    def test_in2_declining_everything_leaves_the_tree_byte_identical(self):
        self.write("README.md", "mine\n")
        before = tree(self.project)
        code, out = self.run_cli("apply")
        self.assertEqual(code, 0, out)
        self.assertEqual(tree(self.project), before)

    def test_uh2_plan_writes_nothing_and_names_the_actions(self):
        before = tree(self.project)
        code, out = self.run_cli("plan", "alpha")
        self.assertEqual(code, 0, out)
        self.assertEqual(tree(self.project), before)
        self.assertRegex(out, r"(?m)^create sarah/hooks/alpha/guard\.sh$")
        self.assertRegex(out, r"(?m)^settings add PreToolUse Bash ")

    def test_uh2_an_empty_plan_for_no_habits(self):
        code, out = self.run_cli("plan")
        self.assertEqual(code, 0)
        self.assertNotRegex(out, r"(?m)^(create|update|settings|gitignore)")

    def test_in3_reinstall_changes_nothing_not_even_mtimes(self):
        self.run_cli("apply", "alpha")
        before, stamps = tree(self.project), mtimes(self.project)
        code, out = self.run_cli("apply", "alpha")
        self.assertEqual(code, 0, out)
        self.assertEqual(tree(self.project), before)
        self.assertEqual(mtimes(self.project), stamps)

    def test_in4_reinstall_after_a_user_edit_keeps_the_content_and_asks(self):
        self.run_cli("apply", "alpha")
        edited = self.hook_path().read_text() + "# my change\n"
        self.hook_path().write_text(edited)
        code, out = self.run_cli("apply", "alpha")
        self.assertEqual(code, 3, out)
        self.assertRegex(out, r"(?m)^conflict sarah/hooks/alpha/guard\.sh edited")
        self.assertEqual(self.hook_path().read_text(), edited)

    def test_in4_an_explicit_overwrite_decision_restores_the_payload(self):
        self.run_cli("apply", "alpha")
        self.hook_path().write_text(self.hook_path().read_text() + "# my change\n")
        code, out = self.run_cli("apply", "alpha", "--resolve", "sarah/hooks/alpha/guard.sh=overwrite")
        self.assertEqual(code, 0, out)
        self.assertNotIn("my change", self.hook_path().read_text())

    def test_in5_unstamped_file_at_target_skip_by_default(self):
        mine = "#!/bin/sh\necho mine\n"
        self.write("sarah/hooks/alpha/guard.sh", mine)
        code, out = self.run_cli("apply", "alpha")
        self.assertEqual(code, 3, out)
        self.assertRegex(out, r"(?m)^conflict sarah/hooks/alpha/guard\.sh unmanaged")
        self.assertEqual(self.hook_path().read_text(), mine)
        self.assertNotIn("guard.sh", (self.project / "sarah" / "habits.md").read_text())

    def test_in5_adopt_records_the_file_without_touching_it(self):
        mine = "#!/bin/sh\necho mine\n"
        self.write("sarah/hooks/alpha/guard.sh", mine)
        code, out = self.run_cli("apply", "alpha", "--resolve", "sarah/hooks/alpha/guard.sh=adopt")
        self.assertEqual(code, 0, out)
        self.assertEqual(self.hook_path().read_text(), mine)
        self.assertIn(manifest_row("alpha", "sarah/hooks/alpha/guard.sh", mine), (self.project / "sarah" / "habits.md").read_text())
        self.assertEqual(self.run_cli("apply", "alpha")[0], 0, "adopted file re-runs clean")

    def test_in5_wrap_installs_ours_beside_theirs(self):
        mine = "#!/bin/sh\necho mine\n"
        self.write("sarah/hooks/alpha/guard.sh", mine)
        code, out = self.run_cli("apply", "alpha", "--resolve", "sarah/hooks/alpha/guard.sh=wrap")
        self.assertEqual(code, 0, out)
        self.assertEqual(self.hook_path().read_text(), mine)
        wrapped = self.project / "sarah" / "hooks" / "alpha" / "guard.sarah.sh"
        self.assertTrue(wrapped.read_text().endswith(HOOK))
        cmd = self.settings()["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
        self.assertIn("guard.sarah.sh", cmd)
        before = tree(self.project)
        self.assertEqual(self.run_cli("apply", "alpha")[0], 0, "wrapped file re-runs clean")
        self.assertEqual(tree(self.project), before)

    def test_in6_remove_with_unchanged_files_takes_out_files_entries_and_rows(self):
        self.run_cli("apply", "alpha", "beta")
        code, out = self.run_cli("remove", "alpha")
        self.assertEqual(code, 0, out)
        self.assertFalse(self.hook_path().exists())
        self.assertNotIn("alpha", self.settings_text())
        habits = (self.project / "sarah" / "habits.md").read_text()
        self.assertNotIn("alpha", habits)
        self.assertIn("beta", habits)
        self.assertTrue((self.project / "sarah" / "hooks" / "beta" / "b.sh").exists())

    def test_in7_remove_keeps_an_edited_file_and_says_so(self):
        self.run_cli("apply", "alpha")
        edited = self.hook_path().read_text() + "# mine\n"
        self.hook_path().write_text(edited)
        code, out = self.run_cli("remove", "alpha")
        self.assertEqual(code, 3, out)
        self.assertRegex(out, r"(?m)^kept sarah/hooks/alpha/guard\.sh edited")
        self.assertEqual(self.hook_path().read_text(), edited)
        self.assertNotIn("alpha", self.settings_text())

    def test_in8_install_then_remove_restores_the_tree(self):
        user_settings = {"model": "opus", "hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "mine.sh"}]}]}}
        self.write(".claude/settings.json", json.dumps(user_settings, indent=2) + "\n")
        self.write(".github/workflows/ci.yml", "name: ci\n")
        self.write("sarah/hooks/own.sh", "exit 0\n")
        self.write(".gitignore", "build/\n")
        before = tree(self.project)
        self.assertEqual(self.run_cli("apply", "alpha", "beta")[0], 0)
        self.assertEqual(self.run_cli("remove", "alpha", "beta")[0], 0)
        after = tree(self.project)
        after.pop("sarah/habits.md", None)
        before_wo = dict(before)
        self.assertEqual(after, before_wo)

    def test_in8_remove_from_a_bare_project_leaves_no_empty_dirs_or_settings(self):
        before = tree(self.project)
        self.run_cli("apply", "alpha")
        self.run_cli("remove", "alpha")
        after = tree(self.project)
        after.pop("sarah/habits.md", None)
        if not [k for k in after if k.startswith("sarah/")]:
            after.pop("sarah", None)
        self.assertEqual(after, before)

    def test_in9_works_without_git(self):
        subprocess.run(["rm", "-rf", str(self.project / ".git")], check=True)
        code, out = self.run_cli("apply", "alpha")
        self.assertEqual(code, 0, out)
        self.assertEqual(self.run_cli("status")[0], 0)
        self.assertEqual(self.run_cli("remove", "alpha")[0], 0)

    def test_in9_a_habit_that_needs_git_or_gh_is_refused_and_others_still_work(self):
        plugin = self.other_plugin("p2", {"needy": {**alpha(), "requires": ["git", "gh"]}, "plain": {"files": {"sarah/hooks/plain/p.sh": HOOK}}},
        )
        subprocess.run(["rm", "-rf", str(self.project / ".git")], check=True)
        before = tree(self.project)
        code, out = self.run_cli("apply", "needy", plugin=plugin)
        self.assertEqual(code, 1, out)
        self.assertIn("needy", out)
        self.assertEqual(tree(self.project), before)
        self.assertEqual(self.run_cli("apply", "plain", plugin=plugin)[0], 0)

    def test_in9_gh_missing_refuses_a_habit_that_requires_gh(self):
        plugin = self.other_plugin("p3", {"needy": {**alpha(), "requires": ["gh"]}})
        with mock.patch("shutil.which", return_value=None):
            code, out = self.run_cli("apply", "needy", plugin=plugin)
        self.assertEqual(code, 1, out)
        self.assertIn("gh", out)

    def test_in9_a_remote_requirement_checks_git_remote(self):
        plugin = self.other_plugin("p4", {"needy": {**alpha(), "requires": ["remote"]}})
        code, out = self.run_cli("apply", "needy", plugin=plugin)
        self.assertEqual(code, 1, out)
        subprocess.run(["git", "-C", str(self.project), "remote", "add", "origin", "../origin.git"], check=True)
        self.assertEqual(self.run_cli("apply", "needy", plugin=plugin)[0], 0)

    def test_in11_a_crash_at_any_point_leaves_a_state_status_explains_and_rerun_finishes(self):
        clean = self.base / "clean"
        clean.mkdir()
        reference = self.project
        self.project = clean
        self.assertEqual(self.run_cli("apply", "alpha", "beta")[0], 0)
        expected = tree(clean)
        self.project = reference

        crashes = 0
        for n in range(0, 12):
            with self.subTest(replace_calls_allowed=n):
                scratch = self.base / f"crash{n}"
                scratch.mkdir()
                self.project = scratch
                real, calls = os.replace, {"n": 0}

                def flaky(src, dst, *a, **k):
                    if calls["n"] >= n:
                        raise OSError("simulated crash")
                    calls["n"] += 1
                    return real(src, dst, *a, **k)

                with mock.patch("os.replace", side_effect=flaky):
                    try:
                        code, out = self.run_cli("apply", "alpha", "beta")
                    except OSError:
                        code = None
                if code == 0:
                    self.assertEqual(tree(scratch), expected)
                    continue
                crashes += 1
                junk = [k for k in tree(scratch) if ".sarah-tmp" in k]
                self.assertEqual(junk, [], "no temp files left behind")
                for path, data in tree(scratch).items():
                    if data and path.startswith("sarah/hooks/"):
                        self.assertIn(data, [v for v in expected.values() if v], "a file is whole or absent, never partial")
                scode, sout = self.run_cli("status")
                self.assertIn(scode, (0, 1), sout)
                self.assertTrue(sout.strip(), "status says something")
                code, out = self.run_cli("apply", "alpha", "beta")
                self.assertEqual(code, 0, out)
                self.assertEqual(tree(scratch), expected)
        self.assertGreater(crashes, 3, "the loop actually exercised crashes")

    def test_in11_a_failure_before_writing_leaves_the_old_state(self):
        self.run_cli("apply", "alpha")
        before = tree(self.project)
        with mock.patch("os.replace", side_effect=OSError("disk full")):
            try:
                self.run_cli("apply", "alpha", "beta")
            except OSError:
                pass
        self.assertEqual([k for k in tree(self.project) if ".sarah-tmp" in k], [])
        self.run_cli("apply", "alpha", "beta")
        self.assertTrue((self.project / "sarah" / "hooks" / "beta" / "b.sh").exists())
        self.assertEqual(tree(self.project)["sarah/hooks/alpha/guard.sh"], before["sarah/hooks/alpha/guard.sh"])

    def test_in11_status_reports_an_incomplete_apply(self):
        self.run_cli("apply", "alpha")
        self.hook_path().unlink()
        code, out = self.run_cli("status")
        self.assertEqual(code, 1, out)
        self.assertRegex(out, r"(?m)^missing sarah/hooks/alpha/guard\.sh")
        self.assertIn("apply", out)

    def test_in12_the_tree_change_equals_what_plan_listed(self):
        self.write("README.md", "mine\n")
        before = tree(self.project)
        _, plan = self.run_cli("plan", "alpha", "beta")
        listed = set(re.findall(r"(?m)^create (\S+)$", plan))
        self.assertEqual(self.run_cli("apply", "alpha", "beta")[0], 0)
        after = tree(self.project)
        added = {k for k, v in after.items() if k not in before and v is not None}
        self.assertEqual(added - {"sarah/habits.md", ".gitignore", ".claude/settings.json"}, listed)
        self.assertEqual({k for k in before if before[k] != after.get(k)}, set())

    def test_in13_a_symlinked_target_that_escapes_is_refused_and_nothing_is_written(self):
        outside = self.base / "outside"
        outside.mkdir()
        (self.project / "sarah").mkdir()
        os.symlink(outside, self.project / "sarah" / "hooks")
        code, out = self.run_cli("apply", "alpha")
        self.assertEqual(code, 1, out)
        self.assertEqual(list(outside.iterdir()), [])
        self.assertFalse((self.project / ".claude").exists())

    def test_in13_a_symlinked_file_target_is_not_written_through(self):
        victim = self.base / "victim.sh"
        victim.write_text("keep")
        (self.project / "sarah" / "hooks" / "alpha").mkdir(parents=True)
        os.symlink(victim, self.hook_path())
        code, out = self.run_cli("apply", "alpha")
        self.assertEqual(code, 1, out)
        self.assertEqual(victim.read_text(), "keep")

    def test_unknown_habit_is_an_error_and_writes_nothing(self):
        before = tree(self.project)
        code, out = self.run_cli("apply", "nope")
        self.assertEqual(code, 1, out)
        self.assertEqual(tree(self.project), before)

    def test_a_payload_that_is_a_symlink_is_refused(self):
        payload = self.plugin / "skills" / "sarah-init" / "habits" / "alpha" / "files" / "sarah" / "hooks" / "alpha"
        target = self.base / "elsewhere.sh"
        target.write_text("exit 0\n")
        os.symlink(target, payload / "link.sh")
        code, out = self.run_cli("apply", "alpha")
        self.assertEqual(code, 1, out)

    def test_habits_md_keeps_what_the_user_wrote_in_other_sections(self):
        self.run_cli("apply", "alpha")
        p = self.project / "sarah" / "habits.md"
        p.write_text(p.read_text().replace("## Autonomy\n", "## Autonomy\n\n- push feature/*: granted\n"))
        self.run_cli("apply", "beta")
        self.assertIn("- push feature/*: granted", p.read_text())
        self.run_cli("remove", "beta")
        self.assertIn("- push feature/*: granted", p.read_text())

    def test_reserved_sections_exist_and_are_kept_untouched(self):
        self.run_cli("apply", "alpha")
        p = self.project / "sarah" / "habits.md"
        text = p.read_text()
        self.assertIn("## Conversation defaults", text)
        self.assertIn("## Tracker", text)
        p.write_text(text.replace("## Conversation defaults\n", "## Conversation defaults\n\n- tone: off\n").replace(
            "## Tracker\n", "## Tracker\n\nLast audit: 2026-10-24\n"))
        self.run_cli("apply", "beta")
        self.run_cli("remove", "beta")
        out = p.read_text()
        self.assertIn("- tone: off", out)
        self.assertIn("Last audit: 2026-10-24", out)
        self.assertEqual(self.run_cli("status")[0], 0)

    def test_cli_entry_point_runs_as_a_script(self):
        proc = subprocess.run(
            [sys.executable, str(SCRIPT), "--project", str(self.project), "--plugin-root", str(self.plugin), "plan", "alpha"],
            capture_output=True, text=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("create sarah/hooks/alpha/guard.sh", proc.stdout)

    def test_the_shipped_fixture_payload_installs_and_is_inert(self):
        root = SCRIPT.parents[1]
        code, out = self.run_cli("apply", "_fixture", plugin=root)
        self.assertEqual(code, 0, out)
        scripts = list((self.project / "sarah" / "hooks" / "_fixture").glob("*.sh"))
        self.assertTrue(scripts)
        for s in scripts:
            proc = subprocess.run(["sh", str(s)], input="{}", capture_output=True, text=True)
            self.assertEqual((proc.returncode, proc.stdout), (0, ""), s.name)
        self.assertEqual(self.run_cli("remove", "_fixture", plugin=root)[0], 0)


class Tamper(HabitsCase):
    """A manifest is a committed file. A row in it must never reach outside the project."""

    def setUp(self):
        super().setUp()
        self.victim = self.base / "victim.txt"
        self.victim.write_text("precious")
        self.inside = self.write("sarah/state.md", "state\n")

    def seed_and_remove(self, path, text):
        seed_habits_md(self.project, [manifest_row("alpha", path, text)])
        return self.run_cli("remove", "alpha")

    def test_dotdot_row_deletes_nothing_outside(self):
        code, out = self.seed_and_remove("../victim.txt", "precious")
        self.assertEqual(self.victim.read_text(), "precious")
        self.assertRegex(out, r"(?m)^refused \.\./victim\.txt")

    def test_absolute_row_deletes_nothing(self):
        code, out = self.seed_and_remove(str(self.victim), "precious")
        self.assertEqual(self.victim.read_text(), "precious")
        self.assertIn("refused", out)

    def test_symlink_directory_row_deletes_nothing(self):
        (self.project / "sarah").mkdir(exist_ok=True)
        os.symlink(self.base, self.project / "sarah" / "hooks")
        code, out = self.seed_and_remove("sarah/hooks/victim.txt", "precious")
        self.assertEqual(self.victim.read_text(), "precious")
        self.assertIn("refused", out)

    def test_in_project_file_outside_the_install_prefixes_is_not_deleted(self):
        code, out = self.seed_and_remove("sarah/state.md", "state\n")
        self.assertEqual(self.inside.read_text(), "state\n")
        self.assertRegex(out, r"(?m)^refused sarah/state\.md")

    def test_a_row_whose_hash_no_longer_matches_is_kept(self):
        self.write("sarah/hooks/alpha/guard.sh", "changed\n")
        code, out = self.seed_and_remove("sarah/hooks/alpha/guard.sh", "original\n")
        self.assertEqual((self.project / "sarah/hooks/alpha/guard.sh").read_text(), "changed\n")
        self.assertRegex(out, r"(?m)^kept sarah/hooks/alpha/guard\.sh")

    def test_apply_does_not_overwrite_through_a_tampered_row(self):
        seed_habits_md(self.project, [manifest_row("alpha", "../victim.txt", "precious")])
        self.run_cli("apply", "alpha")
        self.assertEqual(self.victim.read_text(), "precious")

    def test_status_names_a_refused_row_and_touches_nothing(self):
        seed_habits_md(self.project, [manifest_row("alpha", "../victim.txt", "precious")])
        before = tree(self.project)
        code, out = self.run_cli("status")
        self.assertEqual(code, 1, out)
        self.assertRegex(out, r"(?m)^refused \.\./victim\.txt")
        self.assertEqual(tree(self.project), before)

    def test_a_row_naming_a_habit_other_than_the_one_removed_is_left_alone(self):
        self.write("sarah/hooks/beta/b.sh", "x\n")
        seed_habits_md(self.project, [manifest_row("beta", "sarah/hooks/beta/b.sh", "x\n")])
        self.run_cli("remove", "alpha")
        self.assertTrue((self.project / "sarah/hooks/beta/b.sh").exists())
