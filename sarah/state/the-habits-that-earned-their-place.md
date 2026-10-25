# Habits that earned their place — an opt-in catalog offered by `/sarah-init`

**Branch:** `feature/the-habits-that-earned-their-place` · **Level:** 3 · **Phase:** merged into `develop`; release next · **Updated:** 2026-10-24

## The problem, as agreed

S.A.R.A.H. v0.1.0 gives a project structure — phases, state, gates — and no
operating habits. The maintainer runs a second, private product with Claude Code
*without* the framework, and its habits grew from incidents and only held once
they became mechanisms: written rules had already failed. The measurement pilot
shows both sides: what the framework lets go missing, and what it over-produces.

**The rule of entry, which is the answer to the assumption most likely to sink
this:** a habit born from an incident, installed in a project that never had the
incident, is weight. The pilot's main defect is already weight — a 155 KB state
index read every session, ~14 questions per session. So **every habit in the
catalog names the failure it prevents**, with evidence from the reference project
or the pilot, and is installed only if the user picks it.

**Nothing private from either project enters this repository** — no names,
domain content, or infrastructure. Insights are recorded as failure, evidence
(aggregate), remedy.

## Scope chosen: B — opt-in modules, designed together with the extraction

Chosen by the user over A (extract first) and C (parity). Sixteen habits, all
selected:

| Group | Habit |
| --- | --- |
| **Conversation** (defaults) | Every user decision is an `AskUserQuestion`, never buried in prose |
| | Within an approved plan, no "continue or stop?" questions — stop only when told |
| | Never hand the user a command the agent can run itself |
| | Explain level, gates and trade-offs in the project's terms; never re-ask what was answered |
| **Board** | Optional tracker (Trello first) offered by `/sarah-init`; demands enter there and the framework manages them |
| | Each task declares executor, model, effort and fallback |
| | Fixed orchestrator brief, deeper for weaker executors; fixed executor report (done / proof / not finished / requested tasks) |
| | Daily board audit as one deduplicated, self-closing issue |
| **Installable agreements** (may block; the user chooses) | Gitflow guard + merge only with green CI |
| | Changelog fragment per delivery + one user-facing sentence feeding release notes |
| | Premise re-check before a task starts, reconciled against prior decisions; exceptions only with a reason and an expiry date |
| | Worktree per task, parallel executors under a WIP limit, worktree born ready |

**The plugin's own hooks stay sensors.** Blocking behaviour lives in what
`/sarah-init` offers to install into the user's project, by the user's choice —
decided by the user 2026-10-24.

## Pilot evidence already extracted (aggregate, partial — 43 of 47 slices)

| Finding | Evidence |
| --- | --- |
| The first option is almost always taken | 89% of single-choice answers; another listed option 2%; free text 8% — and the free text is where gates changed outcomes |
| Continuation questions are the largest single class | 104 of 855 questions; the answers say "stop only when I say", "keep going" |
| Already-answered questions get asked again | "I already answered", twice in one session |
| Framework vocabulary unexplained | the scale level was not understood on day 1 |
| Recommendations made on unverified facts | the user doubted one and was right |
| The user wants work executed, parallel and unattended | "you do it via ssh", "3 parallel fronts max", "run overnight without me" |
| State files bloat | index 155 KB, task files 125 KB and 91 KB, architecture map 78 KB |
| Integration never happens | one feature branch, 779 commits, never merged to `develop` |
| Skills that never fired | `sarah-research`, `sarah-hotfix`, `sarah-compact` (`sarah-phase-release`: no release yet) |
| A day-1 "permanent" exclusion resurfaced with no visible reconciliation | found by text search; not yet traced |

## Friction interview, 2026-10-24

The pilot kept no handwritten notes; this replaces them, declared as the user's
own account after the fact.

| Question | Answer |
| --- | --- |
| Where ceremony weighed most | All four offered: opening/closing, multi-round review, long texts, continue-or-stop questions |
| Opening and closing | **Heavy and also essential** — it is where the day is agreed and closed. Keep the ritual, make it short |
| Continue or stop | **Never ask.** Stop only when told to, or when a bounded order is met ("do x tasks and stop"). No order means keep going |
| Text | Clear, objective, succinct, **less technical**; technical explanation only on request |
| Taking the first option (89%) | **"Trusted it without reading deeply."** The human gate is mostly trust — so the recommendation carries the weight, and its facts must be verified before it is made |
| Reading reports and state files | **Almost never.** The agent has to help decide, not hand over reading |
| What it should have done alone | Parallel fronts; run unattended; test on its own; remember what was decided |
| Parallelism default | **Parallel fronts with specific agents at specific effort; `/sarah-init` defaults to up to 3 simultaneous tasks** |

