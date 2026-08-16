# S.A.R.A.H. state

**Updated:** 2026-08-15

| | |
| --- | --- |
| **Default level** | 3 |
| **Mode** | greenfield |

## In flight

| Task | File | Phase | Level | Waiting on | Since |
| --- | --- | --- | --- | --- | --- |
| v1 readiness — evidence, visibility, and the state model | `sarah/state/v1-readiness.md` | 5-implement, complete | 3 | **you — publish v1, or not** | 2026-08-15 |

## Carried forward

- **The Level 3 pipeline runs end to end, and the two open questions are closed.** Exercised twice: 2026-08-05 uninstrumented from step 1, and 2026-08-06 instrumented throughout. Gate 3 holds and gate 4 stops deliveries; every phase spawns its own specialists without being asked. What each run could and could not prove is recorded in `sarah/changelog/2026-08-05-level-3-pipeline-verified.md` and `sarah/changelog/2026-08-06-level-3-instrumented.md`. **What no run has proven:** the human gates, because headless prompts must say "do not ask me anything"; and whether the framework's contribution is separable from the model's, which is what Phase E exists to measure. Evidence in the run logs, outside the repository.
- **Framework v2 exists but is unproven.** `feature/framework-v2-lean` rewrites the review gate to probe with hostile input and rehearse a cold start, refuses README-not-run and production test seams, cuts phase-boundary ceremony, and keeps three artefacts an independent analysis found genuinely valuable: invariants stated with the consequence no test would catch, superseded decisions with their reason, and the deliberately-not-tested list. Whether any of it helps is exactly what Phase F was started to measure, and Phase F is paused.
- **Three instrument bugs of my own, all the same shape.** The blinding sanitizer deleted whole lines and truncated prose in one arm only (~15% of the evidence base). The harness treated a rate-limited step as complete, so one artefact was judged having never had a review. And a framework-use check counted tool calls, but slash commands are expanded before becoming tool calls - it voided a valid run. The pattern: **my own spot checks are less trustworthy than the instrumented procedure, and when they disagree the procedure wins unless I can show otherwise.**
- **The evidence study ran and could not discriminate — for two independent reasons.** Six builds of one brief, three per arm, eighteen blind scores, $280.76. Every artefact scored 43-44 out of 44, so the rubric had no room to record a difference. And the arms were confounded: the control ran without the maintainer's user settings and the framework arm ran with them, so the comparison was framework-plus-personal-context against a bare CLI. The second reason is the more serious — a saturated instrument measures nothing, but a confounded one measures the wrong thing while looking like it worked. Inconclusive about the framework in both directions. One finding stands on its own: on the four security requirements the brief never states, plain Claude Code scored full marks in all three runs. Cost and its variance are the reliable measurements - the framework arm spread 2.7x against the control's 1.06x. Full writeup in `docs/study/`.
- **`sarah-bootstrap` sits at ~1,574 tokens against its own 2,000 ceiling**, measured 2026-08-06. Anything added there still costs every session, so additions stay in words rather than lines.
- **Gate 5 now requires a commit, and nothing enforces it at runtime.** Three instrumented runs ended implementation with a passing suite and no commits — the third collapsed eight phases into three commits at release time, one of them 2,849 lines with the review fixes fused into the code under review. The gate was rewritten and all seven phase skills now close their own loop. The framework is prose a model reads: whether phase-closing commits actually happen is measurable only by instrumenting another run, and that measurement is now part of what Phase E has to report.
