# S.A.R.A.H. state

**Updated:** 2026-08-16

| | |
| --- | --- |
| **Default level** | 3 |
| **Mode** | greenfield |
| **Released** | `v0.1.0`, 2026-08-16 |

## In flight

Nothing in this repository. **One thing is owed on the origin**, and it is not a
code change: the push-mirror still points at the pre-rename repository name and
has been failing every eight hours since 2026-08-05. Until it is repointed,
`v0.1.0` exists on the origin and nowhere else, and the README's Quickstart
resolves to nothing.

`v1-readiness` shipped as `v0.1.0` and its task file was deleted, which is what
the per-task state model prescribes. What it delivered is in
`sarah/changelog/`; what outlived it is below.

## Carried forward

- **A rename left a downstream reference behind, and it failed in silence for
  eleven days.** The mirror kept the old repository name, retried every eight
  hours, and recorded `Repository not found` where only its own settings page
  could see it. The 2026-08-05 decision that renamed the repository closed with
  "no versioned file changed: every URL already used that name" — true, and it
  was the one unversioned URL that mattered. **Sixth of the family, and the first
  outside an instrument:** a component that cannot report its own failure to
  anyone who would act on it. The state file then repeated the belief as fact,
  which is how a tag got pushed ahead of a branch that could not accept it.
- **v0.1.0 is tagged and the pipeline enforces it.** `release.yml` fires on `v*`,
  calls `validate.yml` through `workflow_call` rather than copying its guards,
  and refuses a tag whose manifests disagree with it or whose version has no
  `CHANGELOG.md` section. Both refusals were exercised against a wrong tag before
  the branch was cut. **Bumping a version means editing both manifests and adding
  a changelog section, or the release stops** — by design.
- **`docs/operating.md` is where observe-and-reverse lives.** No telemetry, on
  purpose. Four signals: CI on the tag, CI on `main`, the plugin loading, and
  issues. **None of them can tell whether a skill fires** — that is behavioural
  and only a recorded run against a fresh project has ever measured it. Structural
  green is necessary and never sufficient, and the missing installation smoke test
  is recorded as a gap rather than closed.
- **The framework does not make Claude write better code on a well-specified
  brief, and the README says so.** Six blind-judged runs, 20.7/48 against 19.7 at
  21% more cost; an earlier study could not discriminate at all because every
  artefact scored 43-44 of 44 and the arms were confounded by `--setting-sources`.
  Three attempts, three times without a verdict in our favour. US$ 308.63 and
  US$ 187.31. Full writeups in `docs/study/`. **The next study needs a different
  question, not a better rubric** — the tested claim was code quality on a brief
  that leaves nothing unstated, which is the case the framework is least likely
  to help.
- **The human gates have never been measured.** Every instrumented run carried
  "do not ask me anything", which proves the automatic gates and forecloses the
  human ones. Anything claiming otherwise is claiming more than the evidence.
- **Five instrument bugs, one shape.** A sanitizer that deleted lines in one arm
  only; a harness that read a rate-limited step as complete; a framework-use
  count that crashed into `0` and became a finding; an isolation probe that read
  silence as absence; a recovery step that would have deleted three finished runs.
  **An instrument must be able to report that it did not measure.** The fixes that
  held were written by exclusion — refuse anything that is not a regular file,
  make each verdict carry its own affirmative evidence — and the ones that kept
  failing enumerated what to fear.
- **Divergence, not omission, is the defect that survives gates.** Round 5 of the
  packager review shipped a file called `the framework.md` whose prose pointed at
  `the frameworkmd`, from two rewrite expressions that were meant to agree. No
  gate could see it because each passed alone. The fix was defining the
  expression once. `release.yml` calling `validate.yml` is the same lesson applied
  before the fact.
- **`sarah-bootstrap` sits at ~1,950 tokens against its 2,000 ceiling**, measured
  2026-08-16 by CI. It is injected into every session, so there is room for
  roughly one paragraph and no more. Additions go in words, or something leaves.
- **Framework v2's subtractive thesis is unproven and still the live question.**
  The review gate probes with hostile input and rehearses a cold start, and three
  artefacts survived an independent cut: invariants stated with the consequence no
  test would catch, superseded decisions with their reason, and the
  deliberately-not-tested list. Whether any of it helps was what Phase F set out
  to measure, and Phase F answered a different question.
- **Gate 5 requires a commit, and nothing enforces it at runtime.** All seven
  phase skills close their own loop in prose. Whether phase-closing commits
  actually happen is measurable only by instrumenting another run.
- **The eight steps are documented in three places and must stay in agreement:**
  `README.md` (§The workflow), `skills/sarah-init/SKILL.md` (step 0 welcome), and
  `skills/sarah-bootstrap/SKILL.md` (the routing ladder). A change to one is a
  change to all three.

## Publication

The repository is **public** and pushing is publishing. Commit freely; push only
on an explicit decision. Nothing versioned here may reveal the maintainer's
internal infrastructure: clone URLs, badges, issue links, and CI reference GitHub
and nothing else, and two CI guards enforce it.

Two mechanics that cost a release-day hour on 2026-08-16 and are written down so
they do not cost another:

- **`main` refuses every direct push**, admins included. Releases land through a
  pull request merged **fast-forward only**, which keeps the tag pointing at a
  commit `main` actually contains. Sequence in `docs/branching.md`.
- **The mirror does not run.** It was never repointed after the 2026-08-05
  rename, so it has been failing on the old repository name every eight hours
  since. Nothing external has received a single commit. Fixing it is a settings
  change on the origin, not a change here.
