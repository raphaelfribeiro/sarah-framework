"""Static checks S1 and S7 for the conversation defaults (R1-R7, R4).

S1: the defaults text the session-start hook prints stays within 200 tokens,
by the chars/4 estimate CI also uses for the bootstrap. (The denser estimate in
scripts/token_budget.py reads plain prose about 15% higher; it is a gauge for
ARCHI.md, not the budget here.)

S7: a user-facing fixture opens with whether a decision is needed, runs to at
most 10 lines, and keeps each line to 110 characters. Fixtures live in
tests/fixtures/ux/*.txt; any file added there is linted.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULTS = ROOT / "hooks" / "conversation-defaults.txt"
FIXTURES = ROOT / "tests" / "fixtures" / "ux"
BUDGET = 200
TOGGLES = {"questions", "keep-going", "run-it", "plain", "verified", "remembered", "unattended"}
FIRST_LINE = re.compile(r"^(Decision needed: .+|No decision needed\b.*)$")


class DefaultsBudget(unittest.TestCase):
    def setUp(self):
        self.assertTrue(DEFAULTS.is_file(), "hooks/conversation-defaults.txt does not exist")
        self.text = DEFAULTS.read_text(encoding="utf-8")

    def test_s1_within_200_tokens(self):
        approx = len(self.text) / 4
        self.assertLessEqual(approx, BUDGET, f"~{approx:.0f} tokens (chars/4)")

    def test_every_rule_carries_one_known_toggle_name(self):
        tags = re.findall(r"^@([a-z][a-z-]*) ", self.text, re.M)
        self.assertEqual(set(tags), TOGGLES)
        self.assertEqual(len(tags), len(set(tags)), "a toggle name is used twice")

    def test_no_line_other_than_a_rule_starts_with_a_tag_character(self):
        for line in self.text.splitlines():
            if line.startswith("@"):
                self.assertRegex(line, r"^@[a-z][a-z-]* \S")


class FixtureShape(unittest.TestCase):
    def test_s7_there_are_fixtures_to_lint(self):
        self.assertTrue(list(FIXTURES.glob("*.txt")), "no fixtures in tests/fixtures/ux/")

    def test_s7_first_line_states_whether_a_decision_is_needed(self):
        for f in sorted(FIXTURES.glob("*.txt")):
            first = f.read_text(encoding="utf-8").splitlines()[0]
            self.assertRegex(first, FIRST_LINE, f.name)

    def test_s7_at_most_ten_lines_of_110_characters(self):
        for f in sorted(FIXTURES.glob("*.txt")):
            lines = f.read_text(encoding="utf-8").splitlines()
            self.assertLessEqual(len(lines), 10, f"{f.name}: {len(lines)} lines")
            for n, line in enumerate(lines, 1):
                self.assertLessEqual(len(line), 110, f"{f.name}:{n} is {len(line)} characters")


if __name__ == "__main__":
    unittest.main()
