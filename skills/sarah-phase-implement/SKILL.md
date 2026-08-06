---
name: sarah-phase-implement
description: Plan the work, write the failing test, then write the code. Produces an implementation plan and a test plan across the pyramid, proportional to the scale level. Use when the user says "implement it", "build it", "write the code", "fix this bug", "make it work", when an approved spec or design is ready to build, or when a diagnosed bug needs fixing. This is the phase most work lands in.
---

# Phase 5 — Implementation

Most work lands here, including work that reaches here directly. A Level 0 typo and a Level 3 feature both pass through this phase; what differs is how much happens before the first line of code.

## Level behavior

| Level | Before code | Tests |
| --- | --- | --- |
| **0** | Nothing. Change it. | None. |
| **1** | A mini-plan under one page, approved by the user. | The changed behavior, plus a regression test for the bug. Tests may come after the fix if the user chooses. |
| **2** | Plan plus test plan, both approved. | Failing test first, no exceptions. Unit always; integration wherever the change touches a real boundary. |
| **3** | Full plan plus test plan, approved. | Failing test first. The full pyramid: unit, integration at every boundary, end to end on the critical flows. |

**Level 0 means Level 0.** No plan, no test, no gate beyond a working build. Reaching code in under a minute is the correct outcome, and adding ceremony here is the specific failure this framework was built to prevent.

## Who works this phase

**Developer** and **Test Engineer**, together. The test engineer proposes the test plan alongside the implementation plan — not afterward, because a test plan written after the design is a test plan shaped by the implementation.

## How it runs

1. **Read what you need and no more.** The spec, the plan, the files being changed, the neighbors of those files. Never a whole document as a routine step. If a step would cross roughly 30k tokens of input, it is the wrong step — split it.

2. **Produce the plan.** From `references/implementation-plan-template.md` at Level 2 and above; a short list at Level 1. It names the files, the order of work, and what could go wrong.

3. **Produce the test plan** in the same breath: what gets tested at which layer, and what is deliberately not tested.

4. **Get both approved.** This gate is hard. Do not implement without an approved plan.

5. **Write the failing test** (Level 2+). Run it. **Confirm it fails for the right reason** — a test that was green from the start has tested nothing, and this is the step that gets skipped.

6. **Spawn the `developer`** to implement against the failing test.

7. **Run everything.** Report actual output, including failures.

## The test-first gate

At Level 2 and above: **no production code without a failing test first.** Wrote the code before the test? Delete it and start over.

That instruction sounds theatrical and is meant literally. Writing the test afterward produces a test shaped to pass the code you already wrote, which is why retrofitted tests catch so little.

## What you never do

- Implement without an approved plan.
- Change more than the plan says. Notice something else wrong, report it, leave it. Unrequested changes hide the real change and make review guesswork.
- Weaken a test to make it pass. If the test is wrong, say why.
- Invent an API without verifying it exists. Check.
- Report success without running it. Everything downstream trusts that report.

## Exit gate

Code written, tests passing, and the actual test output shown to the user — not summarized as green.

Then **the documentation gate**, proportional to the level:

- **Level 0–1:** `sarah/state.md` updated. That is all.
- **Level 2+:** also `ARCHI.md` if anything architectural moved, `README.md` if anything user-visible changed, and a short entry in `sarah/changelog/`:

```markdown
# <what was delivered>

**Date:** YYYY-MM-DD · **Level:** N · **Phase:** 5-implement

Five to ten lines: what changed, why, and anything the next person needs to know.
Name what is deliberately not done.
```

If it isn't documented, it isn't done.

Then **commit** — on the feature branch, small and frequent while the work
happens, and never a single commit for the whole phase. Code that passes its
tests but sits uncommitted is not delivered: it survives no crash and can be
bisected by nobody. If it isn't committed, it didn't happen.

Then move to `sarah-phase-review`. You do not review your own work.
