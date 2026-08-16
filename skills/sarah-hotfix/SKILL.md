---
name: sarah-hotfix
description: Production is broken and the fix cannot wait for the normal pipeline. Skips gates deliberately, records exactly which ones and why, and creates the debt to pay back afterward. Use when the user says "production is down", "urgent", "hotfix", "emergency", "customers are affected", "rollback", or describes a live failure that needs fixing now.
---

# Hotfix — the emergency path

Production is broken. Normal process is the wrong tool right now, and pretending otherwise costs the user real money while a specification gets written.

This skill exists so that skipping gates is a **deliberate, recorded act** rather than a quiet erosion. A framework with no emergency path does not stop emergencies — it just gets abandoned during them, along with everything else it was enforcing.

## First: is rollback faster?

Ask this before anything else. If the last known-good version can be redeployed in less time than a fix takes to write, roll back first and fix afterward with the pressure off.

A fix written under pressure is the fix most likely to be wrong, and it is being applied to the system where being wrong is most expensive right now.

## Stabilize, then diagnose, then fix

1. **Stop the bleeding.** Rollback, feature flag, disable the endpoint, scale up. Reducing harm buys the time to think.
2. **Diagnose from evidence.** Logs, traces, the actual error, what changed recently. Do not guess and deploy — a wrong hotfix makes the incident longer and the next diagnosis harder, because now two things are different.
3. **The narrowest fix that works.** Not the right fix, not the clean fix. The smallest change that stops the harm. The right fix comes later, with a plan and a review.
4. **Verify it worked.** In production, against real evidence. An incident closed on the belief that the fix worked is an incident that reopens at a worse hour.

## Which gates are skipped

Say it out loud, at the time:

| Gate | In a hotfix |
| --- | --- |
| Spec | Skipped. The spec is "stop this". |
| Plan | One or two lines, stated before acting. Not skipped — spoken. |
| Test first | Usually skipped. **A regression test comes after**, and it is not optional. |
| Review | **Not skipped.** Shortened. Even sixty seconds of fresh eyes on a production change catches the second-order damage that panic causes. |
| Documentation | Deferred to the debt entry below, not dropped. |

**Review is the one that survives.** Everything else here is about speed; that one is about not making the incident worse, which is the actual risk in the moment.

## Record the debt

Before this is over, write to `sarah/changelog/`:

```markdown
# HOTFIX — <what broke>

**Date:** YYYY-MM-DD · **Level:** hotfix

**What broke:** <symptom, who was affected, for how long>
**Root cause:** <or "not yet known" - never a guess dressed as a fact>
**The fix:** <the narrow change that was made>

**Gates skipped:** <which ones, and why>
**Owed:** <regression test, proper fix, ARCHI.md update, post-mortem>
```

Then update the task's file in `sarah/state/` with the outstanding items as blocked work.

**A hotfix that leaves no debt entry is how a codebase fills with changes nobody can explain.** Six months later the narrow fix is load-bearing and nobody knows why it exists.

## Afterward

Once production is stable, the owed work becomes an ordinary task at its proper level: the regression test that would have caught this, the real fix if the narrow one was a patch, and the `ARCHI.md` update if the incident revealed something about the system that its map does not say.

Bring it back to the user as a normal piece of work, with the debt entry as its input. Do not let it disappear because the pressure is off — that is exactly when it disappears.

## What never happens here

- **Deploying a guess.** Diagnose first, even when the diagnosis takes ten minutes.
- **Widening the fix.** Notice something else wrong, write it in the debt entry, leave it.
- **Skipping the review** because it is urgent.
- **Closing without a debt entry.**
