<!--
  TEMPLATE: delta-spec, brownfield.

  Reproduce every heading verbatim and in order. Fill or delete. Strip every
  HTML comment from the generated file.

  A delta-spec describes the change, never the system. Everything not mentioned
  here is unchanged, and that omission is the whole point: it keeps the document
  small enough to stay true. The system itself is described in ARCHI.md, and
  this document anchors to it rather than restating it.

  Never write a full specification of an existing system to justify a change to
  part of it. That produces a document too large to maintain, which rots and is
  then trusted anyway.
-->

# Delta spec — {{CHANGE_NAME}}

**Date:** {{DATE}} · **Level:** {{1|2|3}} · **Status:** {{draft|approved}}

## Context

<!--
  What in the existing system this touches, and why the change is wanted. Link
  to the ARCHI.md sections it anchors to rather than repeating them.
-->

{{CONTEXT}}

Anchors to: {{`ARCHI.md` §3 System shape, §5 Boundaries}}

## ADDED Requirements

<!-- New behavior that does not exist today. Delete the section if there is none. -->

### R1 — {{name}}

{{What must be true.}}

**Accepted when:**
- {{Observable condition.}}

## MODIFIED Requirements

<!--
  Behavior that exists and changes. State both sides: what it does today and
  what it will do. A modification written only as its new state is unreviewable,
  because nobody can see what was given up.
-->

### R2 — {{name}}

**Today:** {{current behavior}}
**Becomes:** {{new behavior}}

**Accepted when:**
- {{Observable condition.}}

## REMOVED Requirements

<!--
  Behavior going away. Say what happens to anything that depends on it - callers,
  stored data, existing users mid-flow. Removal without a migration answer is
  how a change breaks something nobody was thinking about.
-->

### R3 — {{name}}

**Removed:** {{what goes away}}
**Depends on it:** {{who or what, and what happens to them}}

## Unchanged but affected

<!--
  Parts that keep their behavior while running on changed ground. These are the
  regression risks, and naming them here is what makes them get tested.
-->

- {{Component or behavior}} — {{why it is exposed to this change}}

## Edge cases and failure behavior

| Case | Expected behavior |
| --- | --- |
| {{}} | {{}} |

## Open questions

<!-- Must be empty before approval. Delete the section when it is. -->

| Question | Blocks | Options on the table |
| --- | --- | --- |
| {{}} | {{}} | {{}} |
