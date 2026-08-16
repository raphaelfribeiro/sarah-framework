# A guard that cannot spell what it hides

**Date:** 2026-08-16 · **Level:** 2 · **Phase:** 5-implement → 7-release

Found while preparing to mirror the repository publicly for the first time.

The guard that kept private infrastructure out of a public repository **was a
denylist, so it contained the names**. It ran `grep -rniE '<three names>'` from
`.github/workflows/validate.yml`, and `.githooks/pre-push` ran the same
expression before a push. Both are versioned. Both would have been published.
The guard was the leak.

It also had to exclude itself and the workflow from its own search, or it would
fire on its own source — leaving exactly two files in which a real reference was
invisible to it. That exclusion was documented as an accepted risk. It was the
same risk twice.

## Written by exclusion instead

`scripts/allowed-hosts.txt` lists the hosts this repository **is allowed to
name**. Nine of them. Anything else fails, whether or not anybody predicted it.
The list cannot leak what it does not contain, so the guard now searches
everything with no exclusions at all — including itself.

The list is a file rather than a literal in each guard, because two copies of one
list are two lists. That is round 5 of the packager review again, and the third
time this repository has applied it deliberately rather than after a failure.

Verified both directions: the tree passes, and a planted
`https://<host>.<private-tld>` is caught twice over — once as an unlisted host,
once by the bare-hostname rule. A filename like `settings.local.json` does not
false-positive, because the rule requires the suffix to end rather than continue
into another dotted component.

## What an allowlist cannot do, and what covers it

A host allowlist catches machines. It cannot catch a **bare word** — a product or
network name written as prose, with no domain attached. Tested and confirmed:
against the exact commit that leaks, the new guard passed.

Those terms cannot be versioned here without recreating the original defect, so
they live in `.private-terms` at the repository root, gitignored and never
committed. The pre-push hook reads it when present and searches both content and
commit messages with it.

**When it is absent, the hook says so on every push.** That line is the point of
the design. The sixth instrument failure recorded in `sarah/state.md` this
morning was a component that failed on schedule and told only itself; a local
guard that is simply missing in a fresh clone is the same failure with better
manners. It now reports its own coverage, and an absent list is visible rather
than assumed.

## Also fixed

Commit messages were checked against a different, narrower pattern than file
content, so a hostname in a message could pass where the same text in a file
would not. Both now run the same rules. This repository has one commit message
that proves the gap was real.

## Deliberately not done

CI cannot check `.private-terms`, because CI runs after publication and the file
is not published. The pre-push hook is the only gate for that class, and it is
opt-in per clone. Stated rather than solved.
