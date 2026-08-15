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

   **Bring the not-tested list with it.** The implement phase produces one, with
   a reason and a compensating control for each gap. It arrives here because a
   gap only counts as accepted once a human has seen it — an untested edge that
   was never surfaced is not a decision, it is an omission with a paper trail.
   If the change has no such list, that absence is the first finding.
2. **Spawn the `code-reviewer`** in a clean context with the diff and the plan.
3. **Spawn the `security-advisor`** in parallel when the change touches auth, secrets, input handling, personal data, or an external boundary.
4. **Probe, do not only read.** Reviewers write throwaway scripts that call the
   code with hostile input and observe what it does. Reading finds design
   mistakes; only execution finds the ones that live in a missing `except`.
   Feed every parser the values that break parsers — empty, enormous, negative,
   `inf`, `nan`, deeply nested, wrong type, duplicate keys — and every path
   handler the ones that break paths. **A crash on unauthenticated input is a
   security finding, not a robustness nit.**
5. **Rehearse the cold start.** Clone into a fresh directory, build a clean
   environment, and follow the README exactly as a stranger would, running every
   command it prints. Instructions that do not work are a defect of the same
   rank as a broken test, and they are invisible to anyone reading the repository
   they already have. Nothing else in this framework catches them.
6. **Verify before reporting.** Every finding needs a concrete failure: the input or state, and the wrong result that follows. No scenario, no finding — a review that reports suspicions as defects stops being believed, and then it stops working.
7. **Report ranked**, most severe first, marking which findings block and which are optional. Forcing the author to guess which is which wastes the review.

   **Consolidate before you report.** Two reviewers produce two reports; the
   human needs one. Merge them into a single table — finding, **blocking or
   optional**, who found it — and say when both found the same defect
   independently, because that is the strongest signal a review produces. Then
   the detail a fix needs, and nothing about how the search went. End by naming
   what the human has to decide, if anything. A review that buries its verdict
   in prose has done the work and thrown away the delivery.

   **When one reviewer calls a finding blocking and the other calls it
   optional, put both in the row and say who said which.** Do not pick one.
   Two specialists splitting on whether a thing ships is a finding about the
   change, and resolving it quietly destroys the only information a second
   reviewer was there to produce. It is also the human's call, not the
   consolidator's — the split is what they need to see.

**Read narrowly.** Pull the diff and the files it touches, and pipe long command
output through `tail` or `grep` rather than swallowing it whole. A reviewer that
re-reads the entire repository spends its budget on rediscovery instead of on
finding defects.

## What you never do

- Let the implementer review the implementation.
- Report style preferences as defects. That is the linter's job.
- Pad the review. Ten trivia items bury the one real bug.
- Approve to be agreeable.
- Merge. You report; the human decides.
- **Pass a change whose README you did not run.** Documentation that has never
  been executed is a claim, and this gate exists to stop claims reaching a user.
- **Accept a test seam that ships in production.** A hook, global, or flag that
  exists only so a test can reach inside is a defect in the delivery: it is
  reachable at runtime by anything, not just the test. Say so and send it back.

## Gate 4 — review passed

**Pass**, or **changes required** with specific blocking items.

Changes required means back to `sarah-phase-implement` for those items, then review again — the fixes get reviewed too.

**Present the not-tested list to the human before the gate closes**, each entry
with its reason and what covers it instead. They accept it, or they send an
entry back for a test. Reporting it as reviewed without that answer defeats the
purpose of carrying it here.

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
