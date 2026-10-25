# Plan — S.A.R.A.H. v0.2.0, the habits that earned their place

**Date:** 2026-10-24 · **Level:** 3 · **Spec:** [the-habits-that-earned-their-place.md](the-habits-that-earned-their-place.md) (R1-R24), [architecture](the-habits-that-earned-their-place.architecture.md) (D1-D9), [UX](the-habits-that-earned-their-place.ux.md), ADR-006 to 010

## Goal

A user who runs `/sarah-init` on v0.2.0 gets short, decision-first conversation defaults, and can opt in to each habit in the catalog. Every installed habit is recorded, removable and owned by the user's project. Plugin hooks remain sensors. Declining everything behaves as v0.1.0 plus the defaults.

## Steps

Each step is one commit on this branch, in this order, with the test-plan tests for its requirement IDs written first. "Probe" marks a dependency on an unverified platform fact (see Risks).

| # | Step (requirements) | Files | Could go wrong |
| --- | --- | --- | --- |
| 1 | **Cheap fix (R23, D7).** `git mv` `task-template.md` from `sarah-init/references/` to `sarah-bootstrap/references/`; repoint the `templates/` symlink; reword `sarah-init/SKILL.md` lines 109 and 138 to name the bootstrap's copy. The bootstrap text is **not edited** (zero tokens). Add a CI step: every `references/<file>` link in a `SKILL.md` resolves to a real file in that skill's own directory | `skills/sarah-bootstrap/references/task-template.md`, `templates/task-template.md`, `skills/sarah-init/SKILL.md`, `.github/workflows/validate.yml` | A symlink left pointing at the old path passes `ls` but fails to read at runtime (ARCHI §8). The new check must treat a symlink in `references/` as a failure |
| 2 | **Probe results folded into the design.** Record the four verdicts in architecture §0 (F3/F5, F16, F17, F18), apply any named fallback to the slices below, and stop for the user if a fallback changes an accepted criterion | `docs/specs/...architecture.md` §0, §8 | A probe returns "works in this CLI version only". Record the CLI version beside the verdict |
| 3 | **Conversation defaults (R1-R7, D2).** `hooks/conversation-defaults.txt` (at most 200 tokens, one toggle name per rule); `session-start.sh` prints it after the existing lines and reads toggles from `sarah/habits.md` if present. Add one line each to the phase skills where a default applies. CI: measure the defaults file (200) and the hook's worst-case output (400) | `hooks/conversation-defaults.txt`, `hooks/scripts/session-start.sh`, phase `SKILL.md` files, `scripts/token_budget.py` use in `validate.yml` | Old lines plus defaults plus later habit, size and tracker lines can pass 400 tokens. Measure with every optional line present; trim old lines first. POSIX `sh`, exit 0 always |
| 4 | **State ceiling (R19, D6).** Hook prints one `Size:` line per file over 8,192 B (index) or 16,384 B (task); honors `sarah/.local/compact-snoozed`. `sarah-compact` gains the four-step state section and proposes before writing | `hooks/scripts/session-start.sh`, `skills/sarah-compact/SKILL.md` | `wc -c` pads on some platforms; strip it. D6 says this repo's index is 8,768 B; it is 3,545 B (see Out of scope) |
| 5 | **Install engine (R8 mechanics, R20, R22, D3.1).** `scripts/habits.py` with `plan`, `apply`, `remove`, `status`; the `sarah/habits.md` schema (chosen set, settings, autonomy, manifest, exceptions); stamps with plugin version and sha256; settings-entry identification by `sarah/hooks/` path; `.gitignore` entry for `sarah/.local/`. Ships with one inert fixture payload. CI: payload scripts get `sh -n` and a "never `exit 1`" check (exit 2 allowed), since the existing check covers only `hooks/scripts/` | `scripts/habits.py`, `skills/sarah-init/habits/_fixture/`, `.github/workflows/validate.yml` | The riskiest step. Merging JSON into a settings file the user already has; a user-edited stamped file; an unstamped file already at the target; re-run must change nothing; remove must touch only matching hashes. No `python3`: offer the habit with the prerequisite stated, install nothing |
| 6 | **The init interview (R8, R18, R20, UX §1-4).** `/sarah-init` walks the full catalog in plain words; `references/habits-catalog.md` holds failure statements and the technical-name table (shown on "details"); re-run shows the current set; add and remove go through the same entry point; default limit 3. At most 40 lines added to `SKILL.md` | `skills/sarah-init/SKILL.md`, `skills/sarah-init/references/habits-catalog.md` | `SKILL.md` is 164 lines; keep prose in the reference. Habits whose prerequisite is missing are omitted with one line, never installed half-working. Probes F3/F16/F18 can change the copy |
| 7 | **Executor, brief and report (R10, R11, D1).** `agents/executor.md` (`model: sonnet`, no `effort`; four report sections); `references/executor-brief.md` in three depths; orchestrator steps in `sarah-phase-implement` (declare, dispatch with model, effort and worktree isolation, check the report, one re-brief, one fallback re-dispatch); the moved task template gains the executor table (executor, model, effort, fallback) and a Premises section | `agents/executor.md`, `skills/sarah-phase-implement/SKILL.md`, `skills/sarah-phase-implement/references/executor-brief.md`, `skills/sarah-bootstrap/references/task-template.md` | Probe F3/F5/F17. The roster grows by exactly one description; confirm `claude plugin validate . --strict` accepts the frontmatter. Card and report text goes in an untrusted-data block (§5.6) |
| 8 | **Durable decisions (R6, D2).** `sarah/decisions.md` format (one line per decision, newest first, dated); read at task start; conflict surfaces as one question quoting the decision; the documentation gate moves binding decisions into it. Wording lives in `sarah-phase-implement` and `hasta-la-vista`; the hook's defaults text already points at the file | `skills/sarah-phase-implement/SKILL.md`, `skills/hasta-la-vista/SKILL.md`, `skills/sarah-init/references/state-template.md` | The file does not exist in projects until the first decision; every reader must tolerate absence. "Permanent" exclusions must be stored as such, not as ordinary lines |
| 9 | **Short rituals (R21).** Rewrite `ill-be-back` (at most 30 lines) and `hasta-la-vista` (at most 35) to the UX §6 shapes: first line says whether a decision is needed, at most 10 lines, a table above 2 items, the closing commit question. Add the compaction offer once a day | `skills/ill-be-back/SKILL.md`, `skills/hasta-la-vista/SKILL.md` | Shorter text drops the documentation-gate check; keep it. "Still running" depends on whether background tasks outlive the session (a fifth unverified fact: omit the line until checked) |
| 10 | **Autonomy grants and always-ask (D9, ADR-010).** Autonomy section in `habits.md`; init records grants (recommended: push `feature/*`); `habits.py` installs `permissions.ask` rules for the fixed always-ask list and offers matching `allow` rules for `settings.local.json` as a shown diff. Expansion in conversation only on the user's quoted instruction | `scripts/habits.py`, `skills/sarah-init/habits/always-ask/`, `skills/sarah-init/references/habits-catalog.md` | Probe F18. The framework must never write an `allow` rule unprompted |
| 11 | **Exceptions and the gitflow guard (R13, R16, D3.2-3.3, D8).** Shared `sarah/hooks/lib` in POSIX `sh`: reads the exceptions table, honors a row only if reason is non-empty, today is in window and expiry is at most 14 days after grant, otherwise fails closed; logs each use. R13 hook and `sarah-gitflow.yml` (`pull_request` only, `contents: read`, no third-party action); attribution as a separate yes/no, default off. `sarah-status` lists active and recently expired exceptions. Bootstrap line 76 ("Every merge has a human behind it") reworded to name the opt-in exception, **net no longer than today** | `skills/sarah-init/habits/gitflow/`, `skills/sarah-init/habits/_lib/`, `skills/sarah-status/SKILL.md`, `skills/sarah-bootstrap/SKILL.md` | Date arithmetic in POSIX `sh` (no `date -d`): use `awk` day-number math and test the 14-day boundary and malformed dates. A script must block only on a positive finding; `gh` or `jq` missing means allow and say so. Bootstrap is at ~1,964 of 2,000 tokens; run `scripts/token_budget.py` after the edit |
| 12 | **Changelog fragment (R14).** Hook refuses `gh pr create` without a `sarah/changelog/` entry carrying a user-facing sentence; `sarah-phase-release` reads that sentence into the release notes | `skills/sarah-init/habits/changelog-fragment/`, `skills/sarah-phase-release/SKILL.md` | "User-facing sentence" must be checkable by a script: define one marked line in the fragment format and check only that line exists |
| 13 | **Dispatch guard and parallelism (R15, R17, D5).** `dispatch-guard.sh` (PreToolUse, matcher `Agent`): refuses over-limit, no model, stale premise check; counts in-progress rows in the index. Installs `worktree.baseRef: "head"` and `.worktreeinclude` entries. Step 0 of the brief: rename branch, write task file, run recorded setup, report baseline | `skills/sarah-init/habits/dispatch-guard/`, `skills/sarah-phase-implement/references/executor-brief.md`, `scripts/habits.py` | Probe F16. When only R18 is chosen, the limit is advisory. Index race between worktrees: only the orchestrator writes it (invariant 6) |
| 14 | **Work does not idle (R24).** Stop hook: blocks once when nothing is in progress, ready work exists, no task waits on the user and no stop marker is set; allows when `stop_hook_active` | `skills/sarah-init/habits/no-idle/` | A loop. The `stop_hook_active` allow is the whole safety; the failing test for it comes first. |
| 15 | **Tracker seam (R9, R12, D4).** `tracker.py` dispatching to `tracker_trello.py` over `urllib`; verbs `check`, `intake`, `sync`, `audit`, `report`; credentials from `TRELLO_API_KEY` and `TRELLO_TOKEN` only; the daily-audit date stored in `habits.md`; the Trello setup flow of UX §2; allowlist entries for the Trello hosts in `scripts/allowed-hosts.txt` | `scripts/tracker.py`, `scripts/tracker_trello.py`, `scripts/allowed-hosts.txt`, `skills/sarah-init/references/habits-catalog.md` | The credential must never reach stdout, a trace, a logged URL or a brief; Trello takes it as a query parameter, so redact before any print. 401: one message, no retry. Public board refused at `check`. Offline: `Card: pending`, reconcile on the next sync |
| 16 | **Documentation gate and release prep.** Listed below | see below | The eight-steps agreement and the manifests are the two places a mismatch ships |

