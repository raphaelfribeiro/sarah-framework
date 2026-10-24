"""Static checks S9, S10 and the executor part of S3 (R10, R11).

The executor is the one new agent. Its frontmatter may carry only fields a
plugin agent accepts, its model is a default the call overrides, and its report
has four named sections. The brief comes in three depths and treats card text
as untrusted data. The task template declares the executor per task.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AGENTS = ROOT / "agents"
IMPLEMENT = ROOT / "skills" / "sarah-phase-implement"
TEMPLATE = ROOT / "skills" / "sarah-bootstrap" / "references" / "task-template.md"

# hooks, mcpServers and permissionMode are ignored for plugin agents (F1).
ALLOWED = {"name", "description", "model", "effort", "tools", "disallowedTools", "maxTurns", "skills", "color"}
ROSTER = {
    "code-reviewer", "developer", "devops-engineer", "product-analyst", "product-manager",
    "release-manager", "security-advisor", "software-architect", "test-engineer", "ux-ui-designer",
}


def frontmatter(path):
    lines = path.read_text(encoding="utf-8").split("\n")
    assert lines[0] == "---", f"{path} has no frontmatter"
    end = lines.index("---", 1)
    fields = {}
    for line in lines[1:end]:
        match = re.match(r"([A-Za-z]+):\s*(.*)", line)
        if match:
            fields[match.group(1)] = match.group(2)
    return fields


class ExecutorAgent(unittest.TestCase):
    def test_exactly_one_new_agent(self):
        names = {p.stem for p in AGENTS.glob("*.md")}
        self.assertEqual(names, ROSTER | {"executor"})

    def test_frontmatter_is_limited_to_accepted_fields(self):
        fields = frontmatter(AGENTS / "executor.md")
        self.assertEqual(set(fields) - ALLOWED, set())
        self.assertEqual(fields["name"], "executor")
        self.assertTrue(fields["description"])

    def test_model_is_a_default_and_effort_is_never_fixed(self):
        fields = frontmatter(AGENTS / "executor.md")
        self.assertEqual(fields["model"], "sonnet")
        self.assertNotIn("effort", fields)

    def test_report_names_four_sections_and_the_model_it_ran_on(self):
        text = (AGENTS / "executor.md").read_text(encoding="utf-8")
        for section in ("Done", "Proof", "Not finished", "Requested tasks"):
            self.assertRegex(text, rf"(?m)^### {section}$", section)
        self.assertRegex(text, r"(?i)model and effort.{0,40}ran on|ran on.{0,40}model")


class ExecutorBrief(unittest.TestCase):
    brief = IMPLEMENT / "references" / "executor-brief.md"

    def test_three_depths(self):
        text = self.brief.read_text(encoding="utf-8")
        for depth in ("Full", "Standard", "Lean"):
            self.assertRegex(text, rf"(?m)^## {depth}\b", depth)

    def test_no_tracker_verbs_or_credentials(self):
        text = self.brief.read_text(encoding="utf-8")
        self.assertNotIn("tracker.py", text)
        self.assertNotIn("TRELLO_", text)

    def test_untrusted_block_rule_present(self):
        text = self.brief.read_text(encoding="utf-8").lower()
        self.assertIn("untrusted", text)

    def test_implement_skill_links_the_brief_and_stays_short(self):
        skill = (IMPLEMENT / "SKILL.md").read_text(encoding="utf-8")
        self.assertIn("references/executor-brief.md", skill)
        self.assertLess(len(skill.split("\n")), 500)


class TaskTemplateExecutorTable(unittest.TestCase):
    def test_executor_table_and_premises(self):
        text = TEMPLATE.read_text(encoding="utf-8")
        self.assertRegex(text, r"(?m)^## Executor$")
        self.assertRegex(text, r"(?m)^\| Executor \| Model \| Effort \| Fallback \|$")
        self.assertRegex(text, r"(?m)^## Premises$")


class OrchestratorSteps(unittest.TestCase):
    def test_dispatch_steps_are_named(self):
        text = (IMPLEMENT / "SKILL.md").read_text(encoding="utf-8").lower()
        for needle in ('isolation: "worktree"', "proof", "re-brief", "fallback"):
            self.assertIn(needle, text)


if __name__ == "__main__":
    unittest.main()
