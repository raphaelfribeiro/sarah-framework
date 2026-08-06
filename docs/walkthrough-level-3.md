# Walkthrough — Level 3, a new product from scratch

This is a real run, not an illustration. On 2026-08-06 the full Level 3 pipeline
was executed against an empty directory, instrumented end to end so that every
tool call and every subagent spawn was captured. The numbers below are measured.

The brief: a command-line tool in Python that stores notes as Markdown files
with YAML front matter, supports tags, and searches across them full-text.
Small enough to reach a release, real enough to have a filesystem, a command
surface, an error surface and a test pyramid.

**Result: eight phases, `v0.1.0` tagged, 159 tests passing, $39.64 and roughly
90 minutes of model time.**

## The shape of it

| Phase | Skill that fired | Specialists spawned |
| --- | --- | --- |
| 1 | `/sarah-init` | — |
| 2 Brainstorm | `sarah-phase-brainstorm` | `product-analyst` |
| 3 Spec | `sarah-phase-spec` | `product-manager` |
| 4 Architecture | `sarah-phase-architecture` | `software-architect`, `security-advisor` |
| 5 Design | `sarah-phase-design-ux` | `ux-ui-designer` |
| 6 Implementation | `sarah-phase-implement` | `test-engineer`, `developer` |
| 7 Review | `sarah-phase-review` | `code-reviewer`, `security-advisor` |
| 8 Release | `sarah-phase-release` | `devops-engineer`, `release-manager` |

**No prompt named a skill or an agent.** Each phase was opened with the kind of
sentence a user actually types — *"Before we build anything, I want to think
this through"*, *"How should we build this?"*, *"Build it."* — and the framework
routed itself: `sarah-bootstrap` first, then the phase skill, then that phase's
specialists and no others.

The `security-advisor` appearing alongside the architect is behaviour
`sarah-bootstrap` documents in its routing table and that had never been
observed before this run.

## Gate 3, caught in the act

The gate says: no production code without a failing test. Proving it needs
evidence of *order*, and the run produced it.

Eight test files were written. Then the suite ran, and ran red:

```
ImportError while importing test module 'tests/test_cli.py'
E   ModuleNotFoundError: No module named 'caderno.cli'
!!!!!!!!!!!!!!!!!!! Interrupted: 7 errors during collection !!!!!!!!!!!!!!!!!!!!
```

It ran red **five times**. At that point `src/` contained exactly one file — a
three-line package `__init__.py` holding a docstring and `__version__`. The
implementation the tests import did not exist.

That is a red suite for the right reason. An earlier run could only show that
`tests/` appeared before `src/`, which is directory ordering and proves nothing.

## Gate 4 stopped the delivery

The review phase spawned `code-reviewer` and `security-advisor` into clean
contexts that had never seen the code written. The verdict was **four blocking
findings**, each carrying a reproduced failure scenario rather than a suspicion.

The most serious: `caderno edit` resolved a note reference without excluding
symlinks, so a `.md` file that was a symlink pointing outside the notes
directory got **written through**. A collection cloned from a third party could
have had a file outside it silently rewritten, exit code 0, no warning. It
violated an invariant the project's own `ARCHI.md` declared closed.

The second: `search` discarded the body of any note whose front matter failed to
parse, so a term present verbatim in a note returned *"no notes found"* — a
wrong answer with no error, which is the worst failure mode a search tool has.

The reviewers' own summary is the line worth keeping:

> the 147 passing tests covered none of these scenarios

The defects lived exactly where the suite did not look. Fixing them produced
twelve new tests — 159 passing — and the fix phase re-ran both reviewers without
being asked to.

## What this run does not prove

A walkthrough that only reports what went well is marketing. Three limits, all
recorded in `sarah/changelog/2026-08-06-level-3-instrumented.md`:

**The human gates were not exercised.** Every prompt carried *"do not ask me
anything and do not stop for approval"*, which is unavoidable when driving the
CLI headlessly. Gates 1 and 2 — spec approved, plan approved — are human by
definition, so this run demonstrates the automatic gates and cannot speak to
the others.

**Phase 6 was interrupted.** A session rate limit cut the implementation phase
partway and it was resumed. The resumed half spawned no subagent; the
orchestrator finished the code itself, which is not how the phase is meant to
work.

**One project, one run.** Nothing here separates what the framework contributed
from what the model would have done anyway. That question needs a controlled
comparison, and answering it is a separate piece of work.

## Reproducing it

The run was driven with `claude -p` per phase, `--continue` to carry the session
forward, and `--output-format stream-json --verbose` so that spawns and tool
calls were recoverable afterwards. Prompts were kept deliberately neutral: no
mention of tests-before-code, no specialist named. Asking for either would have
made the experiment confirm itself.
