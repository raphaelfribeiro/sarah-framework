# S.A.R.A.H. state

**Updated:** 2026-10-24

| | |
| --- | --- |
| **Default level** | 3 |
| **Mode** | greenfield |
| **Released** | `v0.1.0`, 2026-08-16 |

## In flight

| Task | File | Phase | Level | Waiting on | Since |
| --- | --- | --- | --- | --- | --- |
| Measurement pilot — Jukebox Disc | `sarah/state/measurement-pilot.md` | running, outside this repo — 44 sessions, 43 of 47 slices | 2 | the pilot to finish; a partial read began 2026-10-24 | 2026-08-16 |
| Habits that earned their place | `sarah/state/the-habits-that-earned-their-place.md` | implement (plan approved) | 3 | nothing: building | 2026-10-24 |

**Reopened 2026-10-24 by the maintainer's decision**, with the pilot still running: the
user's own install stays pinned to `v0.1.0`, so work here cannot reach the pilot.

`v1-readiness` shipped as `v0.1.0`; what it delivered is in `sarah/changelog/`.
This index was compacted on 2026-10-24 to meet the 8 KB ceiling the habits task
introduces; the long form of each lesson below is in the changelog and git history.

## Carried forward

- **The leak guard is an allowlist** (`scripts/allowed-hosts.txt`). Bare product
  and network names go in a gitignored `.private-terms` read by the pre-push hook,
  which **announces on every push when that file is absent**. CI runs after
  publication, so it cannot catch that class.
- **A component that cannot report its own failure fails in silence.** The mirror
  kept a pre-rename URL for eleven days and only its settings page knew. A state
  file repeating a belief as fact is the same defect.
- **Bumping a version means editing both manifests and adding a `CHANGELOG.md`
  section**, or `release.yml` refuses the tag — by design. It calls `validate.yml`
  rather than copying its guards.
- **`docs/operating.md` holds observe-and-reverse.** No telemetry. No signal there
  can tell whether a skill fires; that needs a recorded run.
- **The framework does not make Claude write better code on a well-specified
  brief**, and the README says so: three studies, none in our favour, writeups in
  `docs/study/`. The next study needs a different question, not a better rubric.
- **The human gates have never been measured** by an instrumented run; the
  measurement pilot is the first reading, and it is partial.
- **An instrument must be able to report that it did not measure.** Fixes that
  held were written by exclusion; ones that enumerated what to fear kept failing.
- **Divergence, not omission, survives gates.** Define a shared expression once.
- **`sarah-bootstrap` sits at ~1,950 of 2,000 tokens.** Additions go in words, or
  something leaves.
- **Framework v2's subtractive thesis is unproven** and still the live question.
- **Gate 5 requires a commit, and nothing enforces it at runtime.**
- **The eight steps live in three places that must agree:** `README.md`,
  `skills/sarah-init/SKILL.md` and `skills/sarah-bootstrap/SKILL.md`.

## Publication

The repository is **public** and pushing is publishing. Commit freely; push only
on an explicit decision. Nothing versioned may reveal the maintainer's internal
infrastructure; two CI guards enforce it.

- **`main` refuses every direct push**, admins included. Releases land through a
  pull request merged **fast-forward only**. Sequence in `docs/branching.md`.
- **The mirror syncs on push**, with an eight-hour fallback and a manual trigger
  through the origin's API. It sends heads and tags only.
- **A brand-new mirror target does not fire its own release.** Re-push the tag as
  its own event.
