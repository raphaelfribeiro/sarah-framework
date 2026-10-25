"""Static checks S12, S13 and the prose edits of steps 11 and 12 (R13, R14, R16).

The gitflow workflow is the CI half of a blocking agreement that runs in other
people's repositories, so its permissions and its supply chain are asserted
here rather than trusted. The payload scripts are checked against the same
exit-code rule CI applies, plus shellcheck when it is installed.
"""

import json
import re
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HABITS = ROOT / "skills" / "sarah-init" / "habits"
WORKFLOW = HABITS / "gitflow" / "files" / ".github" / "workflows" / "sarah-gitflow.yml"
PAYLOADS = ("_lib", "gitflow", "changelog-fragment")
BOOTSTRAP = ROOT / "skills" / "sarah-bootstrap" / "SKILL.md"


def scripts():
    out = []
    for name in PAYLOADS:
        out += sorted((HABITS / name / "files").rglob("*.sh"))
    return out


class Layout(unittest.TestCase):
    def test_each_habit_has_a_manifest_and_files(self):
        for name in PAYLOADS:
            meta = json.loads((HABITS / name / "habit.json").read_text())
            self.assertIn("description", meta, name)
            self.assertTrue(list((HABITS / name / "files").rglob("*.sh")), name)

    def test_lib_ships_where_the_habits_source_it(self):
        self.assertTrue((HABITS / "_lib" / "files" / "sarah" / "hooks" / "_lib" / "exceptions.sh").is_file())
        for guard in ("gitflow", "changelog-fragment"):
            text = (HABITS / guard / "files" / "sarah" / "hooks" / guard / "guard.sh").read_text()
            self.assertIn("_lib/exceptions.sh", text, guard)

    def test_the_guards_are_registered_on_bash_pre_tool_use(self):
        for guard in ("gitflow", "changelog-fragment"):
            meta = json.loads((HABITS / guard / "habit.json").read_text())
            self.assertIn({"event": "PreToolUse", "matcher": "Bash", "file": f"sarah/hooks/{guard}/guard.sh"}, meta["settings"])

    def test_the_lib_registers_nothing(self):
        meta = json.loads((HABITS / "_lib" / "habit.json").read_text())
        self.assertEqual(meta.get("settings", []), [])


class Workflow(unittest.TestCase):
    """S12."""

    def setUp(self):
        self.text = WORKFLOW.read_text()

    def test_runs_on_pull_request_only(self):
        on = re.search(r"^on:\s*\n((?:[ \t]+.*\n|\n)+)", self.text, re.M)
        self.assertIsNotNone(on)
        triggers = re.findall(r"^  ([a-z_]+):", on.group(1), re.M)
        self.assertEqual(triggers, ["pull_request"])
        self.assertNotIn("pull_request_target", self.text)

    def test_contents_read_at_top_level(self):
        self.assertRegex(self.text, r"(?m)^permissions:\n  contents: read\n")
        self.assertEqual(len(re.findall(r"(?m)^\s*permissions:", self.text)), 1)

    def test_no_secrets(self):
        self.assertNotIn("secrets.", self.text)

    def test_only_checkout_and_it_is_pinned_to_a_sha(self):
        uses = re.findall(r"uses:\s*(\S+)", self.text)
        self.assertEqual(len(uses), 1)
        self.assertRegex(uses[0], r"^actions/checkout@[0-9a-f]{40}$")

    def test_refs_reach_the_script_as_data(self):
        # Interpolating a ref into run: is script injection.
        for run in re.findall(r"run:\s*(.*)", self.text):
            self.assertNotIn("${{", run)


class Scripts(unittest.TestCase):
    """S13."""

    def test_posix_sh_syntax(self):
        for f in scripts():
            r = subprocess.run(["sh", "-n", str(f)], capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, f"{f}: {r.stderr}")

    def test_exit_codes_are_only_0_or_2(self):
        # The pattern CI applies, so a local pass means a CI pass.
        bad = re.compile(r"^[ \t]*exit[ \t]+([13-9]|[0-9]{2,})", re.M)
        for f in scripts():
            self.assertIsNone(bad.search(f.read_text()), f)

    def test_no_set_e(self):
        # set -e turns any failed command into exit 1, which fails open.
        for f in scripts():
            self.assertNotRegex(f.read_text(), r"(?m)^\s*set\s+-\w*e", f)

    def test_no_date_dash_d(self):
        for f in scripts():
            self.assertNotRegex(f.read_text(), r"date\s+(-d|--date|-v)", f)

    def test_no_bashisms(self):
        for f in scripts():
            t = f.read_text()
            for needle in (" [[ ", "<(", "\nlocal ", "\nsource ", "\n. /dev/stdin"):
                self.assertNotIn(needle, t, f"{f}: {needle!r}")

    @unittest.skipUnless(shutil.which("shellcheck"), "shellcheck not installed")
    def test_shellcheck(self):
        for f in scripts():
            r = subprocess.run(["shellcheck", "-s", "sh", "-S", "warning", str(f)], capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, f"{f}:\n{r.stdout}")


class Prose(unittest.TestCase):
    def test_bootstrap_names_the_opt_in_exception(self):
        text = BOOTSTRAP.read_text()
        line = next(l for l in text.splitlines() if "Every merge has a human behind it" in l)
        self.assertIn("green CI", line)
        self.assertIn("merge-on-green", line)   # the exception is the recorded grant, not the habit being installed

    def test_bootstrap_stays_in_budget(self):
        self.assertLessEqual(len(BOOTSTRAP.read_text()) / 4, 2000)

    def test_status_lists_exceptions(self):
        text = (ROOT / "skills" / "sarah-status" / "SKILL.md").read_text()
        self.assertIn("Exceptions", text)
        self.assertIn("sarah_exceptions_list", text)
        self.assertIn("expired", text)

    def test_release_reads_the_user_facing_line(self):
        text = (ROOT / "skills" / "sarah-phase-release" / "SKILL.md").read_text()
        self.assertIn("User-facing:", text)


if __name__ == "__main__":
    unittest.main()
