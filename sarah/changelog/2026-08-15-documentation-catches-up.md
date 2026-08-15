# The documentation catches up with the framework

**Date:** 2026-08-15 · **Level:** 2 · **Phase:** 5-implement

One pass to make the repository stop describing a framework that no longer
exists, after a day in which the study finished and the workflow became visible.

## What changed

| File | Was saying | Now says |
| --- | --- | --- |
| `docs/study/results-phase-f.md` | did not exist | The six runs, 18 blind scores, the cost, and the blinding that failed |
| `docs/study/results.md` | the study, present tense | superseded, with a pointer to the one that ran with fixed instruments |
| `docs/quality-gates.md` | gate 5 ends at documentation | a release also closes on being observable and reversible |
| `README.md` | "the comparative evidence does not exist yet" | it exists, it is ours, and it does not favour us |
| `docs/walkthrough-level-3.md` | a run with eight silent phases | plus what a user sees today that the recorded run did not show |
| `skills/sarah-status/SKILL.md` | phase and level as names | the eight-step map with the current position marked |

## What was deliberately not edited

`ARCHI.md`. It describes the plugin's structure — skills, agents, hooks, context
budget — and adding a deliverable to an existing phase moved none of that.
Marked not-applicable in `sarah/state.md` rather than given a cosmetic edit,
because a gate satisfied by pretending is not a gate.

The Level 1 walkthrough, for the same reason: nothing it shows has changed.

The Level 3 walkthrough was **annotated rather than rewritten**. It records a run
that actually happened on 2026-08-06; editing it to show the map would be
describing a run nobody performed.

## Still open

The phase fusion — brainstorm, spec, architecture and design-ux into one shaping
phase. It is the change most likely to move the measured 21% cost premium, and
it lands alone so that its effect can be attributed to it.
