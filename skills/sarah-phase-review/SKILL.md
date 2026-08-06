---
name: sarah-phase-review
description: Review a change before merge with fresh eyes that never saw it written. Runs correctness and security review in a clean context, verifies each finding, and reports a pass or blocking changes. Use when the user says "review this", "is this ready to merge", "check my code", before any merge or pull request, or immediately after implementation finishes. Never let the author review their own work.
---

# Phase 6 — Review

**Whoever writes the code never reviews it.** This is the gate the whole framework leans on, and it is worth nothing if it always opens.

## When this phase applies

| Level | Applies |
| --- | --- |
| **0** | No. |
| **1** | Yes. Reviewer only; security only if the change touches their surface. |
| **2** | Yes. Reviewer plus security advisor. |
| **3** | Yes. Reviewer plus security advisor, on every change. |

## Who works this phase

**Code Reviewer** and **Security Advisor**, both in fresh contexts.

The fresh context is the entire mechanism. A reviewer who watched the implementation reason its way to an answer inherits its blind spots, and inherited blind spots are exactly what a review is for.

## Choosing the reviewing model

S.A.R.A.H. prefers an adversarial review across models: one model implements, a different one reviews. A second model does not share the first one's blind spots, and the difference shows up most on plans and designs rather than on line-by-line code.

**At the start of this phase, check what is available:**

```bash
for c in codex gemini llm aider cursor-agent; do command -v "$c" >/dev/null 2>&1 && echo "found: $c"; done
```

- **Something found** — offer it as an option with its trade-off: an independent model catches what a same-model reviewer will not, at the cost of a second tool in the loop and its own token spend. The user decides. Never invoke an external CLI without asking.
- **Nothing found** — say nothing about it, and review with a fresh subagent. This is the normal path, not a degraded one, and it must be good on its own.

> Runtime detection of a second model ships unexercised in v0.1: the framework's own maintainer runs Claude only, so this branch is written but never executed here. Treat it as untested until a contributor with a second CLI reports otherwise. The fresh-subagent path is tested on every review.

## When no independent reviewer can run

Sometimes neither path is available: subagents are disabled or refused in this session, and no second-model CLI exists. This is not a rare edge — a permission setting is enough to cause it.

**The gate does not dissolve because a tool was unavailable.** A gate that silently downgrades whenever it is inconvenient stops being a gate on exactly the day it matters.

Do this, in order:

1. **Stop and say so, before reviewing anything.** Name what is unavailable and why the independent path failed.
2. **Offer the ways out**, and let the user pick:
   - Enable subagents for this session, then review properly. Recommend this one — it is usually a single setting, and it restores the gate rather than working around it.
   - Review in a separate, clean session started by the user, with the diff and the plan as the only input.
   - Proceed with a self-review, **accepted explicitly by the user as a known gap**.
3. **If the user accepts a self-review**, do it honestly and label it for what it is. Record in `sarah/state.md` that gate 4 was not satisfied for this change, and say so again at merge and in the changelog entry. A gap that is written down can be paid off later; a gap that was mentioned once in a conversation is simply lost.

Never report a self-review as a passed review. The author checking their own work is a useful habit and is not this gate — the whole mechanism is the reviewer not having watched the author reason.

## How it runs

1. **Assemble what changed.** The diff, the approved plan, and the acceptance criteria. The reviewer needs the plan to detect drift from it.
2. **Spawn the `code-reviewer`** in a clean context with the diff and the plan.
3. **Spawn the `security-advisor`** in parallel when the change touches auth, secrets, input handling, personal data, or an external boundary.
4. **Verify before reporting.** Every finding needs a concrete failure: the input or state, and the wrong result that follows. No scenario, no finding — a review that reports suspicions as defects stops being believed, and then it stops working.
5. **Report ranked**, most severe first, marking which findings block and which are optional. Forcing the author to guess which is which wastes the review.

## What you never do

- Let the implementer review the implementation.
- Report style preferences as defects. That is the linter's job.
- Pad the review. Ten trivia items bury the one real bug.
- Approve to be agreeable.
- Merge. You report; the human decides.

## Exit gate

**Pass**, or **changes required** with specific blocking items.

Changes required means back to `sarah-phase-implement` for those items, then review again — the fixes get reviewed too.

On a pass, the documentation gate must also be closed before merge:

- **Level 0–1:** `sarah/state.md` current.
- **Level 2+:** also `ARCHI.md` if architecture moved, `README.md` if anything user-visible changed, and an entry in `sarah/changelog/`.

Review fixes are commits of their own, on the same feature branch — never
amended into the commits under review, which would erase what the reviewer
caught.

Once the gate closes, the delivery goes to the permanent branch **the way the
project's branching model says**: under gitflow, a pull request into `develop`.
The pull request is the delivery boundary, and a human merges it.

If a tracker MCP is connected, offer to sync the card or issue — as an option, never automatically. If none is connected, never mention it.

Every gate has a guardian. Every merge has a human behind it.
