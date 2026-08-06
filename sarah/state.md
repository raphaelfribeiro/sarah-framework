# S.A.R.A.H. state

**Updated:** 2026-08-06

| | |
| --- | --- |
| **Phase** | 5-implement |
| **Default level** | 3 |
| **Mode** | greenfield |
| **Current task** | Build S.A.R.A.H. v0.1 — Phases A, B and C complete; Phase C awaiting review |
| **Task level** | 3 |

## In flight

- Phases A, B and C delivered. 15 skills, 10 agents, 3 hooks, one script, ~3,090 tokens always-on. Awaiting the maintainer's review before Phase D opens.
- The Level 3 pipeline was exercised end to end on 2026-08-05 and held. See *Carried into Phase D* for what it proved and what it did not.
- **2026-08-06, instrumented from step 1 — both open questions settled.** Gate 3 holds: eight test files written, the suite run five times, red every time with `ModuleNotFoundError`, and `src/` holding nothing but a three-line package `__init__`. The specialists fire unprompted: `product-analyst` (brainstorm), `software-architect` + `security-advisor` (architecture), `ux-ui-designer` (design), `test-engineer` + `developer` (implementation). Phase 6 was cut by a session rate limit and resumed, so this is not a clean uninterrupted run; the resumed half spawned no subagent, the orchestrator finished the code itself. Every prompt carried "do not ask me anything", which proves the automatic gates and cannot prove the human ones. 147 tests pass, verified by an independent run. Phases 7 and 8 not yet run — one phase at a time, on explicit approval. Logs outside the repository.

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
| Review passed | pending | Phase C under review by the maintainer |
| Documentation done | done | 2026-08-05 |

## Publication

The repository is **public**. It mirrors automatically, so a push is a publish.
Commit freely; push only on an explicit decision. Nothing versioned here may
reveal the maintainer's internal infrastructure — clone URLs, badges, issue
links, and CI all reference GitHub and nothing else.

## Next

1. **Re-run the Level 3 pipeline instrumented from step 1**, against a fresh project directory, to settle the two things the 2026-08-05 run could not: whether gate 3 ever runs red before the source exists, and whether `product-analyst`, `software-architect` and `ux-ui-designer` are actually spawned. Use `--output-format stream-json` on every step, not just the last three. Roughly 45 minutes.
2. Maintainer signs off on Phase C.
3. Phase D — the full README with the honest comparison against BMAD, Spec Kit, Superpowers, TRIP and OpenSpec; `docs/` including `extending.md` with the tracker extension contract; a Level 1 and a Level 3 walkthrough; GitHub Actions validation; `CONTRIBUTING.md` and issue and PR templates.
4. **Phase E — the evidence study. Blocks v0.1.** Build the same minimal project
   twice, once with S.A.R.A.H. and once without, under one instrumented harness,
   and publish the measured comparison in the repository. Real data, stated
   method, stated limitations. Charts where they carry the argument better than
   prose. This is a release requirement, not an appendix: without it the claim
   that the framework earns its cost is an assertion, and the audience is
   international.

   Design approved 2026-08-06: **n=3 per arm** — three runs with the framework
   and three without, same brief, same harness, same model — against a **new,
   harder brief** than the notes CLI, chosen to contain ambiguous requirements,
   a real architectural decision, an error surface and some security risk.
   Scoring is **blind**: judges receive the six artefacts without being told
   which arm produced which, and score against a rubric derived from the brief.
   The control arm is plain Claude Code used well, not a straw man, and the
   study must be able to come out unfavourable. Measured, never estimated:
   tests present and passing, real coverage, requirements met, defects and
   security findings from blind judges, tokens and wall-clock from the
   stream-json, documentation volume, commits.
5. Then v0.1: decide whether to push. The repository is public and mirrors automatically, so the first push is the publication.

## Carried into Phase D

- **The Level 3 pipeline now runs end to end — with two things still unproven.** Exercised on 2026-08-05 against a real greenfield CLI: all eight steps from `/sarah-init` through release, 144 tests passing, three commits, `v0.1.0` tagged, CI workflow generated. Gate 4 held without a human in the loop — `code-reviewer` and `security-advisor` were both spawned unprompted, and the review produced three blockers and four minor findings that took their own commit to fix. **Still unproven:** gate 3 (tests before code) was never observed running red, and steps 1 to 5 ran without instrumentation, so whether `product-analyst`, `software-architect` and `ux-ui-designer` actually fired is unknown. Re-running instrumented from step 1 settles both. Evidence in the run logs, outside the repository.
- **`sarah-bootstrap` sits at ~1,838 tokens against its own 2,000 ceiling.** Anything added there in future now requires removing something.
- **Gate 5 now requires a commit, and nothing enforces it at runtime.** Two instrumented runs ended implementation with a passing suite and zero commits, so the gate was rewritten and six phase skills now close their own loop. The framework is prose a model reads: whether phase-closing commits actually happen is measurable only by instrumenting another run, and that measurement is now part of what Phase E has to report.
