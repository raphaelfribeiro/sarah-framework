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

---

## 2026-08-14 — a probe that could not answer counted as a verdict

`sarah-2` died at 19:02 with `ARM ISOLATION FAILED (exit 3) - not retrying`,
which is the one outcome the orchestrator deliberately refuses to retry, because
arms that are not what they claim cannot be fixed by trying again. The run had
already spent 28 minutes and $12 on a step 0 that finished.

The abort line carries its own diagnosis:

    ABORT: framework arm cannot see the framework: You've hit your session
    limit · resets 8:50pm

The probe asks the model to name the skills whose names start with `sarah` and
searched the answer for `sarah-bootstrap`. A session limit is not an answer, and
the check had no way to say so: stderr went to `/dev/null`, a failed decode
became the empty string, and absence of the marker meant absence of the
framework.

**The same defect was asymmetric, and worse on the control arm.** An empty answer
contains no `sarah-bootstrap`, so on `plain` the identical dead probe passed as
proof that the framework was absent — a verification that verified nothing while
logging that it had. The recorded probes show both controls answered `NONE` for
real, so the door was open and never walked through. That is luck, not design.

**The fix is by exclusion, which is the shape that has held here before.** Each
verdict now needs its own affirmative evidence: `present` requires the roster to
name `sarah-bootstrap`, `absent` requires the model to say `NONE`, and anything
else is inconclusive and exits 5 so the orchestrator waits and retries. Only a
probe that answered and contradicts its arm still aborts. Verified against six
inputs including the exact text above and the three probes already on disk.

**This is the fourth instrument bug of the same family**, after the sanitizer
that deleted lines, the rate-limited step that counted as complete, and the
framework-use check that counted tool calls. Every one of them read a failure of
the instrument as a measurement. The lesson has a sharper form now: **an
instrument must be able to report that it did not measure.** A check with only
two outcomes will eventually assign one of them to its own failure.

**What it costs Phase F:** `sarah-2` is void and will be rerun from zero once the
third pair finishes, with the corrected probe. The fix was installed mid-study by
atomic rename, so `sarah-3` and `plain-3` run with it. It changes how a failed
probe is handled and touches nothing that is measured — no prompt, no arm
setting, and nothing inside the plugin.

---

## 2026-08-14 — the recovery step and the destroy step were the same command

`run-phase-f.sh` opened by archiving everything in `runs/` and deleting the
per-run log directories. That was written for one situation: on 2026-08-14 the
only thing in `runs/` was two builds carrying the setting-sources confound,
which genuinely could not be resumed. The migration ran once and was correct.

The rule it left behind was not "clear the confound" but "clear whatever is
here" — and `phase-f-resume.md` told the operator that the response to an
orchestrator that stopped early is to **run the same command again**. By the
evening of 2026-08-14 that meant three finished runs and about $100 of work sat
behind an instruction that would have deleted them, and the logs with them.

Nothing was lost. The orchestrator never died, so the documented recovery was
never needed, and the one rerun that was needed went through the arm script
directly. The window was open for a day and closed by inspection rather than by
consequence.

**Fixed:** resuming is the default and moves nothing; discarding is
`STUDY_ARCHIVE=1`, still by move and never by delete. Verified in a sandbox with
a stubbed arm script: a normal rerun leaves a seeded run untouched and skips it,
and the explicit flag relocates it under `archive/` intact. The resume document
now also shows how to redo a single run without going near the orchestrator.

**The shape, for the fourth time in this study and the second today:** a step
written for one situation applied to every situation. The probe could not say
"I did not measure"; this could not say "there is nothing here to clear". Both
were single-purpose steps that outlived their purpose while keeping their
authority.

---

## 2026-08-14/15 — the counter crashed, and the crash became the finding

`sarah-3` step 1 was logged as **"invoked the framework zero times - recorded as
a finding"**. That is the single most consequential sentence this study can
emit: it says the framework did not survive the handover to a cold session.

It was not a measurement. The counter was an inline heredoc that did
`(ev.get("message") or {}).get("content")`, and one event in four hundred — a
`system/permission_denied` notice — carries `message` as a plain string. The
`AttributeError` went to a stderr the harness never captured, the command
substitution returned empty, and `[ "${used:-0}" -eq 0 ]` converted a dead
instrument into the study's headline result.

**The recount, from logs that were never at risk:**

| Run | step 0 | step 1 | step 2 | step 3 |
| --- | --- | --- | --- | --- |
| `sarah-1` | 0 | 2 | 2 | 2 |
| `sarah-2` | 0 | 2 | 2 | 2 |
| `sarah-3` | 0 | **1** (was logged empty) | 1 | 1 |

Step 0 counts zero by design — it carries an explicit `/sarah-init`, and a slash
command is expanded before it becomes a tool call. Every other step in every
framework-arm run invoked the framework at least once. **The finding was
entirely an artefact.** Nothing else moved: every previously recorded number
reproduced exactly.

**The fix is the round-5 shape, not another check.** The expression now lives in
`docs/study/count-framework-use.py`, used by the harness and by any later
recount, because two copies of a rule disagree eventually — this repository has
already paid that bill once, with a rename. The script prints a number and exits
0, or prints nothing to stdout, explains itself on stderr and exits non-zero.
The harness treats a failed count as `COUNT FAILED` in `framework-use.log` and
says so out loud, and it no longer has a default that means zero.

**Third of three in one day, and the pattern is now complete.** The probe could
not say "I did not measure". The orchestrator could not say "there is nothing
here to clear". This one could not say "I crashed". The first two cost money and
would have cost data; this one cost a conclusion, and it is the only one that
would have survived into a published result — the number was already in a log
file, in the shape a reader trusts.

**One thing seen in passing and not chased:** the permission_denied event that
broke the counter shows a headless run being refused an edit outside its project
directory. Worth understanding before the next study, and not a defect of this
one.
