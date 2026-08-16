<!--
  TEMPLATE: sarah/state/<branch-slug>.md — one task.

  Created when work on a task starts, named after its branch so that the branch
  and its state travel together and no two tasks ever edit the same file.
  Deleted when the task ships: the changelog entry is the permanent record, and
  a directory of finished task files is a graveyard nobody reads.

  Strip every HTML comment from the generated file.
-->

# {{task, in one line}}

**Branch:** `{{feature/branch-name}}` · **Level:** {{0-3}} · **Phase:** {{phase}} · **Updated:** {{DATE}}

## Itinerary

<!--
  The steps the user chose for this task, and the ones they dropped. This is the
  record of a decision, so it names who made it: a step the level skipped reads
  differently from a step the user dropped, and only one of those is worth
  revisiting when something turns out to be missing.
-->

| Step | In | Why |
| --- | --- | --- |
| {{step}} | {{yes / no}} | {{reason, from this request — or "dropped by you"}} |

## In flight

<!-- What is actually happening on this task right now. Two or three lines. -->

## Blocked

<!-- What cannot move and what it waits on. Name the blocker, not the blocked thing. "Nothing blocked" is a complete answer. -->

## Pending decisions

<!--
  Choices waiting on the user, with the date they started waiting. The date is
  the point: a decision pending four days is usually the real bottleneck, and
  nobody notices without the number.
-->

| Decision | Options | Waiting since |
| --- | --- | --- |

## Gates

<!-- Only the gates this task's itinerary and level actually use. Listing gates marked n/a teaches people to skim. -->

| Gate | Status | When |
| --- | --- | --- |

## Next

<!-- Written for someone with no memory of today, because that is who reads it. -->
