"""S13 for the dispatch guard payload, and the prose that binds it (R15, R17).

The guard and its brief agree on one format: the Premises line in the task file.
This checks the payload against the same rules CI applies to every payload, and
that the template, the brief and the catalog carry the words the guard reads.
"""

import json
import re
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PAYLOAD = ROOT / "skills" / "sarah-init" / "habits" / "dispatch-guard"
GUARD = PAYLOAD / "files" / "sarah" / "hooks" / "dispatch-guard" / "guard.sh"
TEMPLATE = ROOT / "skills" / "sarah-bootstrap" / "references" / "task-template.md"
BRIEF = ROOT / "skills" / "sarah-phase-implement" / "references" / "executor-brief.md"
CATALOG = ROOT / "skills" / "sarah-init" / "references" / "habits-catalog.md"


class Payload(unittest.TestCase):
    def test_manifest(self):
        meta = json.loads((PAYLOAD / "habit.json").read_text())
        self.assertEqual(meta["settings"], [{"event": "PreToolUse", "matcher": "Agent", "file": "sarah/hooks/dispatch-guard/guard.sh"}])
        self.assertIn({"path": "worktree.baseRef", "value": "head"}, meta["keys"])
        self.assertIn(".claude/settings.local.json", meta["include"])
        self.assertEqual(meta["requires"], [])

    def test_guard_uses_the_shared_library_and_falls_open_without_it(self):
        text = GUARD.read_text()
        self.assertIn("_lib/exceptions.sh", text)
        self.assertRegex(text, r"(?s)\[ ! -f \"\$here/\.\./_lib/exceptions\.sh\" \].*?exit 0")

    def test_each_check_honours_an_exception_for_its_own_rule(self):
        text = GUARD.read_text()
        for rule in ("dispatch-model", "dispatch-limit", "dispatch-premise"):
            self.assertRegex(text, rf"deny {rule} ", rule)

    def test_posix_sh_syntax(self):
        r = subprocess.run(["sh", "-n", str(GUARD)], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_exit_codes_are_only_0_or_2(self):
        self.assertIsNone(re.search(r"^[ \t]*exit[ \t]+([13-9]|[0-9]{2,})", GUARD.read_text(), re.M))

    def test_no_set_e_and_no_bashisms(self):
        text = GUARD.read_text()
        self.assertNotRegex(text, r"(?m)^\s*set\s+-[a-z]*e")
        for bashism in ("[[", "<<<", "$'", "date -d"):
            self.assertNotIn(bashism, text, bashism)
        self.assertNotRegex(text, r"(?m)^\s*(local|declare)\s")

    @unittest.skipUnless(shutil.which("shellcheck"), "shellcheck not installed")
    def test_shellcheck_posix(self):
        r = subprocess.run(["shellcheck", "-s", "sh", "-S", "warning", str(GUARD)], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout)


class Prose(unittest.TestCase):
    def test_template_defines_the_premises_line(self):
        text = TEMPLATE.read_text()
        self.assertIn("- YYYY-MM-DD - <premise>", text)
        self.assertIn("- YYYY-MM-DD - none", text)

    def test_brief_opens_with_step_zero(self):
        text = BRIEF.read_text()
        self.assertRegex(text, r"(?m)^## Step 0$")
        for needle in ("feature/<slug>", "- setup:", "baseline", "sarah/state/<slug>.md"):
            self.assertIn(needle, text, needle)
        self.assertLess(text.index("## Step 0"), text.index("## Full"))

    def test_catalog_documents_the_settings_lines(self):
        text = CATALOG.read_text()
        for needle in ("- dispatch checks: model, premise, limit", "- limit: 3", "- setup: <command>", "apply _lib dispatch-guard"):
            self.assertIn(needle, text, needle)


if __name__ == "__main__":
    unittest.main()
