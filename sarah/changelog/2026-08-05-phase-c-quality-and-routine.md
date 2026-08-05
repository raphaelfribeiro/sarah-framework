# Phase C — Quality and routine

**Date:** 2026-08-05 · **Level:** 3 · **Phase:** 5-implement

The daily loop and the enforcement layer. All five commands now exist, the hooks
watch commits and pushes, and the review gate no longer dissolves when its tools
are unavailable.

- **Gate 4 gap closed.** `sarah-phase-review` previously had no answer for the
  case where no independent reviewer can run — subagents disabled and no
  second-model CLI. It now stops, names what is unavailable, offers three ways
  out, and if a self-review is accepted, records in `state.md` and the changelog
  that gate 4 was not satisfied. Found during Phase B acceptance, where a
  session setting silently blocked the reviewer.
- **`/sarah-status`** — reads only `state.md`, reports in half a page, writes
  nothing, starts nothing.
- **`/ill-be-back`** — start-of-day situation report in four blocks, ending with
  the day's priorities as options for the user to approve or redefine. Reports
  divergence between the state file and the repository, trusting the repository.
- **`/hasta-la-vista`** — end-of-session debrief. Updates `state.md` and the
  changelog, verifies the documentation gate and reports gaps without fixing
  them, suggests a commit without running it.
- **`/sarah-compact`** plus `scripts/token_budget.py` — standard library only,
  calibrated against Claude Code's own reported counts to within roughly 10%.
  Refuses to compact a file that is within budget.
- **Hooks.** `validate-commit` (conventional message, hardcoded credentials in
  the staged diff, staged JSON parses), `validate-push` (force push, protected
  branch, a push is a publish), `pre-compact` (write durable state before detail
  is lost). All advisory, all exit 0, all silent on the fast path.
- **`sarah-hotfix`** and **`sarah-research`** — the emergency path that records
  which gates it skipped and what is owed, and the investigation path that
  changes nothing and labels found, inferred, and unknown separately.

**Fixed during testing:** `validate-push` parsed the branch positionally, so
`git push --force origin main` warned about the force but not about the branch —
losing half the warning in the most dangerous case. It now drops flags before
reading the refspec; five variants verified, including `HEAD:main`.

**Verified:** commit hook across six cases including a placeholder that must not
alarm; push hook across five parsing variants and a missing `jq`; the token
script against real counts; `/ill-be-back` catching a state file that claimed
delivery while nothing was committed; `/hasta-la-vista` writing state, reporting
an out-of-date README without fixing it, and declining to commit.

**Not yet real:** the full README, `docs/`, the walkthroughs, CI, and the
community files. Phase D.

**Dropped from the plan:** `sarah-upgrade`. With plugin distribution, upgrading
is `/plugin update`; a skill for it would be redundant.
