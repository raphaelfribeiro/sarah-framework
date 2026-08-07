# Incidents during the study

Recorded as they happened, for the writeup. Anything that could have changed a
number belongs here whether or not it flatters the result.

## 2026-08-06 23:51 — session rate limit cut sarah-2 at step 3

HTTP 429, "session limit · resets 11:50pm". The harness had marked steps 1 and 2
complete, so resuming re-ran only step 3. Cost: a few minutes. No work lost.

Third rate-limit cut of the day across all runs. Expected, not exceptional, and
the reason the harness records per-step completion instead of running six arms
from one script.

## 2026-08-07 01:50 — the treatment arm twice failed to load the framework

**This is the most important incident so far, because it would have been
invisible.**

`sarah-3` aborted on attempts 1 and 2. The isolation probe asked the model to
list skills whose name starts with `sarah` and got `NONE` — in a run that is
supposed to have the framework loaded. Attempt 3 probed clean ("framework
present") and proceeded.

Cause: the plugin is installed at user scope, and a freshly created project
directory does not immediately get it. The first two probes ran before the
plugin was available for that directory.

**What would have happened without the probe.** `sarah-3` would have executed
its eight phase-shaped prompts with no framework loaded: no `sarah-bootstrap`,
no phase skills, no specialists. It would have produced an artefact, completed
normally, and been packaged and scored as a treatment-arm result. One third of
the treatment arm would have been a control in disguise, and nothing in the
output would have looked wrong.

This is why the probe refuses to proceed rather than warning. A study that
detects its own contamination only when someone thinks to look for it is a study
that reports contaminated numbers whenever nobody thinks to look.

Verified afterwards: `sarah-1` and `sarah-2` both logged "isolation ok:
framework present" before their first step, and all three control runs logged
"framework absent". Every run's probe output is kept in
`logs/<arm>-<n>/isolation-probe.txt`.

## Timing observed so far

| Run | Wall clock |
| --- | --- |
| plain-2 | 48 min (01:02 to 01:50) |

## 2026-08-07 — the blinding leaked through the README, and judging had started

The packaging script strips `sarah/`, `docs/` and `ARCHI.md`, but the READMEs
written by the framework arm **document those directories** — typically in a
project-tree listing. All three treatment packets (B, D, F) named the framework;
all three control packets did not. A perfect signal.

Judging had already begun on packet A when this was caught. It was stopped, the
one partial score was discarded, and all six packets were re-scored from scratch
so every packet is judged under one protocol.

**Fix:** any line referencing a stripped path is removed, from all six packets
identically. Control packets contain no such lines, so nothing changes there.
The rule is "describe what is in the packet", not "hide the framework".

**This edits artefacts after the fact**, which is worth stating plainly. Leaving
the arm visible in half the packets would have made every blind score
meaningless, so the edit is the lesser harm — but it is an edit, and it is
recorded rather than buried. Verified afterwards: every removed line was a
comment, a docstring line, or a tree entry. No executable statement was touched;
all Python still parses and the TOML config still loads.

## 2026-08-07 — a defect I reported in sarah-1 was my own testing error

I recorded that sarah-1 could not run its own suite on a clean checkout,
because my attempt failed with `ModuleNotFoundError: No module named 'tests'`.

**That was wrong.** All three blind judges built a fresh virtualenv and ran the
suite successfully, reporting 149 passing tests with the output as evidence.
Three independent verifications with evidence beat one of mine without it.

Kept here rather than deleted, because a study that quietly removes its author's
mistakes is not showing its work. The lesson generalises: my own spot checks are
not more trustworthy than the instrumented procedure, and when they disagree the
procedure wins unless I can show otherwise.
