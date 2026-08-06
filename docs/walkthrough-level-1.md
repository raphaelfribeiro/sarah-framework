# Walkthrough — Level 1, a bug fix

> **This walkthrough is illustrative.** Unlike
> [the Level 3 walkthrough](walkthrough-level-3.md), which reports a real
> instrumented run with measured numbers, this one describes the intended flow.
> The figures a real run would produce are not stated here, because inventing
> them would be worse than omitting them.

Most work is not a new product. It is a bug, a small feature, a change contained
in code that already exists. Level 1 exists so that work does not pay for
ceremony it does not need — and getting this wrong is the most expensive mistake
available in a workflow framework. A PRD for a one-line fix teaches everyone to
route around the process, and then the process is not there when it matters.

## What Level 1 costs you

A mini-plan under one page, then implementation, then review. Phases 5 and 6
only. No brainstorm, no spec, no architecture, no design.

Two gates hold, and two relax:

| Gate | At Level 1 |
| --- | --- |
| Spec approved | Not applicable — there is no spec |
| Plan approved | Holds. The mini-plan is approved before code is written |
| Test first | Relaxed. Tests afterwards are acceptable **if the user chooses that** |
| Review before merge | Holds. The author never reviews |
| Documented and committed | `sarah/state.md` updated, work committed. Nothing else |

The documentation row is deliberately almost empty. A documentation gate that
demands paperwork for a typo is a gate everyone learns to skip.

## The flow

**You describe the bug.** No command. `sarah-bootstrap` fires on intent, reads
`sarah/state.md` and the relevant parts of `ARCHI.md`, and sizes the request. A
contained fix in known code sizes to Level 1, and the level is recorded in
`sarah/state.md`.

**You get a mini-plan, not a document.** Under a page: what is broken, what the
fix is, what it touches, and what could break. It arrives as something to
approve — the plan gate is hard even here, because implementing without an
approved plan is how a one-line fix becomes an afternoon.

**Implementation.** `sarah-phase-implement` loads `developer` and
`test-engineer`. A regression test for the reported behaviour, plus a test for
the fix itself. At Level 1 you may choose to write the tests after the code; the
skill will say so rather than assume it.

**Review, by someone who did not write it.** `sarah-phase-review` spawns
`code-reviewer` into a clean context. This gate does not relax with level — the
author never reviews their own work, and at Level 1 the review is short because
the change is small, not because the standard dropped.

**Close it.** `sarah/state.md` updated, work committed on the feature branch.
Every phase that produces an artefact ends with a commit; the pull request comes
at the delivery boundary.

## Where Level 1 goes wrong

**Sizing up to be safe.** A bug fix that gets the full pipeline wastes an
afternoon and teaches you that the framework is overhead. Over-classifying is
the single most common failure of workflow frameworks, and S.A.R.A.H. is not
immune to it.

**Sizing down to move fast.** A change that crosses a component boundary, or
introduces a new one, or alters a schema, is Level 2 wearing a Level 1 costume.
The tell is usually the review: if the reviewer keeps asking about consequences
elsewhere in the system, the sizing was wrong.

**Skipping the review because the change is small.** The review gate is where
the framework earns its cost, and small changes are where confidence is highest
and attention is lowest.

If the level is genuinely ambiguous, the framework asks rather than guesses,
with both candidate levels and what each one costs.
