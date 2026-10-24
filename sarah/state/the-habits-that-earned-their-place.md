# Habits that earned their place — an opt-in catalog offered by `/sarah-init`

**Branch:** `feature/the-habits-that-earned-their-place` · **Level:** 3 · **Phase:** design-ux (Gate 2 closed 2026-10-24) · **Updated:** 2026-10-24

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

Design / UX: the `/sarah-init` habit-catalog interview. Inputs: the approved spec
`docs/specs/the-habits-that-earned-their-place.md` and the approved design
`docs/specs/the-habits-that-earned-their-place.architecture.md`.

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

**First thing implementation does:** four probes of untested platform behaviour —
effort set per call, the hook seeing executor launches, an executor naming the
model it ran on, always-ask rules under permissive modes. A failed probe switches
to the fallback named in the design.

## Gates

| Gate | Status | When |
| --- | --- | --- |
| Brainstorm exit - problem agreed, scope picked | passed | 2026-10-24 |
| 1. Spec approved | passed | 2026-10-24 |
| 2. Architecture approved | passed | 2026-10-24 |
| 3. Design approved | open | |

## Found along the way

- **`claude plugin validate . --strict` now fails on `develop` itself**, before
  any change here: the current CLI warns that a root `CLAUDE.md` is not loaded as
  plugin context (this one is deliberately for developing the repository) and that
  the plugin has no icon. `--strict` turns both into errors, so CI will go red on
  the next push. Fix in this delivery before the PR.

- **`sarah-bootstrap` points at `references/task-template.md`, which does not
  exist next to it.** The template lives in `templates/` and
  `skills/sarah-init/references/`. A session following the skill literally finds
  nothing. Fix in this task or as its own Level 0.

## Next

`sarah-phase-design-ux`: the `/sarah-init` interview — how the catalog is shown,
the order of questions, defaults, the empty and error states (no `python3`, no
token, tracker unreachable), and how a habit is removed later. Then implement.
The user's own install stays pinned on `v0.1.0` while the pilot runs.
