"""Unit tests for scripts/habits.py: UH1-UH12.

Every test here ran red against an empty stub first (see the commit message).
"""

import json
import os
from pathlib import Path

from tests.habits_support import HOOK, HabitsCase, alpha, make_plugin


class Stamp(HabitsCase):
    def test_uh1_stamp_carries_habit_version_and_sha256(self):
        body = b"echo hi\n"
        digest = self.engine.digest(body)
        line = self.engine.stamp_line("alpha", "0.2.0", digest)
        self.assertEqual(line, f"# sarah-habit: alpha 0.2.0 sha256:{digest}")
        self.assertEqual(len(digest), 64)

    def test_uh1_hash_excludes_the_stamp(self):
        body = b"echo hi\n"
        data = self.engine.stamped("alpha", "0.2.0", body)
        stamp, rest = self.engine.split_stamp(data)
        self.assertEqual(rest, body)
        self.assertEqual(stamp, {"habit": "alpha", "version": "0.2.0", "sha256": self.engine.digest(body)})
        self.assertTrue(data.startswith(b"# sarah-habit: alpha 0.2.0 sha256:"))

    def test_uh1_unstamped_data_has_no_stamp(self):
        stamp, rest = self.engine.split_stamp(b"#!/bin/sh\nexit 0\n")
        self.assertIsNone(stamp)
        self.assertEqual(rest, b"#!/bin/sh\nexit 0\n")


class Classifier(HabitsCase):
    def test_uh11_four_classes(self):
        e = self.engine
        body = b"x\n"
        d = e.digest(body)
        self.assertEqual(e.classify(None, d, None), "absent")
        self.assertEqual(e.classify(e.stamped("alpha", "0.2.0", body), d, None), "match")
        self.assertEqual(e.classify(e.stamped("alpha", "0.1.0", b"old\n"), d, None), "stale")
        edited = e.stamped("alpha", "0.2.0", body).replace(b"x\n", b"y\n")
        self.assertEqual(e.classify(edited, d, None), "edited")
        self.assertEqual(e.classify(b"mine\n", d, None), "unmanaged")

    def test_uh11_adopted_file_is_a_match_until_it_changes(self):
        e = self.engine
        mine = b"mine\n"
        self.assertEqual(e.classify(mine, "f" * 64, e.digest(mine)), "match")
        self.assertEqual(e.classify(b"mine, changed\n", "f" * 64, e.digest(mine)), "edited")

    def test_uh11_habit_name_comes_from_a_fixed_set(self):
        for bad in ["", "../x", "a/b", "A", "a b", ".hidden", "x" * 80, "a\n"]:
            with self.assertRaises(self.engine.Refused, msg=repr(bad)):
                self.engine.check_habit_name(bad)
        for good in ["alpha", "gitflow", "_fixture", "no-idle", "a_b"]:
            self.engine.check_habit_name(good)