## Itinerary

Approved by the user as proposed, 2026-10-24.

| Step | In | Why |
| --- | --- | --- |
| Brainstorm | yes | done 2026-10-24 |
| Spec | yes | sixteen habits without acceptance criteria, three conflicts open |
| Architecture | yes | external tracker, hooks installed into the user's project, agent roster against the context budget |
| UI/UX | yes | the `/sarah-init` interview is the surface |
| Build & QA | yes | always |
| Security | yes | tracker token; hooks running in the user's shell |
| Docs | yes | gate 5 |
| Release | yes | ships as public v0.2.0 — what a new installer gets |

## In flight

Implementation, against `docs/specs/the-habits-that-earned-their-place.plan.md`
(16 steps) and `...test-plan.md` (~140 tests, core 95 first). The four platform
probes **all held** on CLI 2.1.308, so no fallback applies.

| Wave | Steps | Branch | Status |
| --- | --- | --- | --- |
| 1 | 1 template move, 2 probes | this branch | done (3e42be2, c7eaa2a) |
| 2 | 3+4 defaults and state size | `feature/habits-s03-defaults-and-size` | merged |
| 2 | 5 install engine | `feature/habits-s05-install-engine` | merged |
| 2 | 7 executor and brief | `feature/habits-s07-executor` | merged (9d2096c) |
| 3 | 8+9 decisions, short rituals | `feature/habits-s08-decisions-rituals` | merged |
| 3 | 6+10 init interview, grants | `feature/habits-s06-init-grants` | merged |
| 3 | 11+12 exceptions, gitflow, changelog fragment | `feature/habits-s11-exceptions-gitflow` | merged (9e7fdb7) |
| 4 | 15 tracker | `feature/habits-s15-tracker` | merged |
| 4 | 14 Stop hook | `feature/habits-s14-no-idle` | merged |
| 4 | 13 dispatch guard | `feature/habits-s13-dispatch-guard` | merged (babeda3) |
| 4 | 3b session-start habit lines (Habits, Tracker, Audit, Exceptions) | `feature/habits-s03b-session-lines` | merged (5d41187) |
| 5 | 16 docs gate and release prep | `feature/habits-s16-docs-gate` | done: ARCHI, README, operating, extending, changelog, version 0.2.0 |

At most three slices run at once, each in its own worktree branched from this
branch, then merged back here. Developers write the tests from the test
engineer's plan, rather than a separate test engineer per slice.

**Carried from implementation, still open after Gate 4:**

- Session-start output is 389 of 400 tokens worst case (chars/4; `token_budget.py`
  rates it ~15% higher). No headroom.
- **Before the push:** the unpublished range carries the maintainer's personal
  address as author; rewrite it to the GitHub no-reply address once every slice is
  merged (decided 2026-10-24). Published history stays as it is.
- **The tracker has never met the live Trello API.** The user chose to release
  without the smoke; it stays a known limit.
- Guards need `git`, `python3` and `jq`; without `jq` they allow, by design.
- The CI gitflow check ignores local exceptions; `gh pr create` without `--base`
  and a local `git merge` into a permanent branch stay unguarded (documented).
- Dispatch guard: the three entries share one payload, so `worktree.baseRef`
  installs even when only the model check is picked. Its task count rests on an
  orchestrator marking the task in progress, which no skill instructs yet, and
  rows waiting on the user count as running (Gate 4, optional, not fixed).

## Gate 4 review (2026-10-24)

Two reviewers in clean contexts, correctness and security. No credential leak, no
code execution through crafted input. Blocking findings, all re-verified, were
fixed test-first in three slices, merged (2b7871e, fe1ea83, 30447d5); 350 Python
tests and the shell suite green, dash included. A re-review of the fixes passed with no blocking finding; its three cheap items are
fixed (quoted `habits.py` form, `git clean -n` false prompt, ADR-010 note on
`merge-on-green` being a record):

