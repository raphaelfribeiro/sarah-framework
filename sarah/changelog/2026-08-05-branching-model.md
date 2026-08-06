# Branching model — gitflow adopted

**Date:** 2026-08-05 · **Level:** 1 · **Phase:** 5-implement

The repository had no stated branching model. Everything landed directly on
`main`, while three separate places already assumed a pull request flow — the
push hook, the generated README template, and this repository's own contributor
instructions. A model nobody wrote down is a model nobody can follow.

- **`docs/branching.md`** — gitflow in full: `main` and `develop` as permanent
  branches, `feature/*`, `release/*` and `hotfix/*` as temporary ones, the
  mandatory back-merge, and why `--no-ff` is not a preference.
- **Gates given a place to stand.** Gate 4 closes on the branch before the merge
  into `develop`; gate 5 travels with the change rather than behind it. A merge
  into `develop` asserts both closed.
- **`CLAUDE.md`** — a branching section, and pull requests now explicitly target
  `develop`.

**Chosen against the recommendation.** GitHub Flow was recommended, on the
grounds that a marketplace plugin has exactly one live version and `develop`
becomes a second trunk to maintain. The maintainer chose gitflow. Recorded here
because a decision worth making is worth knowing the shape of later.

**Cheaper than estimated.** Two artifacts were expected to need rewriting and
neither did: `hooks/scripts/validate-push.sh` already listed `develop` among the
protected-by-convention branches, and `README-template.md` already parameterised
its base branch instead of hardcoding `main`.

**Not addressed here:** contributions arriving through the public mirror. The
model describes how work merges, not how an outside pull request reaches this
repository. That belongs with the community files in Phase D.
