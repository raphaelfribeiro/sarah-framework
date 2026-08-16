# v0.1.0, and the pipeline that will not tag without checking

**Date:** 2026-08-16 · **Level:** 3 · **Phase:** 7-release

Twenty deliveries sat in `sarah/changelog/` and `main` had not moved since
2026-08-05. Both manifests already said `0.1.0`; no tag had ever existed. The
version follows from that with no argument to have: this is the first release,
nothing was ever published, so nothing can break.

## What shipped besides the tag

**`CHANGELOG.md` became the release notes.** The `[Unreleased]` section still
described Phase A alone, eleven days and nineteen deliveries out of date. It now
carries a `[0.1.0]` section written for someone deciding whether to install —
what the framework does, and a **Known limits** block that leads with the study
result: on a well-specified brief S.A.R.A.H. does not make Claude write better
code, 20.7/48 against 19.7 at 21% more cost. A limit found after installing is
the worst release note failure available.

**`docs/operating.md`** answers gate 5's observe-and-reverse requirement for a
thing that has no server. There is no telemetry and that is deliberate; the four
signals are CI on the tag, CI on `main`, the plugin loading, and issues. The
file states plainly what none of them cover — whether a skill *fires* is
behavioural, measurable only by a recorded run against a fresh project, and that
is not automated. Structural green is necessary, never sufficient. The rollback
is written down, including that **v0.1.0 has no predecessor**, so the way back is
uninstalling.

**`.github/workflows/release.yml`** fires on `v*` and refuses to publish a tag
that has not earned it: the manifests must agree with the tag, and the changelog
must have a section for it, or the release stops. Notes are extracted from
`CHANGELOG.md`, never generated.

## The one design decision in it

`release.yml` does not repeat the guards. It calls `validate.yml` through
`workflow_call`, so the tag runs the same file every branch runs.

That is round 5 of the packager review, applied before it could happen again:
two expressions meant to agree, diverging, and no gate able to see it because
each one passed on its own. The fix there was not another check — it was
defining the expression once. A second copy of the guards, aging in a file that
runs only on release day, is that defect waiting for the worst possible moment.

## Verification

Every CI guard was run locally before the branch was cut, and both new guards
were run against a deliberately wrong tag to confirm they fail: `v9.9.9` was
rejected by the manifest check, and a missing changelog section was rejected by
the notes check. A guard that has never been seen to fail is not known to work —
this repository has learned that four separate times.

## Deliberately not done

No installation smoke test. The only signal that would prove the plugin loads
from a tag is installing it in a clean Claude Code, and that needs CLI
authentication on a runner. Recorded as the gap it is, not closed.
