# The mirror that finally ran

**Date:** 2026-08-16 · **Level:** 1 · **Phase:** 7-release, tail

v0.1.0 reached the public repository. Everything in this entry is a measurement,
because every claim in it had previously been an assumption that turned out to
be wrong.

## What was actually verified

| Question | Answer | How |
| --- | --- | --- |
| Which refs does the mirror send? | heads and tags only | listed the refs on the far side |
| Did `refs/pull/*` carry the pre-rewrite objects across? | no | same listing, zero matches |
| Did the mirror error? | no | `last_error` empty after the sync |
| Does CI pass off this machine? | yes | `validate` green on the public side |
| Does the release pipeline work? | yes | both jobs green, release built from the changelog |

The first row is the one that mattered. Two `refs/pull/*` refs on the origin
still point at pre-rewrite commits carrying the redacted content, and the
options for removing them ranged from shell access on the host to rebuilding the
repository. **None of that was necessary, and the way to find out cost one
command.** The plan called for a throwaway probe first; the probe was blocked by
a token scope, and mirroring into a private repository answered the same
question with less setup and no disposable artefacts.

## The trap worth remembering

**A first push into an empty remote does not fire a release.** Every ref arrived
at once and the remote registered a workflow run for the default branch only —
nothing for the second branch, nothing for the tag, even though the workflow file
was present in the tag's own tree. Deleting the tag and pushing it again as an
isolated event ran the pipeline correctly.

It is an artefact of an empty repository, it does not recur, and that is exactly
why it will not be remembered the next time. Recorded in `docs/operating.md`
rather than here alone.

## Corrected

`sarah/state.md` said the mirror does not run and that a fix was owed.
`docs/operating.md` said the release pipeline had never executed anywhere. Both
were true when written this morning and stopped being true this afternoon. A
state file that describes yesterday is the specific failure that made this
morning's tag get pushed ahead of a branch that could not accept it.

## Not done

The two `refs/pull/*` refs still hold pre-rewrite objects on the origin. They are
staying: they do not travel, the origin is private, and removing them would cost
either host access or a repository rebuild. Recorded as accepted rather than
forgotten.
