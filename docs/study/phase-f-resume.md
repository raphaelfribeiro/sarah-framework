# Phase F — how to resume

Paused 2026-08-07. Nothing is running.

## Where it stopped

Two runs partial, build step only:
- `runs/sarah-1` — framework initialised (ARCHI.md, sarah/state.md present)
- `runs/plain-1` — control build interrupted by the 15:00 rate limit

Neither has a COMPLETE marker. Both resume from their last finished step; the
harness skips steps whose log holds a successful result line.

## To resume one run

    sh ~/dev/sarah-runs/phase-f/run-arm.sh sarah 1

## To resume everything

Relight the orchestrator: it chains sarah-1, plain-1, sarah-2, plain-2, sarah-3,
plain-3, waits out rate limits by polling every 15 minutes, and writes
`logs/STUDY-COMPLETE` when done. The one-liner is in the session transcript; it
is a `for` loop over the six pairs calling run-arm.sh with a quota-wait inner
loop.

## What this study measures

Build once, then three changes in COLD SESSIONS (no --continue). See
`changes.md`. Each change walks into a decision the first build had to make:

1. A sender that signs differently — trap: relaxing the canonical string
   globally removes replay protection from everyone.
2. Duplicates getting through — trap: a global uniqueness key makes one sender's
   delivery a duplicate of another's, and with one sender configured no test
   notices.
3. The database growing — trap: pruning the dedup keys makes an old redelivery
   new again.

Measured after each change: does the pre-existing suite still pass, was a
recorded decision reversed without mention, was the named trap taken.

## Instrument bugs already fixed here

- Step completion checks `is_error`, not just the presence of a result line. A
  rate-limited step used to be marked done and skipped.
- Step 0 is verified by artefacts on disk, not by counting tool calls: a slash
  command is expanded before it becomes a Skill tool_use, and counting calls
  voided a valid run.
- Steps 1-3 count real Skill/Agent invocations, and a zero is RECORDED, never
  aborted — whether the framework fires on its own in a cold session is the
  question this study exists to answer.
