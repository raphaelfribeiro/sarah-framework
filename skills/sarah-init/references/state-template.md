<!--
  TEMPLATE: sarah/state.md — the index.

  /sarah-init copies this to sarah/state.md. Strip every HTML comment from the
  generated file.

  This file answers one question: what is in flight, and what is each piece
  waiting on. It holds NO task detail. A task's own state lives in
  sarah/state/<branch-slug>.md, created when the work starts and deleted when it
  ships — the changelog entry is the permanent record, so keeping finished task
  files here only builds a graveyard.

  Why the split: this file used to hold one task, and it is rewritten
  continuously and versioned. Two branches meant two divergent copies and a
  conflict at every merge. Now each branch edits only its own file.

  Keep this under half a page. If it grows, it is holding something that belongs
  in a task file, in ARCHI.md, or in the changelog.
-->

# S.A.R.A.H. state

**Updated:** {{DATE}}

| | |
| --- | --- |
| **Default level** | {{0 \| 1 \| 2 \| 3}} |
| **Mode** | {{greenfield \| brownfield}} |

## In flight

<!--
  One row per task with a file in sarah/state/. Empty is a healthy answer —
  write "Nothing in flight" and nothing else.

  "Waiting on" is the column that matters: it is where a reader finds work that
  has stopped. Name the person or the thing, not the state. "You, since
  2026-08-12" beats "blocked".

  Past five rows, say so once. More in flight than a person can hold is worth a
  sentence, not a policy.
-->

| Task | File | Phase | Level | Waiting on | Since |
| --- | --- | --- | --- | --- | --- |
| {{one line}} | `sarah/state/{{slug}}.md` | {{phase}} | {{0-3}} | {{you / CI / nobody}} | {{DATE}} |

## Carried forward

<!--
  What the project learned that outlives any single task: constraints discovered
  the hard way, decisions that keep being re-litigated, traps someone already
  fell into. This survives every task file that comes and goes.

  Not a diary. If nobody would change a decision because of it, it does not
  belong here.
-->

- {{a lesson, a constraint, or a trap — with the consequence that makes it matter}}
