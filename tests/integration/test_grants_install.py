"""Integration tests for always-ask, grants and "declined all" in scripts/habits.py.

UH6, IN2 and the D9 rules: ask rules only tighten and are removed exactly; a
grant needs a quoted instruction; an allow rule is shown as a diff and written
only when asked to; declining everything is recordable.
"""

import json
import re
from datetime import date

from tests.habits_support import ROOT, HabitsCase, make_plugin, tree

ASK = ["Bash(rm -rf *)", "Bash(git push --force*)", "Read(./.env)"]


class Base(HabitsCase):
    def setUp(self):
        super().setUp()
        self.git_init()
        (self.base / "grants").mkdir()
        self.plugin = make_plugin(self.base / "grants", {
            "alpha": {"files": {"sarah/hooks/alpha/a.sh": "#!/bin/sh\nexit 0\n"}},
            "always-ask": {"files": {}, "ask": ASK},
        })

    def habits_md(self):
        return (self.project / "sarah" / "habits.md").read_text()

    def local_settings(self):
        p = self.project / ".claude" / "settings.local.json"
        return json.loads(p.read_text()) if p.exists() else None

    def grant(self, *argv):
        return self.run_cli("grant", *argv)


class AlwaysAsk(Base):
    def test_apply_adds_the_ask_rules_to_project_settings(self):
        code, out = self.run_cli("apply", "always-ask")
        self.assertEqual(code, 0, out)
        self.assertEqual(self.settings()["permissions"]["ask"], ASK)
        self.assertNotIn("allow", self.settings().get("permissions", {}))
        self.assertIn("- always-ask", self.habits_md())

    def test_user_settings_survive_and_the_users_own_rule_stays_theirs(self):
        self.write(".claude/settings.json", json.dumps({
            "model": "opus", "permissions": {"allow": ["Bash(ls)"], "ask": ["Bash(rm -rf *)"], "deny": ["Read(x)"]}}))
        self.run_cli("apply", "always-ask")
        s = self.settings()
        self.assertEqual(s["model"], "opus")
        self.assertEqual(s["permissions"]["allow"], ["Bash(ls)"])
        self.assertEqual(s["permissions"]["deny"], ["Read(x)"])
        self.assertEqual(s["permissions"]["ask"], ["Bash(rm -rf *)", "Bash(git push --force*)", "Read(./.env)"])
        self.run_cli("remove", "always-ask")
        self.assertEqual(self.settings()["permissions"]["ask"], ["Bash(rm -rf *)"], "the user's own rule is kept")
        self.assertEqual(self.settings()["permissions"]["allow"], ["Bash(ls)"])

    def test_applied_twice_is_byte_identical(self):
        self.run_cli("apply", "always-ask")
        first = tree(self.project)
        code, _ = self.run_cli("apply", "always-ask")
        self.assertEqual(code, 0)
        self.assertEqual(tree(self.project), first)

    def test_remove_drops_exactly_what_was_added_and_cleans_up(self):
        self.run_cli("apply", "always-ask")
        code, out = self.run_cli("remove", "always-ask")
        self.assertEqual(code, 0, out)
        self.assertEqual(self.settings_text(), "", "an emptied settings file is deleted")
        self.assertNotIn("always-ask", self.habits_md().split("## Settings")[1].split("## Autonomy")[0])
        code, status = self.run_cli("status")
        self.assertEqual(code, 0, status)

    def test_plan_lists_the_rules_and_writes_nothing(self):
        before = tree(self.project)
        code, out = self.run_cli("plan", "always-ask")
        self.assertEqual(code, 0, out)
        for rule in ASK:
            self.assertIn(rule, out)
        self.assertEqual(tree(self.project), before)

    def test_status_notices_a_missing_rule(self):
        self.run_cli("apply", "always-ask")
        s = self.settings()
        s["permissions"]["ask"].remove("Read(./.env)")
        (self.project / ".claude" / "settings.json").write_text(json.dumps(s))
        code, out = self.run_cli("status")
        self.assertEqual(code, 1)
        self.assertIn("Read(./.env)", out)

    def test_invalid_settings_are_never_clobbered(self):
        self.write(".claude/settings.json", "{not json")
        code, out = self.run_cli("apply", "always-ask")
        self.assertEqual(code, 1)
        self.assertEqual((self.project / ".claude" / "settings.json").read_text(), "{not json")

    def test_a_permissions_value_of_the_wrong_shape_is_refused_untouched(self):
        for bad in ('{"permissions": []}', '{"permissions": {"ask": "x"}}'):
            self.write(".claude/settings.json", bad)
            code, out = self.run_cli("apply", "always-ask")
            self.assertEqual(code, 1, bad)
            self.assertEqual((self.project / ".claude" / "settings.json").read_text(), bad)

    def test_the_shipped_list_installs_without_touching_allow(self):
        code, out = self.run_cli("apply", "always-ask", plugin=ROOT)
        self.assertEqual(code, 0, out)
        perms = self.settings()["permissions"]
        self.assertEqual(list(perms), ["ask"])
        self.assertGreaterEqual(len(perms["ask"]), 20)
        self.assertEqual(len(perms["ask"]), len(set(perms["ask"])))


