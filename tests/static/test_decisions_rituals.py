"""Static checks for R6 (durable decisions) and R21 (short rituals): S7, S8.

The rituals are prose a model reads, so the checks are line ceilings and the
presence of the elements the UX contract names. Readers of sarah/decisions.md
must tolerate the file being absent.
"""

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "skills"
ILL = (SKILLS / "ill-be-back" / "SKILL.md").read_text(encoding="utf-8")
HASTA = (SKILLS / "hasta-la-vista" / "SKILL.md").read_text(encoding="utf-8")
IMPLEMENT = (SKILLS / "sarah-phase-implement" / "SKILL.md").read_text(encoding="utf-8")
TEMPLATE = (SKILLS / "sarah-init" / "references" / "state-template.md").read_text(encoding="utf-8")
BOOTSTRAP = SKILLS / "sarah-bootstrap" / "SKILL.md"

ABSENCE = ("absent", "does not exist", "missing file")


def lines(text):
    return len(text.rstrip("\n").split("\n"))


def tolerates_absence(text):
    low = text.lower()
    return any(w in low for w in ABSENCE)


class RitualCeilings(unittest.TestCase):
    def test_ill_be_back_at_most_30_lines(self):
        self.assertLessEqual(lines(ILL), 30)

    def test_hasta_la_vista_at_most_35_lines(self):
        self.assertLessEqual(lines(HASTA), 35)

    def test_descriptions_keep_triggers(self):
        for phrase in ("/ill-be-back", "good morning", "what were we doing", "catch me up", "where did we leave off"):
            self.assertIn(phrase, ILL.split("---")[1])
        for phrase in ("/hasta-la-vista", "that's it for today", "I'm done", "wrapping up", "good night"):
            self.assertIn(phrase, HASTA.split("---")[1])


class IllBeBackShape(unittest.TestCase):
    def test_first_line_verdict_and_limits(self):
        for needle in ("Decision needed", "No decision needed", "10 lines", "table"):
            self.assertIn(needle, ILL)

    def test_lines_in_order(self):
        positions = [ILL.find(k) for k in ("Last session:", "Waiting on you:", "In flight:", "Heads-up:")]
        self.assertNotIn(-1, positions)
        self.assertEqual(positions, sorted(positions))

    def test_no_headings_in_output_and_no_writes(self):
        self.assertIn("No headings", ILL)
        self.assertIn("Writes nothing", ILL)

    def test_choosing_is_the_go_signal(self):
        self.assertIn("go signal", ILL)

    def test_compaction_offer_once_a_day(self):
        self.assertIn("/sarah-compact", ILL)
        self.assertIn("once a day", ILL)
        self.assertIn("compact-snoozed", ILL)

    def test_reads_decisions_tolerating_absence(self):
        self.assertIn("sarah/decisions.md", ILL)
        self.assertTrue(tolerates_absence(ILL))


class HastaShape(unittest.TestCase):
    def test_first_line_verdict_and_limits(self):
        for needle in ("Decision needed", "No decision needed", "10 lines", "No headings"):
            self.assertIn(needle, HASTA)

    def test_lines_in_order(self):
        positions = [HASTA.find(k) for k in ("Shipped:", "Open:", "Decided today:", "Docs:")]
        self.assertNotIn(-1, positions)
        self.assertEqual(positions, sorted(positions))

    def test_keeps_state_changelog_and_gate(self):
        for needle in ("sarah/state.md", "sarah/state/", "sarah/changelog/", "documentation gate", "ARCHI.md", "README.md", "Missing:"):
            self.assertIn(needle, HASTA)

    def test_commit_question(self):
        self.assertIn("Commit (Recommended)", HASTA)
        self.assertIn("Hasta la vista.", HASTA)

    def test_no_still_running_line(self):
        self.assertNotIn("Still running", HASTA)
        self.assertNotIn("still running", HASTA.lower())

    def test_gate_moves_binding_decisions(self):
        self.assertIn("sarah/decisions.md", HASTA)
        self.assertIn("Permanent", HASTA)
        self.assertTrue(tolerates_absence(HASTA))


class DecisionsFile(unittest.TestCase):
    def test_template_defines_format(self):
        for needle in ("sarah/decisions.md", "one line", "newest first", "YYYY-MM-DD", "Permanent"):
            self.assertIn(needle, TEMPLATE)

    def test_permanent_stored_distinctly(self):
        self.assertIn("## Permanent", TEMPLATE)

    def test_template_says_created_on_first_decision(self):
        self.assertIn("first decision", TEMPLATE)

    def test_implement_reads_at_task_start_and_quotes_conflict(self):
        self.assertIn("sarah/decisions.md", IMPLEMENT)
        self.assertTrue(tolerates_absence(IMPLEMENT))
        self.assertIn("one question", IMPLEMENT)
        self.assertIn("quote", IMPLEMENT)
        self.assertIn("Permanent", IMPLEMENT)

    def test_bootstrap_unchanged_in_size(self):
        # step 8 must not grow the bootstrap: the hook already points at the file
        self.assertLessEqual(lines(BOOTSTRAP.read_text(encoding="utf-8")), 108)  # its size when this step began


if __name__ == "__main__":
    unittest.main()