| Slice | Branch | Fixes |
| --- | --- | --- |
| Tracker | `feature/gate4-tracker` | tracker never wired (hook reads `## Tracker`; intake, report, sync in the rituals); `nobody` read as blocked; no Ready list; `cards/all`; frame forgery; unframed board text; `base_url` with `\` or `@`; `set_card` outside `sarah/state/` |
| Guards | `feature/gate4-guards` | backslash continuation bypass; `env -i`, `/usr/bin/env`, path-to-git; tag pushes refused; `gh pr merge --auto` and `-R`; "Rule not checked" was invisible (exit-0 stderr is never shown) |
| Permissions | `feature/gate4-permissions` | agent could self-grant and edit `sarah/habits.md`; push grant widened by a refspec and `-d`; forged records on `remove`; `.env` rules cwd-relative; missing destructive forms; merge on green CI becomes a revocable grant |

Also from the fixes: the tracker gained a sixth verb, `done`, run by
`/hasta-la-vista` before a shipped task file is deleted (ADR-009 amendment);
files adopted before this change carry no adopt record, so `remove` keeps them.

Decided by the user after review, 2026-10-24: release **without** the live Trello
smoke, stated as untested in the changelog; the four routine always-ask rules
(`rebase`, `--amend`, `branch -d`, `printenv`) dropped; push and a PR into
`develop` approved, after the author rewrite; `Claude-Session` trailers stripped
from the unpublished range and not added to new commits. The release cut still
waits on its own yes. Still open: the stale D6 8,768-byte claim.

## Blocked

Nothing blocked.

## Decisions at Gate 2 (2026-10-24)

| Decision | Record |
| --- | --- |
| One `executor` agent; model and effort set per call | ADR-006 |
| Conversation defaults printed by the session-start hook; lasting decisions in `sarah/decisions.md` | ADR-007 |
| Agreements installed by `scripts/habits.py` into the user's project, which owns them; manifest in `sarah/habits.md`; plugin hooks stay sensors | ADR-008 |
| Tracker through `scripts/tracker.py`; local state is the source of truth; audit at the day's first session; token from an environment variable, never pasted | ADR-009 |
| Autonomy grants set at init, expandable later; destructive actions, money and credentials always ask. **With R13 installed, merge runs unattended on green CI**; the release cut stays the user's — supersedes "every merge has a human behind it" for those projects | ADR-010 |

Decided at Gate 1: commit attribution chosen at init, **default off** (Q4); state
ceilings **8 KB index, 16 KB per task file** (Q5); **board never empty** enters as
R24 (Q7).

**Left open on purpose:** grants in a team repository apply to every
collaborator's agent — revisit when a team adopts it (ADR-010). `python3` is
needed by any habit that installs or calls a script, the tracker included.

## Decisions at Gate 3 (2026-10-24)

| Decision | Choice |
| --- | --- |
| Init interview | **Always the full catalog**, in plain words without technical terms; technical names only on "details" |
| What init recommends the agent may do unattended | Push feature branches; merge, force-push and deletion still ask |
| The close | One question, "Commit (Recommended)"; the agent commits |
| Compaction offer | Once a day, in the opening or after the first task |
| Opening and closing | At most 10 lines, no headings; **a short table when there are more than 2 items** |

The new patterns listed in the UX spec §9 were approved with the design.

## Gates

| Gate | Status | When |
| --- | --- | --- |
| Brainstorm exit - problem agreed, scope picked | passed | 2026-10-24 |
| 1. Spec approved | passed | 2026-10-24 |
| 2. Architecture approved | passed | 2026-10-24 |
| 3. Design approved | passed | 2026-10-24 |
| Plan approved (16 steps, ~140 tests, full depth) | passed | 2026-10-24 |
| 4. Review | passed: fixes merged and re-reviewed | 2026-10-24 |
| 5. Documented and committed | written in step 16; re-check after review | — |

## Found along the way

- **`claude plugin validate . --strict` had started failing on `develop`**:
  the current CLI warns that a root `CLAUDE.md` is not loaded as plugin context.
  CI does not run the validator, so only the pre-PR check saw it. **Fixed
  2026-10-24 by moving the development `CLAUDE.md` to `.claude/CLAUDE.md`**,
  which Claude Code still loads as project context and the validator ignores.
  The missing-icon notice is informational and does not change the result.
- **`sarah-bootstrap` pointed at a `references/task-template.md` that did not
  exist next to it.** Fixed in step 1 (3e42be2): the template moved into the
  bootstrap's own `references/`, and a static test now checks every skill's
  `references/` links.

## Next

Done: the unpublished range carries the GitHub noreply address and no session
links; pushed, PR #1 into `develop`, CI green, merged on green as the user
authorised. On the first CI run the machine-path guard read the runner's own
bytecode; it now reads tracked files only.

1. The release cut and the `v0.2.0` tag, on the user's yes.

Test-plan section 10 finding 2 (the Premises format) is resolved by the task
template's `## Premises` section. Architecture D6's 8,768-byte claim is left as
it stands, pending the user's word. The user's install stays pinned on `v0.1.0`.
