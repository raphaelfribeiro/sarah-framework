# S.A.R.A.H. state

**Updated:** 2026-08-07

| | |
| --- | --- |
| **Phase** | 5-implement |
| **Default level** | 3 |
| **Mode** | greenfield |
| **Current task** | Build S.A.R.A.H. v0.1 — Phases A to E delivered; the study was inconclusive and the release decision is open |
| **Task level** | 3 |

## In flight

- Phases A, B, C and D delivered. 15 skills, 10 agents, 3 hooks, one script, ~3,090 tokens always-on. Phase D added CI validation, CONTRIBUTING, issue and PR templates, `docs/extending.md`, both walkthroughs, and a README rewritten around evidence rather than claims. **Phase E is the only thing left before v0.1.**
- The Level 3 pipeline was exercised end to end on 2026-08-05 and held. See *Carried into Phase E* for what it proved and what it did not.
- **2026-08-06, instrumented from step 1 — both open questions settled.** Gate 3 holds: eight test files written, the suite run five times, red every time with `ModuleNotFoundError`, and `src/` holding nothing but a three-line package `__init__`. The specialists fire unprompted: `product-analyst` (brainstorm), `software-architect` + `security-advisor` (architecture), `ux-ui-designer` (design), `test-engineer` + `developer` (implementation). Phase 6 was cut by a session rate limit and resumed, so this is not a clean uninterrupted run; the resumed half spawned no subagent, the orchestrator finished the code itself. Every prompt carried "do not ask me anything", which proves the automatic gates and cannot prove the human ones. Gate 4 stopped the delivery with four blocking findings, including `edit` writing through a symlink to outside the notes directory; the reviewers noted the 147 passing tests covered none of the four. Fixes produced twelve new tests — 159 passing, verified independently — and re-ran the reviewers unprompted. All eight phases completed: `v0.1.0` tagged, CI generated, $39.64 and ~90 minutes end to end. Logs outside the repository.

## Blocked

- Nothing blocked.

## Pending decisions

Nothing pending. Resolved on 2026-08-05:

| Decision | Outcome |
| --- | --- |
| Second-model CLI for gate 4 | **Claude only.** No second-model CLI will be installed. The fresh-subagent fallback becomes the primary, exercised review path. Runtime detection stays in the framework for users who do run one, but ships unexercised — recorded as a sharp edge, not a tested feature. |
| Repository name | **`sarah-framework`**, matching the plugin's published identity. Renamed and made public on 2026-08-05. No versioned file changed: every URL already used that name. |
| Branching model | **gitflow.** `main` holds released versions, `develop` holds the next one, work happens on `feature/*`, `release/*` and `hotfix/*`. Chosen over GitHub Flow by the maintainer. Recorded in `docs/branching.md`; the push hook already treated `develop` as protected, and the generated README template already parameterised its base branch, so neither needed changing. |

## Gates

| Gate | Status | When |
| --- | --- | --- |
| Spec approved | approved | 2026-08-05 |
| Plan approved | approved | 2026-08-05 |
| Tests written first | n/a | Phase A ships no executable code beyond one hook, exercised across eight scenarios |
| Review passed | approved | 2026-08-06 — Phase C signed off by the maintainer. `feature/commit-and-pr-are-part-of-done` reviewed separately by `sarah:code-reviewer` in a clean context, which blocked once and passed on re-verification. |
| Documentation done | done | 2026-08-05 |

## Publication

The repository is **public**. It mirrors automatically, so a push is a publish.
Commit freely; push only on an explicit decision. Nothing versioned here may
reveal the maintainer's internal infrastructure — clone URLs, badges, issue
links, and CI all reference GitHub and nothing else.

## Next

1. **Decide what an inconclusive study means for v0.1.** The comparison ran, cost $280.76, and could not discriminate: the rubric saturated at 43-44 out of 44 for every artefact in both arms. Options are to ship v0.1 with the study published as the honest inconclusive result it is, or to build a discriminating rubric and re-run before releasing. This is the maintainer's call and nothing should move until it is made.
2. Then v0.1: decide whether to push. The repository is public and mirrors automatically, so the first push is the publication.

## Carried forward

- **The Level 3 pipeline runs end to end, and the two open questions are closed.** Exercised twice: 2026-08-05 uninstrumented from step 1, and 2026-08-06 instrumented throughout. Gate 3 holds and gate 4 stops deliveries; every phase spawns its own specialists without being asked. What each run could and could not prove is recorded in `sarah/changelog/2026-08-05-level-3-pipeline-verified.md` and `sarah/changelog/2026-08-06-level-3-instrumented.md`. **What no run has proven:** the human gates, because headless prompts must say "do not ask me anything"; and whether the framework's contribution is separable from the model's, which is what Phase E exists to measure. Evidence in the run logs, outside the repository.
- **The evidence study ran and could not discriminate.** Six builds of one brief, three per arm, eighteen blind scores, $280.76. Every artefact scored 43-44 out of 44, so the rubric had no room to record a difference. Inconclusive about the framework in both directions. One finding stands on its own: on the four security requirements the brief never states, plain Claude Code scored full marks in all three runs. Cost and its variance are the reliable measurements - the framework arm spread 2.7x against the control's 1.06x. Full writeup in `docs/study/`.
- **`sarah-bootstrap` sits at ~1,574 tokens against its own 2,000 ceiling**, measured 2026-08-06. Anything added there still costs every session, so additions stay in words rather than lines.
- **Gate 5 now requires a commit, and nothing enforces it at runtime.** Three instrumented runs ended implementation with a passing suite and no commits — the third collapsed eight phases into three commits at release time, one of them 2,849 lines with the review fixes fused into the code under review. The gate was rewritten and all seven phase skills now close their own loop. The framework is prose a model reads: whether phase-closing commits actually happen is measurable only by instrumenting another run, and that measurement is now part of what Phase E has to report.
