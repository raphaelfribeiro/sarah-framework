"""Static checks for the init interview: S4, S5, S8 and the catalog contract.

The catalog is prose a model reads at run time, so what can be checked is its
shape: every habit carries its failure, panels respect the platform's limits,
the plain-language rule holds in every label, and `sarah-init` stays inside its
40-line allowance. Technical names appear only in the details table.
"""

import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INIT = ROOT / "skills" / "sarah-init"
CATALOG = INIT / "references" / "habits-catalog.md"
SKILL = INIT / "SKILL.md"
V010_LINES = 164          # lines of sarah-init/SKILL.md at v0.1.0
ALLOWANCE = 40

# The seven items the plan names, by plain label, with the payload each uses.
ENTRIES = {
    "Keep demands on a Trello board": "tracker",
    "Pick the AI model for each task": "dispatch-guard",
    "Protect the main line": "gitflow",
    "A release-note line per delivery": "changelog-fragment",
    "Check the task still makes sense": "dispatch-guard",
    "Each task gets its own copy": "dispatch-guard",
    "Keep working while work is waiting": "no-idle",
}
BANNED = ["worktree", "wip", "gitflow", "ci", "pull request", "manifest", "executor", "hook", "premise",
          "agreement", "dispatch", "payload", "stamp", "sha256", "settings.json", "python3"]


def text(path):
    return path.read_text(encoding="utf-8")


def entries():
    """{label: {key: value}} from the `### label` blocks and their `- Key: value` lines."""
    out = {}
    for block in re.split(r"(?m)^### ", text(CATALOG))[1:]:
        label, _, body = block.partition("\n")
        out[label.strip()] = dict(re.findall(r"(?m)^- ([A-Za-z ]+): (.+)$", body))
    return out


def panels():
    return [json.loads(b) for b in re.findall(r"(?s)```json\n(.*?)\n```", text(CATALOG))]


def options():
    for panel in panels():
        for q in panel["questions"]:
            for o in q["options"]:
                yield q, o


class Budget(unittest.TestCase):
    def test_s8_init_grows_by_at_most_40_lines(self):
        lines = len(text(SKILL).splitlines())
        self.assertLessEqual(lines, V010_LINES + ALLOWANCE, f"{lines} lines")

    def test_init_still_loads_under_the_500_line_ceiling(self):
        self.assertLess(len(text(SKILL).splitlines()), 500)

    def test_init_links_the_catalog_and_it_resolves(self):
        self.assertIn("references/habits-catalog.md", text(SKILL))
        self.assertTrue(CATALOG.is_file() and not CATALOG.is_symlink())