class DeclinedAll(Base):
    def test_none_records_an_empty_chosen_section(self):
        code, out = self.run_cli("apply", "--none")
        self.assertEqual(code, 0, out)
        text = self.habits_md()
        self.assertRegex(text, r"## Chosen\n\n+## ")
        for section in ["Settings", "Autonomy", "Manifest", "Exceptions"]:
            self.assertIn(f"## {section}", text)
        self.assertEqual(tree(self.project).keys() - {"sarah", "sarah/habits.md"} - {".git"}, set())

    def test_none_installs_nothing_else(self):
        self.run_cli("apply", "--none")
        self.assertFalse((self.project / ".claude").exists())
        self.assertFalse((self.project / ".gitignore").exists())
        self.assertFalse((self.project / "sarah" / "hooks").exists())

    def test_none_twice_is_byte_identical(self):
        self.run_cli("apply", "--none")
        first = tree(self.project)
        self.assertEqual(self.run_cli("apply", "--none")[0], 0)
        self.assertEqual(tree(self.project), first)

    def test_none_never_unchooses_what_is_installed(self):
        self.run_cli("apply", "alpha")
        before = tree(self.project)
        code, out = self.run_cli("apply", "--none")
        self.assertEqual(code, 0, out)
        self.assertEqual(tree(self.project), before)
        self.assertIn("alpha", self.run_cli("status")[1])

    def test_none_with_habit_names_is_refused(self):
        code, out = self.run_cli("apply", "--none", "alpha")
        self.assertEqual(code, 1)
        self.assertIn("--none", out)
        self.assertFalse((self.project / "sarah").exists())

    def test_plan_none_writes_nothing_and_says_what_it_would_do(self):
        code, out = self.run_cli("plan", "--none")
        self.assertEqual(code, 0, out)
        self.assertIn("habits.md", out)
        self.assertFalse((self.project / "sarah").exists())

    def test_plain_apply_with_nothing_still_writes_nothing(self):
        before = tree(self.project)
        self.run_cli("apply")
        self.assertEqual(tree(self.project), before)

    def test_status_after_none_reports_none_chosen_and_is_clean(self):
        self.run_cli("apply", "--none")
        code, out = self.run_cli("status")
        self.assertEqual(code, 0, out)
        self.assertIn("chosen: none", out)

    def test_a_habit_can_be_added_after_declining(self):
        self.run_cli("apply", "--none")
        self.assertEqual(self.run_cli("apply", "alpha")[0], 0)
        self.assertIn("- alpha", self.habits_md())


