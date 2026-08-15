# State is per task, not per repository

**Date:** 2026-08-15 · **Level:** 3 · **Phase:** 5-implement

Asked how S.A.R.A.H. would behave inside a sprint, the honest answer was that it
would not. The state model was single-track by construction: one
`sarah/state.md`, one `Current task`, one phase — versioned and rewritten
continuously, 31 commits deep.

**Two branches meant two divergent copies of that file and a conflict at every
merge.** That was already true; a sprint only makes it daily.

## The split

| File | Holds | Lifetime |
| --- | --- | --- |
| `sarah/state.md` | The index: what is in flight, what each task waits on, what the project carries forward | Permanent, small |
| `sarah/state/<branch-slug>.md` | One task: itinerary, phase, gates, decisions, next | Created when work starts, **deleted when it ships** |

Named after the branch, so a task and its state travel together and no two
tasks ever write the same file. Deleted on delivery because the changelog entry
is the permanent record — a directory of finished task files is a graveyard that
makes the index worse every week.

`sarah/state.md` stays the entry point every skill and hook already reads. 27
files referenced it; breaking all of them would have been worse than the defect.

## What a board with sixty cards gets

A task file is created when work **starts**, not when a card exists. Sixty cards
do not become sixty files — they become the three that are moving. The board
stays the truth about priority; S.A.R.A.H. only knows, for each active piece,
where it stopped and what it waits on.

## Migrated here first

This repository runs the framework it defines, so it migrated before anything
else shipped: `sarah/state.md` went from 250 lines to 24, and the work in flight
moved to `sarah/state/v1-readiness.md` with its itinerary recorded.

## The hook would have gone quiet

`session-start.sh` read `Phase` and `Current task` from a file that no longer has
them, and detected work by counting bullets in a section that is now a table. It
would have degraded to silence — the exact failure mode this week has been spent
hunting. It now counts table rows, still reads the old fields for a project that
predates the split, and says how many tasks are in flight. Verified by running
it against this repository and against a directory with no S.A.R.A.H. at all.

Also fixed while there: it printed `phase unknown` after the split. A placeholder
where information used to be teaches the reader to skip the line.

## Deliberately not done

No sprint ceremony. No planning, no points, no retro. That is the team's work,
the board is better at it, and the framework already costs 21% more without it.
