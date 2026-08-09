---
name: hasta-la-vista
description: End-of-session debrief - what was delivered today, what is still open, then updates sarah/state.md and the changelog, verifies the documentation gate, and suggests a final commit. Use when the user runs /hasta-la-vista, says "that's it for today", "I'm done", "wrapping up", "let's stop here", "good night", or is clearly closing the session.
---

# /hasta-la-vista — debrief

The session that ends without a debrief is the session whose state file is wrong tomorrow. This is where the day's work becomes something the next session can pick up.

Under a page, and it writes.

## 1. What was delivered

From `git log` since the session started, `git status --short`, and what actually happened in this conversation. Two or three lines, concrete.

Distinguish **delivered** from **touched**. Code written but never run is not delivered, and recording it as delivered is how a project's state file quietly becomes fiction.

## 2. What is still open

What was started and not finished, what is blocked, what decisions are still waiting. Where the next session should pick up — written for someone with no memory of today, because on Monday that is exactly who reads it.

A table once there is more than one open item, with what each one waits on. The person reading this is deciding where tomorrow starts, and a paragraph makes them extract the list themselves.

## 3. Update the state

Rewrite `sarah/state.md`: phase, level, in flight, blocked, pending decisions, gates, and the `Next` section. Write `Next` last and write it carefully — it is what `/ill-be-back` reads tomorrow to propose the day.

If something delivered today, add an entry to `sarah/changelog/`:

```markdown
# <what was delivered>

**Date:** YYYY-MM-DD · **Level:** N · **Phase:** <phase>

What changed, why, and anything the next person needs to know.
Name what is deliberately not done.
```

One entry per delivery, not one per session. A day with no delivery gets no entry, and that is a truthful record rather than a gap.

## 4. Check the documentation gate

For everything delivered today, at its level:

- **Level 0–1:** `sarah/state.md` current. Done.
- **Level 2+:** also `ARCHI.md` if anything architectural moved, `README.md` if anything user-visible changed, and the changelog entry.

**Report what is missing rather than quietly fixing it.** If the README should have changed and did not, say so — the user decides whether to fix it now or carry it. A gate that closes itself is not a gate.

If a tracker MCP is connected, offer to sync the cards. If none is connected, never mention it.

## 5. Suggest the commit

Propose a commit message for what is uncommitted. Suggest it; do not run it. Committing is the user's call, and so is pushing — which on a public repository means publishing.

Then sign off. Once, briefly.

## What never happens here

- **No new work.** Someone said they were done. Starting something is the opposite of listening.
- **No invented delivery.** A day that produced nothing is recorded as a day that produced nothing.
- **No corporate summary.** Under a page. If the debrief is long enough to skim, it will be skimmed, and then the state file rots anyway.
- **No silent fixing of the documentation gate.** Report it. The user decides.
