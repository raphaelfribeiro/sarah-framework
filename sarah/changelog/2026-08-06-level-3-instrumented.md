# The Level 3 pipeline, instrumented from step 1

**Date:** 2026-08-06 · **Level:** 3 · **Phase:** 5-implement

The 2026-08-05 run proved the pipeline completes but left two things unproven,
because steps 1 to 5 ran without instrumentation. Both are now settled, against
a fresh greenfield project with `--output-format stream-json` on every step.

**Gate 3 holds.** Eight test files were written, the suite was executed **five
times and came back red every time** — `ModuleNotFoundError: No module named
'caderno.cli'`, seven collection errors — while `src/` held nothing but a
three-line package `__init__`. This is a red suite for the right reason, not
directory ordering, which was all the previous run could show.

**The specialists fire unprompted.** No prompt named an agent or a skill. Every
phase routed itself through `sarah-bootstrap` and its own phase skill, then
spawned its own roster: `product-analyst` (brainstorm), `product-manager`
(spec), `software-architect` **and `security-advisor`** (architecture),
`ux-ui-designer` (design), `test-engineer` and `developer` (implementation),
`code-reviewer` and `security-advisor` (review), `devops-engineer` and
`release-manager` (release). The security advisor consulting on architecture is
behaviour `sarah-bootstrap` documents and nobody had ever observed.

**Gate 4 stopped the delivery.** The review returned **four blocking findings**,
each with a reproduced scenario. The most serious: `caderno edit` wrote
**through a symlink to outside the notes directory** — a collection cloned from
a third party could have had `~/.bashrc` rewritten, exit code 0, no signal. It
violated an invariant the project's own `ARCHI.md` declared closed. The second:
`search` went blind to the body of any note with invalid YAML, answering "no
notes found" for a term literally present.

**The reviewers' own summary is the finding that matters most:** *the 147
passing tests covered none of these scenarios.* The defects lived exactly where
the suite did not look. Resolving them produced twelve new tests — 159 passing,
verified by an independent run — and the fix phase re-ran `code-reviewer` and
`security-advisor` without being asked.

**Measured cost:** $39.64 and roughly 90 minutes of model time for one complete
Level 3 delivery, from empty directory to tagged `v0.1.0` with CI.

**What this run does not prove, and must not be read as proving:**

- **Every prompt carried "do not ask me anything and do not stop for approval",**
  which is unavoidable headless and subverts the ask → options → approve
  protocol. This exercises the automatic gates. It cannot exercise the human
  ones, and gates 1 and 2 are human by definition.
- **Phase 6 was cut by a session rate limit and resumed.** Not a clean run. The
  resumed half spawned no subagent — the orchestrator finished the code itself,
  which is not how the phase is meant to work.
- **One project, one run.** Nothing here separates the framework's contribution
  from the model's. That is what the Phase E study exists to measure, and this
  run is not a substitute for it.
