# An instrument must be able to report that it did not measure

**Date:** 2026-08-14 · **Level:** 1 · **Phase:** 5-implement

Phase F's isolation probe asks the model to name the skills whose names start
with `sarah`, and checks the answer for `sarah-bootstrap`. On 2026-08-14 the
answer was `You've hit your session limit`, the marker was absent, and the check
concluded that the framework arm could not see the framework — exit 3, the one
code the orchestrator deliberately never retries. `sarah-2` died with 28 minutes
and $12 of finished work behind it.

The defect was also asymmetric, and quieter on the other side: an empty answer
contains no marker either, so on the control arm the same dead probe passed as
proof of absence. Both controls happened to answer `NONE` for real. That is luck.

## What changed

`docs/study/run-arm-phase-f.sh` — each verdict now requires its own affirmative
evidence:

| Answer | Verdict | Effect |
| --- | --- | --- |
| Names `sarah-bootstrap` | present | framework arm proceeds; control arm aborts |
| Says `NONE` | absent | control arm proceeds; framework arm aborts |
| Anything else | inconclusive | exit 5 — the orchestrator waits and retries |

Only a probe that answered and contradicts its arm still aborts the run.

## Verified

Six inputs through the verdict logic: the exact session-limit text that killed
`sarah-2`, an empty string, the three probe answers already on disk, and
`NONETHELESS` as a near-miss for the `NONE` marker. All correct. `sh -n` clean;
`shellcheck` reports only the two pre-existing warnings, both intentional.

Installed into the running study by atomic rename, because `sh` reads a script
incrementally and a run was in flight. It changes how a failed probe is handled
and nothing that is measured — no prompt, no arm setting, nothing in the plugin.

## The pattern this belongs to

The fourth instrument bug of one family, after the sanitiser that deleted lines,
the rate-limited step that counted as complete, and the framework-use check that
counted tool calls. Each read a failure of the instrument as a measurement.
**A check with only two outcomes will eventually assign one of them to its own
failure.**
