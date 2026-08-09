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

## 2026-08-07 — quantifying the sanitizer contamination, and fixing it

Independent analysis put a number on the blinding leak recorded above. The
line-deleting sanitizer removed 7, 9 and 10 README lines from the three
framework packets and **zero from every control packet**. It also damaged
source: two files lost the closing clause of a comment, one lost a sentence
subject.

**Nine of the 96 unanticipated findings are damage the study inflicted**, all
of the form "prose truncated mid-sentence" or "cross-reference to a document
that does not exist", and all in one arm. Five more ("not a git repository")
come from stripping `.git`. **Roughly 15% of the evidence base is instrument
noise, perfectly correlated with one arm.**

v1's scores were saturated, so the scores themselves were unaffected — but any
analysis mining those findings must exclude them, and this study's own writeup
had already attributed the E3 loss partly to real defects when part of it was
self-inflicted.

**Fixed:** the sanitizer now substitutes a neutral token instead of deleting
lines, and asserts afterwards that every file's line count is unchanged from
source. A packet whose line count moved is a packet that was damaged.

## 2026-08-07 — a real defect no judge found, and the rubric that catches it

`sarah-1` derives its idempotency key from an **unsigned** header while signing
something else, which is the same replay-amplification hole judges reproduced
live in three other packets. It scored full marks on v1's item B3.

The instrument was blind to it in the artefact where it was hardest to see.
Item S1 of [`rubric-v2.md`](rubric-v2.md) is written to catch exactly this
class: a security property that holds today but has no mechanism preventing the
next change from breaking it.

## 2026-08-09 — the arms differed by more than the framework

Found while reviewing `feature/framework-v2-lean`, not by an instrument. The
harness gave the control `--setting-sources project` and the framework arm the
default, which also loads **user** settings. So one arm received the maintainer's
own `CLAUDE.md` — a language rule and a set of standing instructions unrelated to
this study — and the other received none of it.

**The comparison was framework-plus-personal-context against a bare CLI**, not
framework against no framework. Every result in Phase E carries this, including
the cost figures: the arm with more always-on instructions is also the arm that
cost more and varied more.

**The visible symptom:** `sarah-1` and `sarah-3` are written in Portuguese —
README, test names, docstrings — and all three control artefacts are in English.
The user `CLAUDE.md` says to answer in Portuguese; only one arm could see it.
That is simultaneously a confound and a **blinding leak the sanitizer cannot
catch**, because it strips names and paths, not languages. A judge holding six
packets, two of them in a different language, has a signal correlated with the
arm.

Nobody reported it. Three judges per packet, eighteen score files, and an
author's spot check all missed it, because everyone was reading for defects in
the software rather than for differences between packets.

**Fixed for Phase F:** both arms now load the same setting sources, and the
framework reaches its arm through `--plugin-dir` alone. Both arms are told, in
the same words, to write in English. The isolation probe still verifies that the
framework is visible in one arm and absent in the other.

**What it costs Phase E:** the comparison was already inconclusive because the
rubric saturated. This is a second, independent reason it cannot support a claim
in either direction, and it is the more serious of the two — a saturated
instrument measures nothing, but a confounded one measures the wrong thing while
looking like it worked.
