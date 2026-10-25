"""Gate 4: the shipped always-ask list closes the self-grant and the widened push.

The list is textual patterns on a platform that treats `*` as any text, spaces
and colons included. These tests pin the rules the review found missing; the
honest limits (a shell write, a second refspec in a form no pattern names) are
in ADR-010.
"""

import json
import re

from tests.habits_support import ROOT, HabitsCase

PAYLOAD = ROOT / "skills" / "sarah-init" / "habits" / "always-ask" / "habit.json"

SELF_GRANT = [
    "Edit(/sarah/habits.md)", "Write(/sarah/habits.md)",
    "Edit(/sarah/exceptions.log)", "Write(/sarah/exceptions.log)",
    "Edit(/sarah/hooks/**)", "Write(/sarah/hooks/**)",
    "Bash(*habits.py grant allow --write*)", "Bash(*habits.py grant add*)",
]
PUSH = [
    "Bash(git push *:*)", "Bash(git push * -d*)", "Bash(git push -d*)",
    "Bash(git push * --mirror*)", "Bash(git push --mirror*)",
    "Bash(git push --all*)", "Bash(git push * --all*)",
    "Bash(git push origin feature/* *)", "Bash(git push -u origin feature/* *)",
    "Bash(git push --set-upstream origin feature/* *)",
]
DESTRUCTIVE = [
    "Bash(rm -r*)", "Bash(rm -R*)", "Bash(rm -fr*)", "Bash(rm -fR*)", "Bash(rm -f -r*)", "Bash(rm -f -R*)",
    "Bash(git clean -*f*)", "Bash(git clean * -*f*)", "Bash(git clean --force*)",
    "Bash(git checkout .)", "Bash(git restore .)", "Bash(git stash clear)",
]
SECRETS = [
    "Read(/.env)", "Read(/.env.*)", "Read(**/.env)", "Read(**/.env.*)",
    "Edit(/.env)", "Edit(**/.env)", "Write(/.env)", "Write(**/.env)",
    "Read(~/.netrc)", "Read(~/.git-credentials)", "Read(~/.kube/**)", "Read(~/.gnupg/**)",
]
KEPT = [
    "Bash(rm -rf *)", "Bash(rm -fr *)", "Bash(rm -r *)", "Bash(git push * :*)", "Bash(git rebase *)",
    "Bash(git commit --amend*)", "Bash(git branch -d *)", "Bash(printenv*)", "Read(./.env)", "Read(./.env.*)",
]


class AlwaysAskList(HabitsCase):
    def setUp(self):
        super().setUp()
        self.rules = json.loads(PAYLOAD.read_text())["ask"]

    def test_the_review_findings_are_covered(self):
        for rule in SELF_GRANT + PUSH + DESTRUCTIVE + SECRETS:
            self.assertIn(rule, self.rules, rule)

    def test_no_existing_rule_was_dropped(self):
        for rule in KEPT:
            self.assertIn(rule, self.rules, rule)

    def test_every_rule_passes_the_engine_and_none_repeats(self):
        payload = self.engine.load_payload(ROOT, "always-ask")
        self.assertEqual(len(self.rules), len(set(self.rules)))
        self.assertEqual(list(payload.ask), self.rules)
        for rule in self.rules:
            self.assertTrue(self.engine.ASK_RULE.fullmatch(rule), rule)

    def test_no_rule_is_an_allow_in_disguise(self):
        for rule in self.rules:
            self.assertRegex(rule, r"^(Bash|Read|Edit|Write)\(")

    def test_wipe_and_drop_cannot_be_granted(self):
        for text in ["wipe the database", "drop tables", "Drop"]:
            self.assertTrue(self.engine.always_asked(text), text)

    def test_the_push_grant_is_not_described_as_unwidenable(self):
        src = (ROOT / "scripts" / "habits.py").read_text()
        self.assertNotIn("cannot be widened", src)
        self.assertRegex(src, r"gitflow guard")


class MergeGrant(HabitsCase):
    def setUp(self):
        super().setUp()
        self.git_init()

    def test_merge_on_green_is_a_row_with_no_allow_rule(self):
        self.assertEqual(self.engine.allow_rules("merge-on-green", "feature/*"), [])
        code, out = self.run_cli("grant", "add", "merge-on-green", "--scope", "feature/*", "--quote", "merge when green")
        self.assertEqual(code, 0, out)
        self.assertIn("merge-on-green", (self.project / "sarah" / "habits.md").read_text())
        code, out = self.run_cli("grant", "allow")
        self.assertNotIn("+ allow", out)

    def test_merge_on_green_covers_feature_branches_only(self):
        for scope in ("main", "*", "develop"):
            with self.assertRaises(self.engine.Refused, msg=scope):
                self.engine.allow_rules("merge-on-green", scope)

    def test_the_grant_can_be_revoked(self):
        self.run_cli("grant", "add", "merge-on-green", "--scope", "feature/*", "--quote", "merge when green")
        code, out = self.run_cli("grant", "revoke", "merge-on-green")
        self.assertEqual(code, 0, out)
        self.assertNotIn("merge-on-green", (self.project / "sarah" / "habits.md").read_text())

    def test_the_docs_condition_merging_on_the_row(self):
        catalog = (ROOT / "skills/sarah-init/references/habits-catalog.md").read_text()
        self.assertIn("grant add merge-on-green --scope 'feature/*'", catalog)
        boot = (ROOT / "skills/sarah-bootstrap/SKILL.md").read_text()
        self.assertIn("merge-on-green", boot)
        adr = (ROOT / "docs/adr/010-autonomy-grants-and-unattended-merge.md").read_text()
        self.assertIn("merge-on-green", adr)
        self.assertLessEqual(len(boot) // 4, 2000)
