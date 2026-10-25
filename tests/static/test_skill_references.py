"""Static checks S2 and S3: every skill can read the references it names.

An installed plugin's skill can read only files inside its own directory, so a
`references/<file>` link must resolve there, as a regular file and not a
symlink: a symlink passes `ls` in this repository and fails to read once the
plugin is installed somewhere else.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "skills"
LINK = re.compile(r"(?<![\w/.-])references/[\w.-]+\.md")


class SkillReferences(unittest.TestCase):
    def test_every_references_link_resolves_inside_its_skill(self):
        broken = []
        for skill in sorted(SKILLS.glob("*/SKILL.md")):
            for name in sorted(set(LINK.findall(skill.read_text(encoding="utf-8")))):
                target = skill.parent / name
                if target.is_symlink() or not target.is_file():
                    broken.append(f"{skill.relative_to(ROOT)} -> {name}")
        self.assertEqual(broken, [], "dead references/ links")

    def test_task_template_lives_with_the_bootstrap(self):
        template = SKILLS / "sarah-bootstrap" / "references" / "task-template.md"
        self.assertTrue(template.is_file() and not template.is_symlink())

    def test_templates_symlink_points_at_the_bootstrap_copy(self):
        link = ROOT / "templates" / "task-template.md"
        self.assertTrue(link.is_symlink())
        self.assertEqual(link.resolve(), (SKILLS / "sarah-bootstrap" / "references" / "task-template.md").resolve())

    def test_init_no_longer_names_its_own_task_template(self):
        text = (SKILLS / "sarah-init" / "SKILL.md").read_text(encoding="utf-8")
        self.assertNotIn("references/task-template.md", text)


if __name__ == "__main__":
    unittest.main()