## Tests

The test engineer's plan is `docs/specs/the-habits-that-earned-their-place.test-plan.md`, written in parallel. This plan does not write tests. It plugs in as follows: each step above is preceded by the failing tests that plan assigns to the same requirement IDs, and the developer takes those first.

| Layer | What it covers | Where |
| --- | --- | --- |
| Unit | Python in `scripts/` (install engine, tracker with a fake HTTP server); `sh` guards driven by fixture input | layout fixed by the test plan, under `tests/` |
| Integration | `habits.py` against a scratch project (re-run, remove, user-owned files untouched); hook output against fixture projects | same |
| End to end | Fresh project through `/sarah-init` choices, run with `claude -p` in the background, never in `/tmp` | same |

**The first failing test:** the one for step 1, a skill link that does not resolve, which the new CI check turns into a failure on today's tree.

**Deliberately not tested:** owned by the test plan, with the reason and what covers each gap.

CI additions (dead-link check, hook budget, payload shell checks) belong to the steps that introduce them. The first step with a Python test adds a `python3 -m unittest` step to `validate.yml`.

## Risks

The four unverified platform facts. Probes are running now; step 2 records the verdicts.

| Fact | Steps that depend on it | If the probe fails (named fallback) |
| --- | --- | --- |
| F3/F5: per-call `effort`; whether `CLAUDE_CODE_EFFORT_LEVEL` overrides it | 6 (copy), 7, 13 | D1 option (c): three files `executor-low`, `executor-medium`, `executor-high`, each with `effort` in frontmatter and model per call; the guard matches the `executor` name prefix. Cost: two more roster descriptions. If only the env override wins, no structure changes: the brief and `operating.md` say a user-set variable overrides the declared effort |
| F16: the `Agent` hook input carries `subagent_type`, `model`, `effort`, `isolation` | 6, 7, 13 | Try the alternative matcher the probe finds. If none works, `dispatch-guard.sh` cannot identify executors and R15/R17 become orchestrator-enforced and advisory, as R18 alone already is. That weakens two accepted criteria ("refused"), so it returns to the user before step 13 starts |
| F17: a subagent can name the model it ran on | 7 (report), UX §5 relay | The orchestrator reports only fallbacks it dispatched itself. A platform-chain switch on overload goes unreported; document the gap in `docs/operating.md`. No step is blocked |
| F18: `permissions.ask` still prompts under permissive modes | 6 (copy), 10 | Init states plainly that the always-ask list is an instruction in permissive modes, not a platform guarantee. Alternative for the user: a blocking hook on the fixed destructive patterns. Recommend disclosure only; an unbypassable hook will block something the user needs |

