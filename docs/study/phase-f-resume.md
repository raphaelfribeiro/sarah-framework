# Phase F — how to run it

Nothing is running. Everything below is unattended: start it and walk away.

## The one command

    STUDY_BASE=<your runs dir>/phase-f \
    STUDY_BRIEF=<your runs dir>/phase-e/brief.md \
    nohup sh docs/study/run-phase-f.sh > /dev/null 2>&1 &

Progress goes to `$STUDY_BASE/logs/orchestrator.log`. Watch it with
`tail -f`, or don't — the run does not need you.

    tail -f <your runs dir>/phase-f/logs/orchestrator.log

It is finished when `$STUDY_BASE/logs/STUDY-COMPLETE` exists. If it stops early
for any reason, **run the same command again** — every finished step is skipped
and it picks up where it stopped.

## What it does

Six runs in pair order: `sarah-1`, `plain-1`, `sarah-2`, `plain-2`, `sarah-3`,
`plain-3`. Pairs finish together, so an interrupted study still has matched
pairs to compare instead of three of one arm.

Rate limits are expected. A step that hits one exits 5; the orchestrator waits
15 minutes (`STUDY_WAIT`) and re-invokes, up to 40 attempts per run
(`STUDY_MAX_ATTEMPTS`). Three failures are *not* retried, because retrying them
would produce a run that looks valid and is not:

| Exit | Meaning | Why it stops |
| --- | --- | --- |
| 2 | Configuration | A path or variable is wrong; retrying changes nothing |
| 3 | Arm isolation failed | The arms are not what they claim to be |
| 4 | Framework never initialised | The framework arm is a control run wearing the wrong label |

## Before it starts

The orchestrator moves anything already in `runs/` to `archive/`. **The two
partial runs from 2026-08-07 cannot be resumed.** They were built when the
harness gave each arm different setting sources, so `sarah-1` ran with the
maintainer's own `CLAUDE.md` and came out written in Portuguese while the
control did not. That is the confound recorded in `incidents.md`, and it is why
those builds are evidence rather than a starting point. `plain-1` produced
almost nothing before it was cut.

## What it measures

Build once, then three changes in COLD SESSIONS — no `--continue` anywhere. The
session that receives change 2 did not write change 1 and can only read what the
repository carries. See `changes-phase-f.md`. Each change walks into a decision
the first build had to make:

1. A sender that signs differently — trap: relaxing the canonical string
   globally removes replay protection from everyone.
2. Duplicates getting through — trap: a global uniqueness key makes one sender's
   delivery a duplicate of another's, and with one sender configured no test
   notices.
3. The database growing — trap: pruning the dedup keys makes an old redelivery
   new again.

Measured after each change: does the pre-existing suite still pass, was a
recorded decision reversed without mention, was the named trap taken.

## After it finishes

    STUDY_BASE=... sh docs/study/package-for-judging.sh <arm> <n> <label>
    STUDY_BASE=... sh docs/study/judge-all.sh

Packets are scored against `rubric-v2.md`, blind. Labels must not encode the
arm; the mapping lands in `KEY-DO-NOT-SHOW-JUDGES.txt`, outside every packet.

## What was fixed before this run

- **Both arms load the same setting sources.** The framework reaches its arm
  through `--plugin-dir` alone, and both arms are told to write in English in
  the same words. This is the whole reason Phase E could not be trusted.
- **A rate-limited step no longer counts as finished.** It exits 0 with the
  error in-band; reading only the exit code wrote `COMPLETE` over work that
  never happened.
- **Step 0 is verified by artefacts on disk**, not by counting tool calls: a
  slash command is expanded before it becomes a `Skill` call, and counting calls
  voided a valid run.
- **Steps 1-3 count real invocations, and a zero is RECORDED, never aborted** —
  whether the framework fires on its own in a cold session is the question this
  study exists to answer.
