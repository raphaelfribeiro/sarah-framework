<!--
  TEMPLATE: implementation plan.

  Reproduce every heading verbatim and in order. Fill or delete. Strip every
  HTML comment from the generated file.

  This document exists to be approved before code is written, so it must be
  readable in a couple of minutes. A plan nobody finishes reading is a gate
  nobody actually passed.

  At Level 1 this collapses to a short list under one page - keep the Steps and
  Tests sections and drop the rest. At Level 0 there is no plan at all.
-->

# Plan — {{WHAT}}

**Date:** {{DATE}} · **Level:** {{1|2|3}} · **Spec:** {{link or "none - Level 1"}}

## Goal

<!-- One or two sentences. What is true after this that is not true now. -->

{{GOAL}}

## Steps

<!--
  Ordered, each naming the files it touches. Order matters: it is what makes the
  work reviewable in pieces and rewindable when a step goes wrong.

  If a step cannot be described in a line, it is more than one step.
-->

| # | Step | Files |
| --- | --- | --- |
| 1 | {{}} | `{{}}` |
| 2 | {{}} | `{{}}` |

## Tests

<!--
  The test plan, written with the implementation plan rather than after it. A
  test plan shaped after the design is a test plan shaped by the design, which
  is how tests end up confirming what the code does instead of what it should do.

  Depth follows the level: Level 2 is unit plus integration where the change
  touches a real boundary; Level 3 adds end to end on the critical flows.
-->

| Layer | What it covers | Where |
| --- | --- | --- |
| Unit | {{}} | `{{}}` |
| Integration | {{}} | `{{}}` |
| End to end | {{}} | `{{}}` |

**The first failing test:** {{which test gets written first, and what it asserts}}

**Deliberately not tested:** {{what, and why that is acceptable}}

## Risks

<!--
  What could go wrong, and what happens then. Not a ritual - only the risks that
  would actually change the approach if they materialized. If there are none
  worth naming, delete the section rather than padding it.
-->

| Risk | If it happens |
| --- | --- |
| {{}} | {{}} |

## Out of scope

<!--
  What this plan deliberately does not touch, including anything noticed while
  planning and left alone. Writing it here is what keeps it from being
  "fixed while I was in there" - the change that makes a review guesswork.
-->

- {{}}

## Documentation on completion

<!--
  The documentation gate for this level, decided now rather than remembered
  later. Level 0-1: state.md only. Level 2+: also ARCHI.md if architecture
  moved, README.md if anything user-visible changed, and a changelog entry.
-->

- [ ] `sarah/state.md`
- [ ] `ARCHI.md` — {{needed because ... | not needed}}
- [ ] `README.md` — {{needed because ... | not needed}}
- [ ] `sarah/changelog/` entry — {{required at Level 2+}}
