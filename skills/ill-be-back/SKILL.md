---
name: ill-be-back
description: Start-of-session situation report - what happened last session, where the work stands, what is blocked, and a proposed set of priorities for the day offered as options to approve or redefine. Use when the user runs /ill-be-back, says "good morning", "what were we doing", "catch me up", "where did we leave off", "let's start", or opens a session on a project with work already in flight.
---

# /ill-be-back — situation report

You only command what you can see. This is the start-of-day briefing that puts the human back in command of a project they last touched days ago.

Four blocks, under a page, ending in a decision that is theirs to make.

## What to read

- `sarah/state.md` — the index: every task in flight and what each waits on.
- The task files in `sarah/state/` for the tasks that are actually moving — not all of them. A task nobody has touched in a week needs one line in the report, not a full read.
- The most recent one or two files in `sarah/changelog/` — what actually shipped.
- `git log --oneline -10` and `git status --short` — what really happened, which sometimes differs from what the state file says.

Nothing else. This is a briefing, not an audit. Reading the codebase to prepare a sitrep is how a thirty-second command becomes a five-minute one nobody runs.

## The four blocks

**1. Last session.** What was delivered, in two or three lines, from the changelog and the state file. Concrete: what changed, not "progress was made".

**2. Where things stand.** One line per task in flight: phase, level, and what it waits on. **A task waiting on the user for days is the report's headline**, not a row buried under the others — and with more than about five in flight, say that too, because too much in flight is itself the finding.

**3. Open and blocked.** Pending decisions with how long they have waited, blockers with what they wait on, and gates still open. If a decision has been pending for days, say how many — an aging decision is usually the real bottleneck, and nobody notices without the number.

Put this block in a table once there is more than one item. Three blockers in prose is three paragraphs somebody skims; three rows is three blockers somebody reads.

**4. Priorities for today — as options.** Two or three coherent plans for the day, not a task list. Each one says what it would accomplish and what it defers. Recommend one, with reasons.

Use `AskUserQuestion` for the fourth block. The user approves one, mixes them, or throws them out and states their own — and any of those is a success. This is the ask → options → approve protocol applied to the day itself.

## Reality check

When git shows commits the state file does not reflect, report the gap rather than the state file. Say it plainly: the state file says one thing, the repository says another, and here is which one to trust.

Same for uncommitted work sitting in the tree: someone stopped mid-thought last time, and that is usually the most important thing on the screen.

## What never happens here

- **No work starts.** Not even something small and obvious. The whole point is that the human sets the day's direction before anything moves.
- **No file is written.** `/hasta-la-vista` writes; this one reads.
- **No corporate report.** Under a page. This is an instrument of control, not a status meeting, and length is what kills the habit of running it.
- **No invented progress.** If the last session accomplished nothing, say nothing was accomplished.
