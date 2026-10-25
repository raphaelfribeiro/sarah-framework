"""Unit tests for the autonomy grants and the always-ask list in scripts/habits.py.

D9 and ADR-010: a grant is a named row, an always-asked action can never be
granted, and the framework derives allow rules but never writes one on its own.
Every test here ran red against the engine before the grants existed.
"""

from tests.habits_support import HabitsCase


class Grants(HabitsCase):
    def test_push_feature_maps_to_allow_rules_for_feature_branches_only(self):
        rules = self.engine.allow_rules("push-feature", "feature/*")
        self.assertTrue(rules)
        for rule in rules:
            self.assertTrue(rule.startswith("Bash(git push"), rule)
            self.assertIn("feature/", rule)
            self.assertNotIn("main", rule)

    def test_ssh_grant_maps_to_the_one_named_host(self):
        self.assertEqual(self.engine.allow_rules("ssh", "build-box"), ["Bash(ssh build-box *)"])

    def test_ssh_scope_takes_no_wildcard_and_no_pattern_characters(self):
        for bad in ["*", "host *", "a;b", "a)b", "", "-oProxyCommand=x", "a b", "h\n"]:
            with self.assertRaises(self.engine.Refused, msg=repr(bad)):
                self.engine.allow_rules("ssh", bad)

    def test_an_action_with_no_known_pattern_yields_no_allow_rule(self):
        self.assertEqual(self.engine.allow_rules("run device tests", "usb phone"), [])

    def test_push_feature_scope_is_fixed(self):
        with self.assertRaises(self.engine.Refused):
            self.engine.allow_rules("push-feature", "*")
        with self.assertRaises(self.engine.Refused):
            self.engine.allow_rules("push-feature", "main")

    def test_always_asked_actions_are_recognised_in_plain_words(self):
        for text in ["force-push", "delete branches", "rm -rf the build", "rewrite history", "spend money",
                     "touch passwords", "read the API key", "use credentials", "Deleting for good"]:
            self.assertTrue(self.engine.always_asked(text), text)

    def test_ordinary_actions_are_not_always_asked(self):
        for text in ["push-feature", "ssh", "run device tests", "save work online"]:
            self.assertFalse(self.engine.always_asked(text), text)

    def test_action_text_cannot_break_the_table(self):
        for bad in ["a|b", "a\nb", "", " ", "x" * 200]:
            with self.assertRaises(self.engine.Refused, msg=repr(bad)):
                self.engine.check_grant_text("action", bad)


class AskRules(HabitsCase):
    def test_a_payload_may_declare_ask_rules_and_nothing_looser(self):
        for key in ("allow", "deny", "defaultMode"):
            plugin = self.base / key
            plugin.mkdir()
            from tests.habits_support import make_plugin
            p = make_plugin(plugin, {"x": {"files": {}, "ask": ["Bash(rm -rf *)"]}})
            meta = p / "skills" / "sarah-init" / "habits" / "x" / "habit.json"
            import json
            data = json.loads(meta.read_text())
            data[key] = ["Bash(ls)"]
            meta.write_text(json.dumps(data))
            with self.assertRaises(self.engine.Refused, msg=key):
                self.engine.load_payload(p, "x")

    def test_an_ask_rule_must_be_a_single_plain_rule(self):
        from tests.habits_support import make_plugin
        for bad in ["", "rm -rf", "Bash(", "Bash(a)\nBash(b)", 5, "Bash()"]:
            plugin = self.base / f"p{abs(hash(repr(bad)))}"
            plugin.mkdir()
            p = make_plugin(plugin, {"x": {"files": {}, "ask": [bad]}})
            with self.assertRaises(self.engine.Refused, msg=repr(bad)):
                self.engine.load_payload(p, "x")

    def test_the_shipped_always_ask_list_covers_destructive_money_and_credentials(self):
        from tests.habits_support import ROOT
        payload = self.engine.load_payload(ROOT, "always-ask")
        rules = "\n".join(payload.ask)
        for needle in ["rm -rf", "git push --force", "git push --delete", "git branch -D", "git reset --hard",
                       "terraform apply", ".env", ".ssh", "get-secret-value"]:
            self.assertIn(needle, rules, needle)
        self.assertEqual(payload.files, {})
        self.assertEqual(payload.settings, [])