class Catalog(unittest.TestCase):
    def test_every_planned_habit_is_listed_with_its_failure(self):
        found = entries()
        for label in ENTRIES:
            self.assertIn(label, found)
            self.assertGreater(len(found[label].get("Failure", "")), 20, label)

    def test_each_entry_names_a_status_a_habit_and_its_prerequisites(self):
        for label, e in entries().items():
            if label not in ENTRIES:
                continue
            self.assertIn(e.get("Status", "").split(" ")[0], ("available", "pending"), label)
            self.assertEqual(e.get("Habit"), ENTRIES[label], label)
            self.assertIn("Needs", e, label)

    def test_status_matches_what_is_on_disk(self):
        for label, e in entries().items():
            if label not in ENTRIES:
                continue
            if e["Habit"] == "tracker":
                exists = (ROOT / "scripts" / "tracker.py").is_file()
            else:
                exists = (INIT / "habits" / e["Habit"] / "habit.json").is_file()
            if e["Status"].split(" ")[0] == "available":
                self.assertTrue(exists, f"{label}: marked available but {e['Habit']} does not exist")
            else:
                self.assertFalse(exists, f"{label}: it exists now, flip its Status to available")

    def test_the_tracker_entry_carries_the_authors_text_and_the_habits_lines(self):
        body = text(CATALOG)
        for needle in ("TRELLO_API_KEY", "TRELLO_TOKEN", "It never blocks", "daily board check", "- tracker: trello",
                       "- board: <id or link>", 'tracker.py" check', "public board is refused",
                       "Never ask the user to paste a token into the chat"):
            self.assertIn(needle, body, needle)
        # Its Status is checked against the disk by test_status_matches_what_is_on_disk.

    def test_pending_entries_are_not_offered(self):
        self.assertRegex(text(CATALOG), r"(?i)pending[^\n]*(omit|not offered|never offered)")

    def test_fixture_and_always_ask_are_never_choices(self):
        found = entries()
        for hidden in ("_fixture", "always-ask"):
            self.assertFalse([l for l, e in found.items() if e.get("Habit") == hidden], hidden)
            for _, o in options():
                self.assertNotIn(hidden, o["label"] + o["description"])
        self.assertIn("_fixture", text(CATALOG))
        self.assertIn("always-ask", text(CATALOG))

    def test_details_table_maps_every_label_to_a_technical_name(self):
        body = text(CATALOG).split("## Details", 1)[1]
        rows = dict(re.findall(r"(?m)^\| ([^|]+?) \| ([^|]+?) \|$", body))
        for label in ENTRIES:
            self.assertIn(label, rows)
            self.assertNotEqual(rows[label], "")
        self.assertIn("tracker (R9, R12)", rows["Keep demands on a Trello board"])
        self.assertIn("R13", rows["Protect the main line"])

    def test_the_recommended_grant_is_pushing_feature_branches_only(self):
        body = text(CATALOG)
        self.assertIn("feature/*", body)
        allowed = next(q for p in panels() for q in p["questions"] if q["header"] == "Allowed")
        first = allowed["options"][0]
        self.assertEqual(first["label"], "Save my work online (Recommended)")
        for word in ("merge", "force-push", "delet"):
            self.assertIn(word, body.lower())
        self.assertNotIn("merge", first["description"].lower())

    def test_the_default_limit_is_three(self):
        self.assertIn("Up to 3 tasks at once", text(CATALOG))
        self.assertIn("3", text(SKILL))

    def test_always_ask_list_is_stated_as_fixed(self):
        body = text(CATALOG)
        for item in ("deleting for good", "rewriting history", "spending money", "touching passwords or keys"):
            self.assertIn(item, body)
        self.assertRegex(body, r"(?i)cannot be granted")

    def test_allow_rules_are_only_ever_shown_before_written(self):
        body = text(CATALOG)
        self.assertIn("grant allow", body)
        self.assertRegex(body, r"(?s)grant allow.*--write")
        self.assertRegex(body, r"(?i)never[^.\n]*allow")

    def test_declined_all_is_recorded(self):
        for doc in (text(CATALOG), text(SKILL)):
            self.assertIn("apply --none", doc)


class Panels(unittest.TestCase):
    def test_s4_limits(self):
        self.assertGreaterEqual(len(panels()), 4)
        for panel in panels():
            self.assertLessEqual(len(panel["questions"]), 4)
            for q in panel["questions"]:
                self.assertLessEqual(len(q["question"]), 120, q["question"])
                self.assertLessEqual(len(q["header"]), 12, q["header"])
                self.assertLessEqual(len(q["options"]), 4, q["question"])
                self.assertGreaterEqual(len(q["options"]), 2, q["question"])
                for i, o in enumerate(q["options"]):
                    self.assertLessEqual(len(o["label"]), 40, o["label"])
                    self.assertLessEqual(len(o["description"]), 200, o["label"])
                    if "(Recommended)" in o["label"]:
                        self.assertEqual(i, 0, f"recommendation must be first: {o['label']}")
                if q["multiSelect"]:
                    self.assertEqual(q["options"][-1]["label"], "None of these", q["question"])
                else:
                    self.assertNotIn("None of these", [o["label"] for o in q["options"]])

    def test_s5_no_jargon_in_labels_or_descriptions(self):
        for q, o in options():
            for field in (q["question"], o["label"], o["description"]):
                low = field.lower()
                for word in BANNED:
                    self.assertIsNone(re.search(rf"(?<![\w/.-]){re.escape(word)}(?![\w/.-])", low), f"{word!r} in {field!r}")
                self.assertIsNone(re.search(r"\bR\d{1,2}\b", field), field)

    def test_every_catalog_label_appears_as_an_option_once(self):
        labels = [re.sub(r" \(Recommended\)$", "", o["label"]) for _, o in options()]
        for label in ENTRIES:
            self.assertEqual(labels.count(label), 1, label)

    def test_no_answer_is_never_a_yes(self):
        self.assertRegex(text(CATALOG), r"(?i)no answer is never a yes")


if __name__ == "__main__":
    unittest.main()
