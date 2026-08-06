# Branching model

This project follows **gitflow**. Two branches live forever; the rest exist only
long enough to deliver one thing and are deleted on merge.

A branching model is a promise about where working code lives. This one keeps
that promise in two places at once: `main` is what users have installed,
`develop` is what the next version will be.

---

## Permanent branches

| Branch | Holds | Rule |
| --- | --- | --- |
| `main` | Released code. Every commit is a published version. | Tagged, never committed to directly. |
| `develop` | Integration. What the next release will contain. | Merge target for every feature. |

`main` is the plugin as installed users have it. A commit landing there without a
version tag means someone shipped without saying what they shipped.

## Temporary branches

| Prefix | Branches from | Merges into | For |
| --- | --- | --- | --- |
| `feature/*` | `develop` | `develop` | Anything new or changed |
| `release/*` | `develop` | `main` **and** `develop` | Version stabilisation |
| `hotfix/*` | `main` | `main` **and** `develop` | Production is broken now |

Name them for the delivery, not the ticket: `feature/gitflow-adoption`, not
`feature/issue-42`. Six months later the branch name is the only context left.

The double merge on `release/*` and `hotfix/*` is not optional. A hotfix that
lands on `main` but never reaches `develop` is a bug that returns with the next
release, wearing the same face.

---

## The flow

**A feature.**

```sh
git checkout develop
git checkout -b feature/short-name
# work, commit
git checkout develop
git merge --no-ff feature/short-name
git branch -d feature/short-name
```

`--no-ff` is deliberate. A fast-forward merge erases the fact that the commits
belonged to one delivery, and the history stops being able to answer *what
shipped together*.

**A release.**

```sh
git checkout -b release/0.2.0 develop
# version bumps, changelog, release notes - no new features
git checkout main
git merge --no-ff release/0.2.0
git tag -a v0.2.0 -m "..."
git checkout develop
git merge --no-ff release/0.2.0     # back-merge, never skip
git branch -d release/0.2.0
```

A `release/*` branch is for stabilising, not for finishing. A feature that
arrives after the branch is cut goes to `develop` and ships in the next version.

**A hotfix** follows the same shape, branching from `main` instead of `develop`,
and back-merging with the same discipline. `sarah-hotfix` records which gates it
skipped and what is owed.

---

## How this meets the gates

The branching model does not replace [the quality gates](quality-gates.md); it
gives them a place to stand.

- **Gate 4 (review)** closes on the branch, before the merge into `develop`.
  The author never reviews their own work, and a branch is what makes a separate
  context possible.
- **Gate 5 (documentation)** closes on the same branch. `ARCHI.md`,
  `sarah/state.md`, `README.md` and a `sarah/changelog/` entry travel with the
  change, not behind it.
- **Version numbers are decided on `release/*`**, from what the changelog
  entries actually say was delivered.

A merge into `develop` asserts that both gates closed. If that stops being true,
the model is decoration.

---

## Pull requests

A pull request that does not follow this model is not accepted. Not negotiated,
not fixed on merge — rejected, with the reason named. The model is only worth
what is refused under it.

A pull request must:

1. **Target `develop`.** Never `main`. The one exception is a `hotfix/*`, which
   targets `main` and is back-merged afterwards.
2. **Branch from the right place.** `feature/*` from `develop`, `hotfix/*` from
   `main`, named for the delivery.
3. **Close gate 4.** Reviewed by someone who did not write it.
4. **Close gate 5.** `ARCHI.md` if the architecture moved, `README.md` if
   anything user-visible changed, and an entry in `sarah/changelog/`.
5. **Pass the checks** in [`CLAUDE.md`](../CLAUDE.md): `claude plugin validate .
   --strict` and `sh -n hooks/scripts/*.sh`.
6. **Say what changed and why.** A diff answers what. Only you can answer why.

## Rules

1. **Never commit directly to `main` or `develop`.** Both are protected by
   convention, and the push hook says so when you try.
2. **Never merge your own review.** Gate 4 belongs to a context that did not
   write the code.
3. **Back-merge every `release/*` and `hotfix/*` into `develop`.** Every time.
4. **Delete the branch on merge.** A branch that outlives its delivery is a
   question nobody can answer later.
5. **Rebase your own branch freely; never rewrite `main` or `develop`.**
   History that others have pulled is not yours to edit.

Every gate has a guardian. Every merge has a human behind it.
