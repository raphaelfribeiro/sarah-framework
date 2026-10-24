---
name: hasta-la-vista
description: End-of-session debrief - what was delivered today, what is still open, then updates sarah/state.md and the changelog, verifies the documentation gate, and suggests a final commit. Use when the user runs /hasta-la-vista, says "that's it for today", "I'm done", "wrapping up", "let's stop here", "good night", or is clearly closing the session.
---

# /hasta-la-vista — debrief

The session that ends without a debrief is the session whose state file is wrong tomorrow.

**Write first, then report.**
- Each task touched today: `sarah/state/<slug>.md` (phase, in flight, blocked, gates, then `Next`, written last). Then `sarah/state.md`, one row per task, `Waiting on` current.
- A task that shipped loses its file and its row. Its entry in `sarah/changelog/` is the record: `# <title>`, then `**Date:** YYYY-MM-DD · **Level:** N · **Phase:** <phase>`, what changed and why, what is deliberately not done. One entry per delivery; none for a day without one.
- Decisions that still bind go into `sarah/decisions.md`: one dated line each, newest first, a "Permanent" exclusion under its own `## Permanent` heading. If the file is absent, create it with the first one.
- Delete exceptions older than 14 days. With a tracker connected, sync it silently and report failures only.

**Documentation gate.** Close the documentation gate for what shipped. Level 0-1: `sarah/state.md` current. Level 2+: also `ARCHI.md` if architecture moved, `README.md` if anything user-visible changed, and the changelog entry. Report what is missing; never fix it silently.

**Output.** No headings. At most 10 lines of about 110 characters, in this order, a line omitted when empty:
1. `Decision needed: <what>.` or `No decision needed. <why>.`
2. `Shipped:` what was delivered, the check run and its result. Code never run goes under Open.
3. `Open:` up to 3, each with what it waits on, readable with no memory of today.
4. `Decided today:` up to 3, each ending "Saved."
5. `Docs:` `Missing: <item>.` when the gate fails.

More than 2 items on a line: one short table. A day with no delivery: `No decision needed. Nothing shipped today; recorded as such.`

**Panel.** At most 2 questions. A missing doc: `Fix it now (Recommended)` or `Carry it to next time`. If files changed: `Commit the N changed files to <branch>?` with `Commit (Recommended)`, naming the message and "Not sent online", or `Leave them uncommitted`. Act on the answers, then sign off once: `Hasta la vista.` Nothing after it. Pushing is never part of the close.

**Never:** start new work, or record touched code as delivered.
