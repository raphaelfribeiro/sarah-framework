---
name: sarah-status
description: Report where the work stands - current phase, scale level, open gates, pending decisions, and what is blocked. Use when the user runs /sarah-status, asks "where are we", "what's the status", "what's pending", "what am I waiting on", or wants a quick picture of the project's workflow state without starting any work.
---

# /sarah-status — situation, in thirty seconds

Read `sarah/state.md`. Report it. Stop.

This command answers one question — *where does the work stand?* — and it answers it fast. It is not a report, it is a glance.

## What to read

`sarah/state.md` — the index — and, only when the user asks about one task in particular, that task's file in `sarah/state/`. Nothing else: not `ARCHI.md`, not the codebase, not the test suite. Those cost tokens and time to answer a question the index already answers.

**With several tasks in flight, the index is the answer.** One row each, and the `Waiting on` column read out loud. Opening every task file to produce a fuller report is how a thirty-second command becomes a five-minute one nobody runs.

If `sarah/state.md` does not exist, say the project is not initialized and offer `/sarah-init`. One line.

## What to report

Half a page, maximum. **Use a table wherever there is more than one of anything** — gates, blockers, pending decisions. Prose describing three gates is an essay about three gates; three rows are three gates.

Mark anything waiting on the user as waiting on the user, in those words. The whole value of this command is that they see the stop signs without reading for them.

1. **Phase and level, on the map.** Where the work is, at what scale, and what the eight steps are — so the answer is a position, not just a name. One line per step, current one marked, steps the level does not use marked as such:

   ```
     Brainstorm & architecture   done
     Business analysis           done
     System analysis             done
     UI/UX design                skipped — no user-facing surface
   > Build & QA                  HERE
     Security                    pending — review gate
     Documentation               pending — gate 5
     Deploy, monitor & operate   pending
   ```

   At Level 0 and 1 this collapses to a single line: most of the map does not apply, and printing eight rows to say so is the padding this command exists to avoid.

   **A step the user dropped is shown as dropped, with who dropped it** — `skipped by you` reads differently from `skipped — no user-facing surface`, and the difference is the whole point of having asked.
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
