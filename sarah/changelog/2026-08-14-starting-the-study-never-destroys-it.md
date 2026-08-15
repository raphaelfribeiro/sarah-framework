# Starting the study never destroys it

**Date:** 2026-08-14 · **Level:** 1 · **Phase:** 5-implement

`run-phase-f.sh` began by archiving everything in `runs/` and deleting the
per-run logs. It was written for one situation — two pre-fix builds carrying the
setting-sources confound, which really could not be resumed — and that migration
ran once, correctly. What survived it was a rule that said "clear whatever is
here".

`phase-f-resume.md` meanwhile told the operator that the answer to an
orchestrator that stopped early is to run the same command again. By the evening
of 2026-08-14 that command would have deleted three finished runs, their logs,
and about $100 of work. **The recovery step and the destroy step were the same
command.**

## What changed

| Situation | Before | Now |
| --- | --- | --- |
| `runs/` has work, plain rerun | archived and logs deleted | resumed; nothing moved or deleted |
| Operator wants a clean start | no way to ask for it | `STUDY_ARCHIVE=1`, still a move, never a delete |
| Redo one run of six | no documented way | arm script directly, documented in `phase-f-resume.md` |

## Verified

A sandbox with a stubbed arm script, both paths. A normal rerun leaves a seeded
run's artefact byte-identical and skips it as finished. `STUDY_ARCHIVE=1`
relocates it under `archive/` intact. `sh -n` clean; `shellcheck` reports only
the pre-existing `SC1007`.

Nothing was actually lost — the orchestrator never died, so the documented
recovery was never run. The window was closed by inspection rather than by
consequence, which is the only reason this entry is a fix and not a post-mortem.

## The shape, twice in one day

The isolation probe could not say "I did not measure". This could not say
"there is nothing here to clear". Both were single-purpose steps that outlived
their purpose while keeping their authority. See
[`docs/study/incidents.md`](../../docs/study/incidents.md) and
[`2026-08-14-probe-that-cannot-answer.md`](2026-08-14-probe-that-cannot-answer.md).
