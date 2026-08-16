# The release path that actually exists

**Date:** 2026-08-16 · **Level:** 1 · **Phase:** 7-release, tail

`v0.1.0` was cut, tagged, and then met a remote that does not work the way this
repository's own documentation says it does. Both discoveries are written down
here rather than remembered.

## What broke on the way out

**`main` refuses every direct push.** Branch protection on the origin has
`enable_push` false, which blocks administrators too — there is no whitelist to
be on. `docs/branching.md` prescribed `git checkout main && git merge --no-ff`
and stopped, so the documented release procedure could never have completed.

The tag went out before the branch did, so for a few minutes `v0.1.0` named a
commit no remote branch contained. Landed properly through a pull request merged
**fast-forward only**, which is the one merge style that moves `main` to the
existing commit instead of inventing a new one — so the already-published tag
stayed valid and nothing had to be moved or rewritten.

`docs/branching.md` now carries the full sequence, including the ordering: push
`develop` and the tag first, because the pull request is the slow step.

**The mirror has never run.** It points at the repository's pre-rename name, and
has been failing every eight hours since 2026-08-05 with `Repository not found`,
reporting it nowhere but its own settings page. Nothing external has received a
single commit, and the Quickstart the README teaches resolves to nothing.

The 2026-08-05 rename decision closed with *"no versioned file changed: every URL
already used that name."* That was true, and it was the one **unversioned** URL
that mattered.

## Why this is the same defect six times

The state file already catalogues five instruments that could not report they had
not measured: a sanitizer, a harness, a counter, a probe, a recovery step. This
is the sixth, and the first outside the study — a component that fails on
schedule and tells only itself.

The consequence was not the broken mirror. It was that `sarah/state.md` had been
asserting *"it mirrors automatically, so a push is a publish"* for eleven days as
though it were a fact, and that assertion is what made pushing a tag ahead of a
branch look safe. **An unverified claim in the state file is worse than an
absent one**, because the state file is what the next session trusts instead of
looking.

## Changed

- `docs/branching.md` — the release flow through a protected `main`, and why
  fast-forward-only is the only acceptable merge style for it.
- `docs/operating.md` — the same, plus the mirror stated as a claim to verify at
  release time rather than a fact, plus the admission that the `release`
  workflow has never executed anywhere. Its steps were exercised locally,
  including against a deliberately wrong tag. That is not the same thing.
- `sarah/state.md` — Publication corrected, the mirror recorded as the one thing
  owed, and the six-of-a-kind noted where the next session will read it.

## Not done

Repointing the mirror. It is a settings change on the origin, outside this
repository, and it is the maintainer's to make.
