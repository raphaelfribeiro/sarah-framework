# The visibility work, verified by running it

**Date:** 2026-08-15 · **Level:** 2 · **Phase:** 5-implement → 6-review

Reading instructions proves nothing about whether a skill fires. The
`test-engineer` sat in this repository for weeks, promised in the README and
invoked by nobody, and a grep would have said it was there the whole time. So
the day's work was run against a fresh project with the plugin loaded exactly as
a user would get it.

## What the run confirmed

| Promise | Evidence |
| --- | --- |
| Welcome and the eight-step map before the first question | All eight printed at `/sarah-init`, ahead of the stack interview |
| Itinerary with the reason drawn from the request | `[ ] Brainstorm — ARCHI already names what to build`, `[x] Security — CSV is untrusted input` |
| The work stops at the itinerary and waits | It stopped, and said it would create the task file once the itinerary was set |
| A task file per branch | `sarah/state/core-converter.md`, created with the approved itinerary in it |
| The index carries the row and what it waits on | `Waiting on: Phase 6 review — feature/core-converter is unmerged` |
| Gate 3 | Commits landed `test:` before `feat:` on a feature branch created without being asked |

## The correction worth keeping

The first run showed no task file, and this file's author called that a defect of
the same family as the orphaned `test-engineer`. **It was not.** The model had
read the instruction and said so explicitly — it would create the file once the
itinerary was approved — and then stopped at the decision point, which is
correct. The harness had no way to approve anything, so the run died at the exact
gate it was built to observe.

That is the Phase E trap wearing different clothes: there, prompts said "do not
ask me anything" and no human gate could ever be proven. Here, a test walked into
a gate it could not answer and the silence was read as a failure.

## What changed anyway

Creating the task file is now imperative rather than descriptive, and names the
reason it gets skipped. Gate 5 does not close for a task with no file. And
`/sarah-status` treats "work exists, no task file" as a finding instead of
reporting "nothing in flight" with a straight face.

To fit, `sarah-bootstrap` dropped its restatement of gate 5, which
`docs/quality-gates.md` already carries in full: ~1,950 tokens against the 2,000
ceiling.

## Cost

About US$ 6 across four runs. It caught a wrong diagnosis before it reached a
release, which is what it was for.