class GrantRows(Base):
    def test_add_records_action_scope_date_and_the_quote(self):
        code, out = self.grant("add", "push-feature", "--scope", "feature/*", "--quote", "yes, save my work online")
        self.assertEqual(code, 0, out)
        auto = self.habits_md().split("## Autonomy")[1].split("## Manifest")[0]
        today = date.today().isoformat()
        self.assertIn("| push-feature | feature/* | " + today + " | yes, save my work online |", auto)

    def test_add_without_a_quote_is_refused_and_writes_nothing(self):
        for argv in (["add", "push-feature", "--scope", "feature/*"],
                     ["add", "push-feature", "--scope", "feature/*", "--quote", "  "]):
            before = tree(self.project)
            code, out = self.grant(*argv)
            self.assertNotEqual(code, 0, argv)
            self.assertEqual(tree(self.project), before)

    def test_add_never_writes_an_allow_rule(self):
        self.grant("add", "push-feature", "--scope", "feature/*", "--quote", "go")
        self.assertIsNone(self.local_settings())
        self.assertFalse((self.project / ".claude" / "settings.json").exists())

    def test_an_always_asked_action_cannot_be_granted(self):
        for action in ["force-push", "delete branches", "spend money", "touch credentials"]:
            before = tree(self.project)
            code, out = self.grant("add", action, "--scope", "x", "--quote", "please")
            self.assertEqual(code, 1, action)
            self.assertIn("always asked", out)
            self.assertEqual(tree(self.project), before)

    def test_a_pipe_or_newline_in_the_quote_cannot_forge_a_row(self):
        self.grant("add", "push-feature", "--scope", "feature/*", "--quote", "ok | main | 2026-01-01 | x\n| ssh | * |")
        rows = [l for l in self.habits_md().splitlines() if l.startswith("| ") and "push-feature" in l or l.startswith("| ssh")]
        self.assertEqual(len(rows), 1, rows)
        self.assertEqual(self.grant("list")[1].count("ssh"), 0)

    def test_adding_the_same_grant_twice_keeps_one_row(self):
        self.grant("add", "push-feature", "--scope", "feature/*", "--quote", "go")
        first = tree(self.project)
        code, out = self.grant("add", "push-feature", "--scope", "feature/*", "--quote", "go again")
        self.assertEqual(code, 0, out)
        self.assertEqual(tree(self.project), first)

    def test_user_text_in_the_autonomy_section_is_kept(self):
        self.run_cli("apply", "--none")
        p = self.project / "sarah" / "habits.md"
        p.write_text(p.read_text().replace("## Autonomy\n", "## Autonomy\n\nMy note about the lab machine.\n", 1))
        self.grant("add", "ssh", "--scope", "lab-box", "--quote", "use lab-box")
        text = self.habits_md()
        self.assertIn("My note about the lab machine.", text)
        self.assertIn("| ssh | lab-box |", text)

    def test_list_prints_the_rows(self):
        self.grant("add", "ssh", "--scope", "lab-box", "--quote", "use lab-box")
        code, out = self.grant("list")
        self.assertEqual(code, 0)
        self.assertIn("ssh", out)
        self.assertIn("lab-box", out)

    def test_list_with_none_says_so(self):
        code, out = self.grant("list")
        self.assertEqual(code, 0)
        self.assertIn("none", out)

    def test_revoke_deletes_the_row_and_nothing_else(self):
        self.grant("add", "push-feature", "--scope", "feature/*", "--quote", "go")
        self.grant("add", "ssh", "--scope", "lab-box", "--quote", "use lab-box")
        code, out = self.grant("revoke", "ssh", "--scope", "lab-box")
        self.assertEqual(code, 0, out)
        text = self.habits_md()
        self.assertNotIn("lab-box", text)
        self.assertIn("push-feature", text)

    def test_revoking_an_unknown_grant_says_so(self):
        code, out = self.grant("revoke", "ssh", "--scope", "nowhere")
        self.assertEqual(code, 1)
        self.assertIn("no such grant", out)

    def test_a_malformed_grant_row_is_ignored_with_one_line(self):
        self.grant("add", "push-feature", "--scope", "feature/*", "--quote", "go")
        p = self.project / "sarah" / "habits.md"
        p.write_text(p.read_text().replace("## Manifest", "| broken row |\n\n## Manifest", 1))
        code, out = self.grant("list")
        self.assertEqual(code, 0, out)
        self.assertEqual(len([l for l in out.splitlines() if "malformed" in l]), 1, out)


