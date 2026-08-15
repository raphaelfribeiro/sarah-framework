---
name: sarah-bootstrap
description: Orient before doing any development work in a S.A.R.A.H. project. Reads ARCHI.md and sarah/state.md, sizes the request into a scale level, and routes to the right phase with only that phase's specialists in context. Use at the start of any coding, planning, or design request in a repository that has a sarah/state.md file - including when the user says "add a feature", "fix this bug", "let's build", "what should we do next", "continue where we left off", or hands over a task with no other context. Also use when unsure which S.A.R.A.H. phase applies.
---

# S.A.R.A.H. — orientation

Skills, Agents, Reviews & Adaptive Hierarchy. The machines write the code. You command the mission.

This skill runs before the work, not instead of it. It costs a few hundred tokens and prevents the two failures that make AI-assisted development untrustworthy: acting without knowing the system, and applying heavy process to light work.

## 1. Orient

Read, in this order, and read **only** these:

1. `sarah/state.md` — current phase, scale level, open gates, pending decisions.
2. `ARCHI.md` — the architecture map, sections relevant to the request.

Never read a full spec, PRD, or architecture document as a routine step. If a routine step needs more than roughly 30k tokens of input, it is the wrong step — narrow it.

If `sarah/state.md` does not exist, this project is not initialized. Say so and offer `/sarah-init`. Do not silently invent state.

## 2. Size the request

Classify before acting. Getting this wrong in either direction is the most expensive mistake available here: ceremony on a typo wastes an afternoon, and no ceremony on a product wastes a month.

| Level | Looks like | Route |
| --- | --- | --- |
| **0 — Trivial** | Typo, rename, copy change, config tweak. No behavior change worth discussing. | Straight to code. No plan, no spec, no gates beyond a working build. Minutes, not hours. |
| **1 — Small** | Bug fix, small feature, contained in known code. | Mini-plan under one page → Developer → Reviewer. Phases 5–6 only. |
| **2 — Medium** | Feature touching several components, a new boundary, or a schema change. | Lean spec + plan. Phases 5–6 in full, phases 1–4 abbreviated to what the change actually needs. |
| **3 — Large** | New product, new subsystem, or anything with unsettled requirements. | Full pipeline, all phases, all gates. |

When the level is genuinely ambiguous, ask the user with the two candidate levels and what each costs. Do not guess upward to be safe: over-classifying is the single most common failure of workflow frameworks.

Record the level in `sarah/state.md`.

## 3. Route to the phase

Load the phase skill. It brings its own specialists. **Never load the full roster** — the roster exists so the right expert is available, not so every expert is present.

| Phase | Skill | Agents in context |
| --- | --- | --- |
| 1. Brainstorm | `sarah-phase-brainstorm` | Product Analyst |
| 2. Spec | `sarah-phase-spec` | Product Analyst, Product Manager |
| 3. Architecture | `sarah-phase-architecture` | Software Architect (Security Advisor consulting) |
| 4. Design / UX | `sarah-phase-design-ux` | UX/UI Designer |
| 5. Implementation | `sarah-phase-implement` | Developer, Test Engineer |
| 6. Review | `sarah-phase-review` | Code Reviewer, Security Advisor |
| 7. Release & operate | `sarah-phase-release` | DevOps Engineer, Release Manager |

**At Level 2 and above, propose the itinerary and let the user set it.** Read `references/itinerary.md` and present all eight steps as a table: in or out, the reason *from this request* rather than from the level, and the cost in the user's time. Then stop and let them answer. The level proposes; the user disposes, including dropping a step you marked in — record the choice in `sarah/state.md` and do not argue. Documentation is the one row that cannot be dropped.

At Level 0 and 1, skip the table. Announce the route in one line, naming any step stepped over. Eight rows to justify a typo fix is the ceremony this framework exists to prevent.

Two requests do not belong on this ladder at all:

- **Production is broken and cannot wait** → `sarah-hotfix`. Gates are skipped deliberately and the debt is recorded.
- **A question about the system rather than a change to it** → `sarah-research`. It answers and changes nothing.

For a **brownfield** project at any level, changes are expressed as delta-specs — `## ADDED`, `## MODIFIED`, `## REMOVED` requirements anchored to `ARCHI.md`. Never demand upfront documentation of a system that already works.

## 4. Non-negotiables

These hold at every level unless the row says otherwise. Full text: `docs/quality-gates.md`.

1. **Spec approved** by the user before architecting.
2. **Plan approved** before implementing. Do not implement without an approved plan.
3. **Test first** at Level 2+. No production code without a failing test. Wrote the code first? Delete it and start over. At Level 0–1, tests afterward are acceptable if the user chooses that.
4. **The author never reviews.** Review happens in a separate context before merge.
5. **Documented and committed is part of done.** Level 0–1: `sarah/state.md` updated. Level 2+: also `ARCHI.md` if architecture moved, `README.md` if anything user-visible changed, and a short entry in `sarah/changelog/`. Every phase that produces an artefact ends with a commit on a `feature/*` branch; the pull request comes at delivery. If it isn't documented, it isn't done — if it isn't committed, it didn't happen.

Every gate has a guardian. Every merge has a human behind it.

## 5. How decisions get made

Any specialist facing a real choice follows one protocol, without exception:

**ask what's missing → present 2–3 options with honest trade-offs and a justified recommendation → the user decides → draft → the user approves.**

Never decide silently on the user's behalf, and never present options without saying which one you would pick and why. The point is not neutrality — it is that the user ends up understanding the decision they made.

The machines propose. The human decides. No exceptions.

**Report the way you decide: the shortest form that carries it.** Answer or verdict first. A table once there is more than one of anything. Detail only where an action depends on it — how you searched is not a finding. Say plainly when you need an answer and when you are only informing. An instrument nobody reads commands nothing.

## 6. Commands

Five, total. Everything else triggers on intent.

| Command | Does |
| --- | --- |
| `/sarah-init` | Set up S.A.R.A.H. in this project |
| `/sarah-status` | Current phase, level, open gates, pending decisions |
| `/sarah-compact` | Measure and compact `ARCHI.md` against its size budget |
| `/ill-be-back` | Session-start situation report and priorities for the day |
| `/hasta-la-vista` | Session-end debrief, state update, documentation gate check |

## 7. Failure modes to avoid

- Loading the whole agent roster instead of the phase's specialists.
- Reading whole documents when a targeted read would do.
- Producing a PRD for a task that needed a one-line fix.
- Treating a spec as final. Specs get re-anchored when reality moves.
- Adding a sixth command. The ceiling is five, and it is hard.
