# The pre-push guard survives a clone

**Date:** 2026-08-10 · **Level:** 1 · **Phase:** 5-implement

The guard that stops this repository's internal origin from reaching the public
mirror lived in `.git/hooks`, which git does not version. It protected exactly
one machine and said nothing about its own absence anywhere else. The failure
mode is quiet: a fresh clone pushes freely, and nobody finds out until the
mirror has already synced.

## What changed

The hook moved to `.githooks/` and is enabled per clone with
`git config core.hooksPath .githooks`. That step is manual, and `CONTRIBUTING.md`
says so plainly — git offers no way for a repository to install its own hooks,
and implying otherwise would be worse than the current honesty.

Two changes travelled with the move. The hook now excludes **itself and the CI
workflow** from its own content scan: both files necessarily spell out the terms
they hunt for, so without the exclusion the guard fires on itself, and that false
positive teaches nothing except how to bypass the check. The CI workflow excludes
the hook for the same reason, and its comment now names both files rather than
one.

## Accepted risk

Unchanged in kind, slightly wider in surface: a real reference added inside
either of those two files is invisible to both guards. Recorded so a later round
does not rediscover it as new.

## Verified

`shellcheck` clean. The guard was confirmed to still block by pushing a
deliberate leak through it before the commit was finalised.
