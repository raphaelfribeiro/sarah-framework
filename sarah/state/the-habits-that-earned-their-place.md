# Habits that earned their place — an opt-in catalog offered by `/sarah-init`

**Branch:** `feature/the-habits-that-earned-their-place` · **Level:** 3 · **Phase:** architecture (Gate 1 closed 2026-10-24) · **Updated:** 2026-10-24

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

Architecture. The approved spec is `docs/specs/the-habits-that-earned-their-place.md`:
24 requirements (R1-R19 and R24 added, R20-R23 modified), cut line written.

## Blocked

Nothing blocked.

## Pending decisions

None waiting on the user. Two questions belong to the architect, not the user:

| Question | Spec ref |
| --- | --- |
| Ten executor agent files, or one executor taking model and effort as parameters | Q1 |
| Where the conversation defaults (R1-R7) live, with the bootstrap ~50 tokens under its ceiling | Q2 |

Decided at Gate 1 by the user: commit attribution is chosen at init, **default off**
(Q4); state files are capped at **8 KB index, 16 KB per task file** (Q5); **board never
empty enters as R24**, the other three unoffered habits stay out (Q7).

## Gates

| Gate | Status | When |
| --- | --- | --- |
| Brainstorm exit - problem agreed, scope picked | passed | 2026-10-24 |
| 1. Spec approved | passed | 2026-10-24 |
| 2. Architecture approved | open | |

## Found along the way

- **`sarah-bootstrap` points at `references/task-template.md`, which does not
  exist next to it.** The template lives in `templates/` and
  `skills/sarah-init/references/`. A session following the skill literally finds
  nothing. Fix in this task or as its own Level 0.

## Next

Design with `sarah-phase-architecture`: answer Q1 and Q2, decide how agreements are installed into a user's project and removed, and how the tracker credential is delivered. Security Advisor consults. The
pin of the user's own install on `v0.1.0` stays while the pilot runs — this
branch must not reach the pilot.
