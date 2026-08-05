<!--
  TEMPLATE: specification, greenfield.

  Reproduce every heading verbatim and in order. Fill the placeholders or delete
  the section. Strip every HTML comment from the generated file.

  Size is proportional to the work: a Level 2 spec is about a page, a Level 3
  spec is as long as it needs to be and no longer. If this document is longer
  than the thing it describes is complex, it will not be read, and an unread
  spec is worse than none because everyone assumes it was followed.

  For an existing system, use delta-spec-template.md instead.
-->

# Spec — {{FEATURE_NAME}}

**Date:** {{DATE}} · **Level:** {{2|3}} · **Status:** {{draft|approved}}

## Problem

<!-- What is wrong today, for whom. Two or three sentences. Not the solution. -->

{{PROBLEM}}

## Requirements

<!--
  Each requirement is an observable outcome with acceptance criteria. If nobody
  can tell whether it is met, it is a wish - rewrite it or drop it.

  Number them. Later documents, plans, and reviews will refer to these numbers.
-->

### R1 — {{name}}

{{What must be true.}}

**Accepted when:**
- {{Observable condition.}}
- {{Observable condition.}}

### R2 — {{name}}

{{...}}

## Out of scope

<!--
  Explicit exclusions, in writing. This section prevents more scope creep than
  every other section combined, because an unwritten exclusion is not an
  exclusion - it is a disagreement waiting to happen.
-->

- {{What this deliberately does not do, and why.}}

## Edge cases and failure behavior

<!--
  Where specifications usually go quiet, and where production actually lives.
  Empty, none, one, many, duplicate, out of order, unauthorized, unavailable,
  concurrent - plus whatever this domain does at its own limits.
-->

| Case | Expected behavior |
| --- | --- |
| {{}} | {{}} |

## Open questions

<!--
  A spec with open questions is not finished. List them here rather than
  resolving them with a plausible assumption; each one is a stop sign for the
  work that depends on it.

  Delete this section when it is empty - and it must be empty before approval.
-->

| Question | Blocks | Options on the table |
| --- | --- | --- |
| {{}} | {{}} | {{}} |