class SettingsMerge(HabitsCase):
    ENTRY = ("PreToolUse", "Bash", 'sh "$CLAUDE_PROJECT_DIR/sarah/hooks/alpha/guard.sh"')

    def test_uh3_keeps_user_keys_order_and_hooks(self):
        user = {
            "model": "opus",
            "permissions": {"allow": ["Bash(ls)"]},
            "hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "mine.sh"}]}]},
            "env": {"A": "1"},
        }
        merged = self.engine.merge_settings(json.loads(json.dumps(user)), [self.ENTRY])
        self.assertEqual(list(merged), ["model", "permissions", "hooks", "env"])
        self.assertEqual(merged["permissions"], user["permissions"])
        groups = merged["hooks"]["PreToolUse"]
        self.assertEqual(groups[0], user["hooks"]["PreToolUse"][0])
        self.assertEqual(groups[1]["hooks"][0]["command"], self.ENTRY[2])

    def test_uh3_applied_twice_is_identical(self):
        once = self.engine.merge_settings({}, [self.ENTRY])
        twice = self.engine.merge_settings(json.loads(json.dumps(once)), [self.ENTRY])
        self.assertEqual(once, twice)
        self.assertEqual(json.dumps(once), json.dumps(twice))

    def test_uh3_apply_twice_leaves_the_file_byte_identical(self):
        self.assertEqual(self.run_cli("apply", "alpha")[0], 0)
        first = (self.project / ".claude" / "settings.json").read_bytes()
        self.assertEqual(self.run_cli("apply", "alpha")[0], 0)
        self.assertEqual((self.project / ".claude" / "settings.json").read_bytes(), first)

    def test_uh4_invalid_settings_are_never_clobbered(self):
        for text in ["{not json", "[1, 2]", '"string"', "{"]:
            with self.subTest(text=text):
                p = self.write(".claude/settings.json", text)
                code, out = self.run_cli("apply", "alpha")
                self.assertEqual(code, 1, out)
                self.assertEqual(p.read_text(), text)
                self.assertFalse((self.project / "sarah").exists(), "nothing else is written either")

    def test_uh4_absent_and_empty_become_a_settings_object(self):
        self.assertEqual(self.run_cli("apply", "alpha")[0], 0)
        self.assertIn("hooks", self.settings())

    def test_uh4_empty_file_is_treated_as_empty_object(self):
        self.write(".claude/settings.json", "  \n")
        self.assertEqual(self.run_cli("apply", "alpha")[0], 0)
        self.assertIn("hooks", self.settings())

    def test_uh4_bom_is_read_and_kept(self):
        p = self.project / ".claude" / "settings.json"
        p.parent.mkdir()
        p.write_bytes(b"\xef\xbb\xbf" + json.dumps({"model": "opus"}).encode())
        self.assertEqual(self.run_cli("apply", "alpha")[0], 0)
        raw = p.read_bytes()
        self.assertTrue(raw.startswith(b"\xef\xbb\xbf"))
        data = json.loads(raw.decode("utf-8-sig"))
        self.assertEqual(data["model"], "opus")
        self.assertIn("hooks", data)

    def test_uh5_entries_are_identified_by_command_path_and_removal_drops_only_ours(self):
        user = {"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "mine.sh"}]}]}}
        merged = self.engine.merge_settings(json.loads(json.dumps(user)), [self.ENTRY])
        stripped, removed = self.engine.remove_settings(merged, "alpha")
        self.assertEqual(removed, 1)
        self.assertEqual(stripped, user)

    def test_uh5_removal_does_not_match_a_longer_habit_name(self):
        entry = ("PreToolUse", "Bash", 'sh "$CLAUDE_PROJECT_DIR/sarah/hooks/alpha-two/guard.sh"')
        merged = self.engine.merge_settings({}, [entry])
        stripped, removed = self.engine.remove_settings(merged, "alpha")
        self.assertEqual(removed, 0)
        self.assertEqual(stripped, merged)

    def test_uh6_never_writes_allow_rules_or_touches_permissions(self):
        self.run_cli("apply", "alpha")
        self.assertNotIn("permissions", self.settings())
        self.assertNotIn("allow", json.dumps(self.settings()))


class Manifest(HabitsCase):
    def test_uh8_round_trip(self):
        rows = [("alpha", "sarah/hooks/alpha/guard.sh", "a" * 64), ("beta", "sarah/hooks/beta/b.sh", "b" * 64)]
        text = self.engine.render_manifest(rows)
        parsed, warnings = self.engine.parse_manifest(text.splitlines())
        self.assertEqual(parsed, rows)
        self.assertEqual(warnings, [])

    def test_uh8_malformed_rows_are_ignored_with_one_line_each(self):
        lines = [
            "| habit | path | sha256 |",
            "| --- | --- | --- |",
            "| alpha | sarah/hooks/alpha/guard.sh | " + "a" * 64 + " |",
            "| alpha | only-two-cells |",
            "| alpha | sarah/hooks/alpha/x.sh | not-a-hash |",
            "| Bad Name | sarah/hooks/x | " + "a" * 64 + " |",
        ]
        parsed, warnings = self.engine.parse_manifest(lines)
        self.assertEqual(len(parsed), 1)
        self.assertEqual(len(warnings), 3)


class Containment(HabitsCase):
    def refused(self, rel):
        with self.assertRaises(self.engine.Refused, msg=repr(rel)):
            self.engine.contain(self.project, rel)

    def test_uh9_dotdot_absolute_and_empty_are_refused(self):
        for rel in ["../outside.sh", "sarah/hooks/../../x", "sarah/hooks/alpha/../../../x", "/etc/passwd", "", ".", "a\0b", "\\abs", "C:\\x"]:
            self.refused(rel)

    def test_uh9_symlink_directory_escape_is_refused(self):
        outside = self.base / "outside"
        outside.mkdir()
        (self.project / "sarah").mkdir()
        os.symlink(outside, self.project / "sarah" / "hooks")
        self.refused("sarah/hooks/alpha/guard.sh")

    def test_uh9_a_symlink_as_the_target_itself_is_refused(self):
        outside = self.base / "victim.sh"
        outside.write_text("keep")
        (self.project / "sarah" / "hooks").mkdir(parents=True)
        os.symlink(outside, self.project / "sarah" / "hooks" / "x.sh")
        self.refused("sarah/hooks/x.sh")

    def test_uh9_a_path_inside_the_project_resolves(self):
        got = self.engine.contain(self.project, "sarah/hooks/alpha/guard.sh")
        self.assertEqual(got, self.project / "sarah" / "hooks" / "alpha" / "guard.sh")

    def test_uh9_paths_outside_the_install_prefixes_are_refused(self):
        for rel in ["sarah/state.md", "ARCHI.md", "src/app.py", ".claude/settings.json", ".github/workflows/ci.yml", "sarah/hooks"]:
            with self.assertRaises(self.engine.Refused, msg=rel):
                self.engine.check_prefix(rel)
        self.engine.check_prefix("sarah/hooks/alpha/guard.sh")
        self.engine.check_prefix(".github/workflows/sarah-gitflow.yml")


class NoNetwork(HabitsCase):
    def test_uh12_sockets_are_patched_to_fail_for_this_suite(self):
        import socket

        with self.assertRaises(AssertionError):
            socket.socket().connect(("127.0.0.1", 9))