Other risks.

| Risk | If it happens |
| --- | --- |
| Hook output over 400 tokens (step 3, grows through 15) | CI fails; shorten existing lines before adding new ones |
| A step needs more than one commit to stay reviewable (5 and 11 most likely) | Split it into engine and payload; keep the order |
| CI host and path guards reject new files (Trello URLs, absolute user paths in fixtures) | Allowlist the host in the same step; build fixture paths at run time |

## Out of scope

- Everything the spec's Out of scope lists.
- Noticed and left alone: `sarah-status` lists the eight steps too, a fourth place that the state file's "three places" note omits and CI does not check. The design's claim that this repo's index is 8,768 B is stale (3,545 B), so D6's "the delivery must compact it" does not apply. Fix the design text in step 16 only if the user agrees.

## Documentation on completion

Step 16 is one commit, after all the others.

- [ ] `sarah/state.md` and `sarah/state/the-habits-that-earned-their-place.md` current; gate 5 row updated
- [ ] `ARCHI.md` — needed: §3 system shape and §5 boundaries (tracker configured, project-side files), §6 decisions (ADR-006 to 010), §7 invariants (plugin hooks sensors; installed agreements belong to the user; merge exception under R13), §8 sharp edges (references link check, probe verdicts), §9 map. Check its size budget
- [ ] `README.md` — needed: the habit catalog, shorter rituals, the `python3` prerequisite for script-backed habits, install pin note
- [ ] `docs/operating.md`, `docs/extending.md` — the tracker-adapter extension point and the F17 gap, only if changed
- [ ] `sarah/changelog/` entry, one for the delivery
- [ ] **The eight steps agree in all three places:** `README.md`, `skills/sarah-init/SKILL.md`, `skills/sarah-bootstrap/SKILL.md` (and `references/itinerary.md` and `sarah-status`). Names and order compared by hand after steps 6 and 11
- [ ] Version `0.2.0` in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`; a `## [0.2.0]` section in `CHANGELOG.md` moved out of `[Unreleased]`, written from the fragments
- [ ] Pre-PR checks from `.claude/CLAUDE.md`: `claude plugin validate . --strict` and `sh -n hooks/scripts/*.sh`; open the PR against `develop`
