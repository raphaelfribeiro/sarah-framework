# A count that can fail out loud

**Date:** 2026-08-15 · **Level:** 1 · **Phase:** 5-implement

The harness logged `sarah-3 step 1 invoked the framework zero times - recorded
as a finding`. That sentence is the strongest claim this study can make against
the framework: it says the framework did not survive the handover to a cold
session.

It was never measured. The inline counter crashed on the one event in four
hundred whose `message` is a string rather than an object, its traceback went to
an uncaptured stderr, and `${used:-0}` turned the empty result into a zero.

## The recount

| Run | step 0 | step 1 | step 2 | step 3 |
| --- | --- | --- | --- | --- |
| `sarah-1` | 0 | 2 | 2 | 2 |
| `sarah-2` | 0 | 2 | 2 | 2 |
| `sarah-3` | 0 | **1** (logged empty) | 1 | 1 |

Step 0 counts zero by design: it carries an explicit `/sarah-init`, and a slash
command is expanded before it can become a tool call. Every other step of every
framework-arm run invoked the framework. **The finding was an artefact and is
withdrawn.** Every number that had been recorded reproduced exactly, so nothing
else in the study moves.

## What changed

`docs/study/count-framework-use.py` holds the expression once, for the harness
and for any later recount — the round-5 lesson, where the fix was not another
check but making divergence impossible. It prints a number and exits 0, or
prints nothing to stdout, explains itself on stderr, and exits non-zero.

The harness records `COUNT FAILED` and says so in the run log when that happens.
It no longer has a default that means zero.

## Deliberately not done

The original `framework-use.log` files are kept beside the new
`framework-use.recount.log`. The wrong numbers are evidence for the incident
entry, and overwriting them would erase the only trace of what was nearly
published.

## The shape, completed

Three instruments in one day. The probe could not say *I did not measure*; the
orchestrator could not say *there is nothing here to clear*; this one could not
say *I crashed*. Only this one would have survived into a published result — the
number was already sitting in a log file, in the shape a reader trusts.