class AllowRules(Base):
    def setUp(self):
        super().setUp()
        self.grant("add", "push-feature", "--scope", "feature/*", "--quote", "go")

    def test_without_write_it_shows_a_diff_and_touches_nothing(self):
        before = tree(self.project)
        code, out = self.grant("allow")
        self.assertEqual(code, 0, out)
        self.assertIn("settings.local.json", out)
        self.assertRegex(out, r"(?m)^\+ allow Bash\(git push")
        self.assertEqual(tree(self.project), before)

    def test_write_adds_the_rules_to_the_personal_file_only(self):
        code, out = self.grant("allow", "--write")
        self.assertEqual(code, 0, out)
        local = self.local_settings()
        self.assertTrue(local["permissions"]["allow"])
        self.assertFalse((self.project / ".claude" / "settings.json").exists(), "the shared file is never given allow rules")
        for rule in local["permissions"]["allow"]:
            self.assertIn(rule, self.habits_md(), "recorded so revoke can take it back")

    def test_write_twice_is_byte_identical(self):
        self.grant("allow", "--write")
        first = tree(self.project)
        self.assertEqual(self.grant("allow", "--write")[0], 0)
        self.assertEqual(tree(self.project), first)

    def test_existing_personal_settings_are_kept(self):
        self.write(".claude/settings.local.json", json.dumps({"permissions": {"allow": ["Bash(ls)"]}, "env": {"A": "1"}}))
        self.grant("allow", "--write")
        local = self.local_settings()
        self.assertEqual(local["env"], {"A": "1"})
        self.assertEqual(local["permissions"]["allow"][0], "Bash(ls)")
        self.assertGreater(len(local["permissions"]["allow"]), 1)

    def test_revoke_removes_only_the_rules_the_framework_wrote(self):
        self.write(".claude/settings.local.json", json.dumps({"permissions": {"allow": ["Bash(ls)"]}}))
        self.grant("allow", "--write")
        code, out = self.grant("revoke", "push-feature", "--scope", "feature/*")
        self.assertEqual(code, 0, out)
        self.assertEqual(self.local_settings(), {"permissions": {"allow": ["Bash(ls)"]}})
        self.assertNotIn("git push", self.habits_md())

    def test_revoke_deletes_a_personal_file_it_emptied(self):
        self.grant("allow", "--write")
        self.grant("revoke", "push-feature", "--scope", "feature/*")
        self.assertFalse((self.project / ".claude" / "settings.local.json").exists())

    def test_a_rule_the_user_already_had_is_not_taken_over(self):
        rule = self.engine.allow_rules("push-feature", "feature/*")[0]
        self.write(".claude/settings.local.json", json.dumps({"permissions": {"allow": [rule]}}))
        self.grant("allow", "--write")
        self.grant("revoke", "push-feature", "--scope", "feature/*")
        self.assertIn(rule, self.local_settings()["permissions"]["allow"])

    def test_invalid_personal_settings_are_never_clobbered(self):
        self.write(".claude/settings.local.json", "{oops")
        code, out = self.grant("allow", "--write")
        self.assertEqual(code, 1)
        self.assertEqual((self.project / ".claude" / "settings.local.json").read_text(), "{oops")

    def test_a_grant_with_no_pattern_offers_nothing(self):
        self.grant("revoke", "push-feature", "--scope", "feature/*")
        self.grant("add", "run device tests", "--scope", "usb phone", "--quote", "go")
        code, out = self.grant("allow")
        self.assertEqual(code, 0, out)
        self.assertNotRegex(out, r"(?m)^\+ allow")
        self.assertIn("no pattern", out)

    def test_an_always_asked_rule_is_never_among_the_allow_rules(self):
        self.run_cli("apply", "always-ask")
        asks = set(self.settings()["permissions"]["ask"])
        self.grant("allow", "--write")
        self.assertFalse(asks & set(self.local_settings()["permissions"]["allow"]))

    def test_revoking_after_removing_the_grants_section_row_by_hand_is_safe(self):
        self.grant("allow", "--write")
        p = self.project / "sarah" / "habits.md"
        p.write_text(re.sub(r"(?m)^\| push-feature .*\n", "", p.read_text()))
        code, out = self.grant("allow")
        self.assertEqual(code, 0, out)
