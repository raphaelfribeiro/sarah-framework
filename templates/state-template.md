<!--
  TEMPLATE: sarah/state.md — workflow state.

  /sarah-init copies this to sarah/state.md. Strip every HTML comment from the
  generated file.

  This file is read at the start of every session and updated at the end of
  every one. It is deliberately small: it holds where the work stands, not what
  the work is. Architecture lives in ARCHI.md, delivered work lives in
  sarah/changelog/, and requirements live in specs.

  Keep it under a page. If it grows past that, something in it belongs
  somewhere else.
-->

# S.A.R.A.H. state

**Updated:** {{DATE}}

| | |
| --- | --- |
| **Phase** | {{1-brainstorm \| 2-spec \| 3-architecture \| 4-design-ux \| 5-implement \| 6-review \| 7-release \| idle}} |
| **Default level** | {{0 \| 1 \| 2 \| 3}} |
| **Mode** | {{greenfield \| brownfield}} |
| **Current task** | {{one line, or "none"}} |
| **Task level** | {{0-3, when it differs from the default}} |

## In flight

<!--
  What is actually being worked on right now. One line each. Empty is a valid
  and healthy state - say "nothing in flight" rather than leaving it blank.
-->

- {{}}

## Blocked

<!--
  Anything that cannot move, and what it is waiting on. Name the blocker, not
  just the blocked thing: "waiting on the user to choose a CI provider" is
  actionable, "CI setup blocked" is not.
-->

- {{}}

## Pending decisions

<!--
  Choices presented to the user that have not been answered yet. Each one is a
  stop sign: work that depends on it does not proceed on an assumption.
-->

| Decision | Options on the table | Waiting since |
| --- | --- | --- |
| {{}} | {{}} | {{}} |

## Gates

<!--
  The approval trail for the current task. A gate is passed only when the user
  said so. Delete rows that do not apply at this level: Level 0-1 work does not
  need a spec gate, and pretending otherwise trains everyone to ignore the
  table.
-->

| Gate | Status | When |
| --- | --- | --- |
| Spec approved | {{pending \| approved \| n/a}} | {{}} |
| Plan approved | {{pending \| approved \| n/a}} | {{}} |
| Tests written first | {{pending \| done \| n/a}} | {{}} |
| Review passed | {{pending \| passed \| n/a}} | {{}} |
| Documentation done | {{pending \| done}} | {{}} |

## Next

<!--
  The two or three things that come next, in order. This is what /ill-be-back
  reads to propose the day's priorities, so write it for a reader who has lost
  all context - including you, on Monday.
-->

1. {{}}
