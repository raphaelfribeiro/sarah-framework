<!--
  TEMPLATE: architecture decision record.

  Reproduce every heading verbatim and in order. Fill or delete. Strip every
  HTML comment from the generated file.

  One decision per record. Numbered sequentially, never renumbered, never
  deleted - a decision that was reversed is superseded, not erased, because the
  reasoning that led to it is exactly what stops it being made again by
  accident.

  Write an ADR when reversing the decision would be expensive, or when the next
  person would otherwise be tempted to undo it without knowing why it exists.
  Not every choice earns one; a record for every preference makes the set
  worthless.

  File as docs/adr/NNN-short-slug.md, and add a one-line entry to the ARCHI.md
  decisions table pointing here.
-->

# ADR-{{NNN}} — {{TITLE}}

**Date:** {{DATE}} · **Status:** {{proposed|accepted|superseded by ADR-NNN}}

## Context

<!--
  The forces in play at the time. What the constraints were, what was already
  decided, what was unknown. Write for a reader two years from now who has none
  of today's context and is wondering what you were thinking.

  Include the constraints that were true then even if they are false now. That
  is what tells a future reader whether the decision still holds.
-->

{{CONTEXT}}

## Options considered

<!--
  The real alternatives, with honest trade-offs. An ADR listing one option is
  not a decision record, it is a justification - and it hides the fact that the
  alternatives were never weighed.
-->

### {{Option A}}

- **Makes easy:** {{}}
- **Makes hard:** {{}}
- **Cost to reverse:** {{}}

### {{Option B}}

- **Makes easy:** {{}}
- **Makes hard:** {{}}
- **Cost to reverse:** {{}}

## Decision

<!-- What was chosen, and the reason that actually drove it. One paragraph. -->

{{DECISION}}

## Consequences

<!--
  What follows, good and bad. The bad ones are the point: an ADR that lists only
  benefits is marketing. Name what this makes harder, what it commits the
  project to, and what has to stay true for it to keep being right.
-->

- {{Consequence.}}
- {{Consequence, including the ones that hurt.}}

## Revisit when

<!--
  The condition that would make this worth reopening - a scale threshold, a
  dependency change, a constraint expiring. Optional, but it is what turns a
  decision into something reviewable instead of permanent by default.
-->

{{CONDITION}}
