# Operating a release

Gate 5 does not close on a release that cannot be **observed and reversed**. This
file is that requirement, answered for what S.A.R.A.H. actually is: prose a model
reads, distributed as a Claude Code plugin, running inside someone else's
session.

Most of what a Level 3 release usually gets — golden-signal dashboards, alerts
with thresholds — would be theatre here. There is no service, no request rate,
no latency. What follows is the honest version of the same discipline.

## What a release is

A tag on `main`. There is no deploy step and no server.

```sh
git checkout -b release/X.Y.Z develop
# version bumps in both manifests, CHANGELOG, release notes - no new features
git checkout main
git merge --no-ff release/X.Y.Z
git tag -a vX.Y.Z -m "..."
git checkout develop
git merge --no-ff release/X.Y.Z     # back-merge, never skip
```

Pushing is what publishes it, and it is a decision rather than a step. Two
things about this origin that the commands above do not show, both learned by
running into them:

- **`main` refuses every direct push**, administrators included, so the local
  merge lands through a pull request merged **fast-forward only**. Any other
  merge style leaves the tag naming a commit `main` does not contain. The full
  sequence is in [branching.md](branching.md).
- **The mirror is not a guarantee.** A push-mirror can be configured, run on
  schedule, fail every time, and report that only inside its own settings page.
  Ours did exactly that for eleven days after the repository was renamed, and
  the state file repeated "it mirrors automatically" as a fact the whole time.
  Treat it as a claim to verify at release time: **read what actually arrived**,
  not what was supposed to. It carries heads and tags and nothing else — checked
  by listing the refs on the far side rather than by reasoning about it.

Users receive it by installing from the marketplace, which resolves to `main`:

```
/plugin marketplace add raphaelfribeiro/sarah-framework
/plugin install sarah@sarah-framework
```

## How you know it is working

There is **no telemetry, and that is deliberate.** The framework runs inside the
user's session, reads their repository, and phones nothing home. Any signal that
required it to would cost more trust than it could ever return.

That leaves four signals, in the order they arrive:

| Signal | Says | Where |
| --- | --- | --- |
| CI green on the tag | The release passed every guard it claims to enforce | Actions, `release` workflow |
| CI green on `main` | The published branch still passes | Actions, `validate` workflow |
| The plugin loads | Manifests parse, skills register, hooks do not break a session | `/plugin` in any Claude Code session |
| Issues | A human hit something the guards do not model | GitHub issues |

**The first signal fired for the first time on v0.1.0**, and it passed: both the
called validation and the publish job, producing the release from the changelog
section. Before that it was a claim — its steps had been exercised locally,
including against a deliberately wrong tag, which is not the same thing.

One trap it revealed, worth knowing before the next repository is set up. **A
first push into an empty remote does not fire a release.** Every ref arrives at
once, and the remote registered a workflow run for the default branch only —
nothing for the other branch, nothing for the tag, even though the workflow file
was present in the tag's own tree. Deleting the tag and pushing it again as an
isolated event ran the pipeline correctly. It is an artefact of an empty
repository and does not recur, which is exactly why nobody remembers it.

The fourth is the only one that finds a defect the first three cannot, which is
why [the README asks for a specific kind of report](../README.md#contributing): a
phrasing that should have fired a skill and did not. A skill that does not
trigger does not exist, and no CI job can measure triggering.

**One thing no signal covers.** CI validates structure — that a skill has
frontmatter, that a body fits its ceiling, that a hook exits 0. Whether a skill
*fires*, whether a gate *holds*, and whether a phase *spawns its specialists* are
behavioural, and the only instrument that has ever measured them is a recorded
run against a fresh project. That is expensive, it is not automated, and it is
not part of this pipeline. Treat structural green as necessary and never as
sufficient.

## The way back

Written now, because an incident is the worst moment to design one.

**For a user.** Pin the previous tag instead of tracking `main`:

```
/plugin uninstall sarah@sarah-framework
/plugin marketplace remove sarah-framework
```

then reinstall from a checkout of the tag that worked. A plugin holds no
migrations and writes nothing outside the project's `sarah/` directory, so
downgrading loses nothing. **Files already written in `sarah/` stay** — they are
the project's, not the framework's, and no rollback removes them.

**For the maintainer.** A bad release comes back by moving `main`, never by
rewriting it:

```sh
git checkout main
git revert -m 1 <merge-commit>     # the release merge
git tag -a vX.Y.Z+1 -m "revert vX.Y.Z: <reason>"
```

Deleting a published tag is not a rollback. Anyone who already installed keeps
what they have, the record of what shipped disappears, and the next report
arrives about a version that officially never existed.

**For v0.1.0 specifically, there is no previous version.** The way back is
uninstalling. Stated plainly because a rollback plan that quietly assumes a
predecessor is a rollback plan that fails on the one release most likely to need
it.

## Owners

One maintainer, one owner for every signal above. An alert nobody acts on is
noise, and at this size a routing table would be a fiction — so there is no
alerting configured beyond GitHub's own notification on a failed workflow run.
When a second maintainer exists, this section is the first thing that has to
change.
