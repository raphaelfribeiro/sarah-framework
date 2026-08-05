---
name: sarah-status
description: Report where the work stands - current phase, scale level, open gates, pending decisions, and what is blocked. Use when the user runs /sarah-status, asks "where are we", "what's the status", "what's pending", "what am I waiting on", or wants a quick picture of the project's workflow state without starting any work.
---

# /sarah-status — situation, in thirty seconds

Read `sarah/state.md`. Report it. Stop.

This command answers one question — *where does the work stand?* — and it answers it fast. It is not a report, it is a glance.

## What to read

`sarah/state.md`, and nothing else. Do not read `ARCHI.md`, do not scan the codebase, do not run the test suite. Those cost tokens and time to answer a question the state file already answers.

If `sarah/state.md` does not exist, say the project is not initialized and offer `/sarah-init`. One line.

## What to report

Half a page, maximum:

1. **Phase and level.** Where the work is, and at what scale.
2. **In flight.** What is actually being worked on. "Nothing in flight" is a complete and healthy answer.
3. **Blocked.** What cannot move, and what it waits on. Name the blocker, not just the blocked thing.
4. **Pending decisions.** Choices waiting on the user, with how long they have waited. These are stop signs for the work behind them.
5. **Open gates.** Which gates are still open for the current task, at this level. Skip the ones marked not applicable — listing gates that do not apply trains people to skim the list.

## What never happens here

- **No work starts.** This command reports; it does not act, plan, or fix. If the user wants to act on what they see, they say so and the phase skills take over.
- **No file is written.** Not even `sarah/state.md`.
- **No advice unless asked.** One line pointing at the most useful next thing is welcome. A plan is not.
- **No padding.** If the answer is "phase idle, nothing in flight, nothing blocked", that is the whole output. Stretching it to look substantial wastes the one thing this command sells, which is speed.

## When the state file is stale

If `sarah/state.md` was last updated days ago and the git log shows work since, say so. A state file that has drifted from reality is worth one sentence — it is exactly the kind of rot `/hasta-la-vista` exists to prevent, and pointing at it is more useful than reporting stale numbers with a straight face.
