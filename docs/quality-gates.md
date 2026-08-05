# Quality gates

Every gate has a guardian. Every merge has a human behind it.

A gate is a point where work stops until a condition is met. S.A.R.A.H. has five. They are written in imperative language on purpose: a gate phrased as a suggestion is not a gate, and the failure mode of every workflow framework is gates that quietly stop being enforced.

Each gate scales with the level. A gate that does not apply at a level is genuinely off, not performed as theatre — that is what keeps the ones that do apply credible.

---

## Gate 1 — Spec approved before architecting

**Applies at:** Level 2 and 3.

Nothing gets designed until the user has approved what is being built. A design against an unapproved spec is a bet on a guess, and the cost lands after the design has already shaped the code.

**Closes when:** the user says the spec is right, and every open question in it is resolved. A spec carrying open questions is not approved — it is a draft with an assumption hidden inside it.

**Level 1** collapses this into the plan: a paragraph and an acceptance criterion, approved together with the plan. **Level 0** has no spec.

---

## Gate 2 — Plan approved before implementing

**Applies at:** Level 1, 2 and 3.

**Do not implement without an approved plan.**

The plan names the files, the order of the work, and what could go wrong. At Level 1 it is a short list under a page. At Level 2 and above it comes from the implementation plan template, and it carries the test plan with it.

**Closes when:** the user approves both the implementation plan and the test plan.

**Why the test plan is part of this gate:** a test plan written after the implementation is a test plan shaped by the implementation. It confirms what the code does instead of checking what it should do, which is why retrofitted tests catch so little.

**Level 0** has no plan. That is the point of Level 0.

---

## Gate 3 — Test first

**Applies at:** Level 2 and 3.

**No production code without a failing test first. Wrote the code before the test? Delete it. Start over.**

That is meant literally. It reads as theatre and it is not: writing the test afterward produces a test shaped to pass the code that already exists.

**Closes when:** the test exists, has been run, and **failed for the right reason**. A test that was green before implementation has tested nothing, and confirming the failure is the step that actually gets skipped.

**At Level 0 and 1**, tests after the fact are acceptable when the user chooses that. Level 1 still gets a regression test for the bug being fixed — a bug fixed without a test guarding it comes back.

### The pyramid, by level

| Level | Unit | Integration | End to end |
| --- | --- | --- | --- |
| **0** | None | — | — |
| **1** | Changed behavior, plus a regression test | Only if the fix crosses a boundary | — |
| **2** | Always | Wherever the change touches a real boundary | — |
| **3** | Always | Every boundary the feature crosses | Critical user flows |

**Integration means a real boundary.** A test that mocks the database is a unit test wearing a costume: useful, but it cannot tell you the query is valid.

---

## Gate 4 — Review before merge

**Applies at:** Level 1, 2 and 3.

**Whoever writes the code never reviews it.**

This is the gate the framework leans on hardest. A reviewer who watched the implementation reason its way to an answer inherits its blind spots, and inherited blind spots are precisely what review exists to catch.

**Preferred:** adversarial review across models — one model implements, a different one reviews. A second model does not share the first one's failure modes, and the difference is largest on plans and designs rather than on line-by-line code.

**Fallback, and the normal path:** a fresh subagent with a clean context. S.A.R.A.H. detects a second-model CLI at runtime and offers it as an option when one exists. When none does, the subject never comes up. Both paths must be good; the framework is not degraded by having one model.

**Closes when:** the reviewer reports **pass**, or reports **changes required** and those items come back fixed and re-reviewed. The fixes get reviewed too.

**Every finding must carry a concrete failure scenario** — the input or state, and the wrong result that follows. A review that reports suspicions as defects stops being believed, and shortly after that it stops being run.

---

## Gate 5 — Documentation is part of done

**Applies at:** every level, proportionally.

**If it isn't documented, it isn't done.**

Documentation here is not a favour to a future reader. `ARCHI.md` is what the next task reads *instead of* the codebase, so letting it go stale does not merely lose information — it actively misleads the next piece of work.

| Level | Required before the merge gate closes |
| --- | --- |
| **0–1** | `sarah/state.md` updated. Nothing else. |
| **2–3** | `sarah/state.md`, plus: `ARCHI.md` if anything architectural moved; `README.md` if anything user-visible changed — how to run it, the stack, the features; and a short entry in `sarah/changelog/`. |

The Level 0–1 row is deliberately almost empty. A documentation gate that demands paperwork for a typo teaches everyone to route around the gate, and then it is not there when it matters.

**An out-of-date README is a defect**, not a chore. If a delivery changed how the project is run and the README still describes the old way, the delivery is not finished.

### The changelog entry

Five to ten lines per delivery, in `sarah/changelog/`:

```markdown
# <what was delivered>

**Date:** YYYY-MM-DD · **Level:** N · **Phase:** <phase>

What changed, why, and anything the next person needs to know.
Name what is deliberately not done.
```

These entries are what release notes are generated from. Writing them at merge time, while the work is fresh, is the only moment they are cheap.

---

## What gates are not

They are not approval theatre. A gate that always opens has stopped being a gate and become a delay, and everyone learns to treat it as one.

They are not the assistant's authority. Every gate closes because a **human** said so. S.A.R.A.H. reports, recommends, and refuses to proceed — it does not approve on the user's behalf.

The machines propose. The human decides. No exceptions.
