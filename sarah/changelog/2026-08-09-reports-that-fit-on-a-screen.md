# Reports that fit on a screen

**Date:** 2026-08-09 · **Level:** 2 · **Phase:** 5-implement → 6-review

The maintainer asked for objective reporting after a session in which the
framework produced exactly the wall of prose it warns against.

**The diagnosis was not what it looked like.** The rule already existed:
`ill-be-back` says "under a page", `sarah-status` says "no padding",
`code-reviewer` says "do not pad the review". All of it held in writing and none
of it held in practice. What was missing was **form**. Where no shape is
prescribed, text grows to fill the space, and "be concise" is exhortation — the
kind that had already failed.

## What changed

Verdict or answer first. A table once there is more than one of anything. Detail
only where an action depends on it. Applied to both reviewing agents,
`sarah-phase-review`'s reporting step, `sarah-status`, `ill-be-back`,
`hasta-la-vista`, and one line in `sarah-bootstrap` — which is injected into
every session and therefore reaches everything, at a cost of roughly 84 tokens
against a 2,000 ceiling.

Two rules earned their place beyond shape. **A reviewer's search path is not
evidence; the reproduction is** — that is the specific habit that made this
session's reports long. And **when one reviewer calls a finding blocking and the
other calls it optional, both go in the row with who said which**: on 2026-08-09
the two reviewers split exactly that way on the UTF-16 gap, and the split was
the most useful thing either of them produced.

## What the review caught, twice

Both rounds blocked, and both findings were self-inflicted by the same mechanism:
**two edits in one commit that were never checked against each other.**

Round one: rewriting `code-reviewer`'s reporting section deleted "say which
findings block and which are optional" without putting it back. Round two:
renaming the table's column to `blocking or optional` while, two paragraphs
below, adding a rule about reviewers disagreeing on *severity* — a value the
table no longer carried and the code reviewer never emitted.

**The reviewer ran under the instructions it was reviewing**, which is the only
way round one could have been found: it hit the gap live, had to invent a
blocking judgment because nothing told it whether severity carried that meaning,
and reported that as both a finding and an experience. Static reading would not
have produced it.

## Verified

`claude plugin validate . --strict` passes. No `description` frontmatter changed,
so no skill's triggering is affected. All bodies far under the 500-line ceiling.
`sarah-bootstrap` measures ~1,658 tokens against its 2,000 budget by the CI's own
chars/4 measure.

The final vocabulary fix — unifying `blocking or acceptable risk` into
`blocking or optional` so the two agents feed the consolidation step the same
values — was made after the second review and has not itself been reviewed. It
is a three-line substitution with no new instruction, and it is recorded here
rather than left implicit.
