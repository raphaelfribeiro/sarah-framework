# S.A.R.A.H.

[![License: MIT][license-shield]][license-url]
[![Status: alpha][status-shield]][status-url]
[![validate][ci-shield]][ci-url]

**Be prepared. Judgment Day is a deploy on Friday.**

Structured development workflow for Claude Code — specialist agents per phase, hard gates, human decisions.

*The machines write the code. You command the mission.*

**S**kills, **A**gents, **R**eviews & **A**daptive **H**ierarchy. A Claude Code
plugin that carries a project from the first idea to the release tag without
letting the workflow become a project of its own.

---

> [!WARNING]
> **v0.1 is not released.** The comparative study has now run three times. It
> does not show that S.A.R.A.H. produces better software than plain Claude Code.
> [Evidence](#evidence) has the numbers, including the ones that argue against
> us.

## What it does

Claude Code writes the code. S.A.R.A.H. decides what gets checked before it
reaches your repository, and hands you the decisions worth making.

- **Catches what the brief never said.** Security, limits, and scope are checked
  because the process checks them, not because someone remembered.
- **Remembers between sessions.** Tomorrow's session opens knowing what today's
  decided, without you re-explaining it.
- **Stops before merge.** A reviewer that never saw the code written looks for
  what the author could not see.
- **Shrinks to fit.** A typo gets none of this. A new product gets all of it.
- **Leaves the calls to you.** Real choices arrive as options with trade-offs
  and a recommendation. You decide; the machines never run the mission.

## Who it's for

| Use it when | Skip it when |
| --- | --- |
| The work spans several sessions | One session, one file, one answer |
| Nobody will read every line the model writes | You review everything yourself anyway |
| The brief is silent on security, limits and scope | Requirements are complete and explicit |
| Somebody else inherits the code | Throwaway scripts and spikes |
| Getting it wrong is expensive | Getting it wrong costs a retry |

## What it is not

**It does not make Claude write better code.** We tested that and published the
numbers below: on a well-specified brief, plain Claude Code scores the same and
costs about 20% less. If your requirements are complete and you read every diff,
you do not need this.

What it buys is coverage of what nobody specified, and continuity across
sessions. Pay for it when you need it.

## The workflow

Every step of the software lifecycle has an owner here. You see the map on day
one, and at every handover you are told where you are, what comes next, and what
was skipped for the size of the work.

| Step | Phase | Specialist | Delivers |
| --- | --- | --- | --- |
| Brainstorm & architecture | `brainstorm` → `architecture` | product-analyst, software-architect | Scope options, stack, boundaries, decision records |
| Business analysis | `spec` | product-manager | Requirements with acceptance criteria and a cut line |
| System analysis | `architecture` | software-architect | Data ownership, failure behaviour, contracts |
| UI/UX design | `design-ux` | ux-ui-designer | Flows and every screen state, including empty and error |
| Build & QA | `implement` | developer, test-engineer | Failing test first, then the code |
| Security | `architecture` + `review` | security-advisor | Auth, secrets, input trust, data exposure |
| Documentation | Gate 5, every phase | all | State, architecture and changelog current, or it is not done |
| Deploy, monitor & operate | `release` | devops-engineer, release-manager | CI/CD pipeline, version, release notes, observability and rollback |

**You choose the route.** At Level 2 and above, work opens with the itinerary:
all eight steps, in or out, why each call was made *for this request*, and what
each one costs you in time. Change any row and it changes.

```
Level 2 · itinerary for: webhook retry limit

  step             | why here                        | cost
  -----------------|---------------------------------|------
  [ ] Brainstorm   | problem already stated          | ~10min
  [x] Business an. | no acceptance criteria yet      | ~10min
  [x] System an.   | crosses a data boundary         | ~15min
  [ ] UI/UX        | no user-facing surface          | ~20min
  [x] Build & QA   | always                          | —
  [x] Security     | untrusted input from outside    | ~10min
  [x] Docs         | gate 5                          | ~5min
  [x] Deploy       | goes to production              | ~10min

→ enter to proceed · "add ux" · "drop system analysis" · "why?" for the trade-offs
```

**Nothing is skipped silently, and nothing is forced.** Drop a step and it is
recorded, not argued with — the one exception is documentation, because gate 5
is what makes the next session possible. A typo fix gets no table at all; eight
rows to justify a rename is the ceremony this framework exists to prevent.

## Quickstart

```
/plugin marketplace add raphaelfribeiro/sarah-framework
/plugin install sarah@sarah-framework
/sarah-init
```

`/sarah-init` reads your repository, works out whether it is greenfield or
brownfield, and interviews you only for what it could not learn on its own.

After that, stop typing commands. Describe what you want and the framework
routes itself.

## How it works

Every request passes through `sarah-bootstrap`, which reads the state index, the file of the task it belongs to, and
the relevant parts of `ARCHI.md`, sizes the work, and loads exactly one phase
skill — which loads only its own specialists.

**Sizing is the whole game.** Getting it wrong in either direction is the most
expensive mistake available: ceremony on a typo wastes an afternoon, and no
ceremony on a product wastes a month.

| Level | Looks like | Gets |
| --- | --- | --- |
| **0** Trivial | Typo, rename, config tweak | Straight to code |
| **1** Small | Bug fix, contained feature | Mini-plan → developer → reviewer |
| **2** Medium | Several components, a new boundary, a schema change | Lean spec and plan |
| **3** Large | New product or subsystem, unsettled requirements | Full pipeline, all gates |

Then five gates, each with a human behind it:

1. **Spec approved** before architecting.
2. **Plan approved** before implementing.
3. **Test first** at Level 2+. Wrote the code first? Delete it and start over.
4. **The author never reviews.** Review happens in a separate context.
5. **Documented and committed is part of done.** Every phase that produces an
   artefact ends with a commit; the pull request comes at delivery.

Walkthroughs: [Level 1](docs/walkthrough-level-1.md) ·
[Level 3](docs/walkthrough-level-3.md) (a real, instrumented run).

## Commands

Five, total. Everything else triggers on intent.

| Command | Does |
| --- | --- |
| `/sarah-init` | Set up S.A.R.A.H. in this project |
| `/sarah-status` | Current phase, level, open gates, pending decisions |
| `/sarah-compact` | Measure and compact `ARCHI.md` against its size budget |
| `/ill-be-back` | Session-start situation report and the day's priorities |
| `/hasta-la-vista` | Session-end debrief, state update, documentation check |

## Evidence

Claims about developer workflows are cheap. Here is what has actually been
measured, and what has not.

**Measured.** The Level 3 pipeline was run end to end twice, the second time
instrumented from step one so that every tool call and subagent spawn was
captured. Against an empty directory it produced a tagged `v0.1.0` with 159
passing tests, in roughly 90 minutes and $39.64 of model time. Gate 3 was
observed holding — the suite ran red five times with `ModuleNotFoundError`
while `src/` contained nothing but a three-line package `__init__`. Gate 4
blocked the delivery with four findings, the worst of them a symlink escape that
wrote outside the notes directory, and the reviewers noted that the 147 passing
tests covered none of the four scenarios. Details in
[the Level 3 walkthrough](docs/walkthrough-level-3.md).

**The comparison, third attempt, 2026-08-15.** Same brief, six builds — three
with S.A.R.A.H., three with plain Claude Code — then three changes each in cold
sessions, scored blind by three judges per artefact against a 24-item rubric
built to be failable. US$ 308.63.

| | S.A.R.A.H. | Plain Claude Code |
| --- | --- | --- |
| Score (median of 3 judges, out of 48) | **20.7** | 19.7 |
| Range across runs | 17 – 24 | 17 – 22 |
| Cost per build | **$34.13** | $28.30 |
| Security items | **2.6** | 1.0 |
| Restraint — no unrequested surface | **3.2** | 2.0 |
| Resource behaviour | 2.6 | **3.6** |
| Documentation that executes | 3.9 | **4.9** |
| Maintainability | 3.6 | **4.4** |

**Read it honestly.** One point out of 48 is not a difference — the arms overlap
almost entirely, and the worst run in the study is a tie between them. The
framework costs 21% more. The section-level pattern is the only interesting
thing here: it wins where the brief is silent and loses where the work is
direct, which is what a checklist should do and no proof that it did.

**And the blinding leaked.** A separate reader, asked after scoring, identified
all three framework artefacts with 87–94% confidence, citing the scars left by
stripping the process documents out of them. Two of three controls were correctly
called. So even the one-point difference is not a blind measurement. This is a
design problem, not a bug: a framework that produces process documents which the
code then references cannot be hidden by rewriting text.

Three attempts, three times without a verdict. The instrument now discriminates
— scores spread 35% to 50%, against 43–44 out of 44 in the attempt below — and
that is the part we would defend.

**Earlier attempt, inconclusive, 2026-08-07.** A controlled study was run: the
same brief built three times with S.A.R.A.H. and three times with plain Claude
Code, scored blind by three judges per artefact against a rubric fixed in
advance. It failed twice over, and both failures are the author's.

**The rubric saturated** — every artefact scored 43 or 44 out of 44 — so it
could not detect a difference in either direction. **And the arms were
confounded**: the harness ran the control with `--setting-sources project` and
the framework arm with the default, which also loads user settings, so one arm
received the maintainer's own `CLAUDE.md` and the other received none of it. The
comparison was framework-plus-personal-context against a bare CLI. It went
unnoticed through eighteen blind scores and was found on 2026-08-09, while
reviewing something else; the visible symptom had been sitting in the artefacts
the whole time, two of three framework-arm builds written in Portuguese and none
of the control's.

Neither failure is a verdict on the framework, and the second is the more
serious: a saturated instrument measures nothing, but a confounded one measures
the wrong thing while looking like it worked. Both are fixed for the next
attempt — a rubric that can be failed, and two arms that load identical setting
sources with the framework reaching its arm through `--plugin-dir` alone.

One finding survives independently, because it does not require comparing the
arms: on the four security requirements the brief deliberately never states —
timing-safe comparison, replay window, idempotency, raw-body signing — **plain
Claude Code scored full marks in all three runs**. The implicit-requirement gap
that process is often sold to close was already closed here.

Two measurements are reliable regardless of the rubric, though the confound
touches them too: the framework cost more ($46.28 against $29.19 median), and
its cost was far less predictable — a 2.7× spread across its runs against 1.06×
for the control. The arm that cost more is also the arm carrying more always-on
instructions, and these runs cannot separate the two.

Read [the Phase F results](docs/study/results-phase-f.md), [the first
attempt](docs/study/results.md), [the method](docs/study/method.md)
committed before any run, [the incident log](docs/study/incidents.md) including
two errors of the author's own, and [the raw scores](docs/study/scores/).

**What remains unmeasured.** The human gates have never been exercised: driving
the CLI headlessly requires telling it not to ask questions, which is precisely
what gates 1 and 2 are made of. Blinding also stripped every ADR, spec and plan
from the judged packets — the framework's most distinctive output could not be
scored at all. Treat the five commitments above as design intent, not
demonstrated results.

## How it compares

Honest positioning. None of these projects has published a controlled comparison
against working without them. S.A.R.A.H. now has one, and it does not favour
S.A.R.A.H.: same scores as plain Claude Code, 21% more cost. Read that as the
standard the others have not yet been held to, not as a point in our favour.

| | Scope | Runs on | Process weight |
| --- | --- | --- | --- |
| [**BMAD-METHOD**](https://github.com/bmad-code-org/BMAD-METHOD) | Agile team simulation with specialist agent personas | Tool-agnostic | Heavy by design: detailed PRDs and architecture documents up front |
| [**GitHub Spec Kit**](https://github.com/github/spec-kit) | Spec-driven: spec → plan → tasks → implement → review | 30+ agents | Spec-first on every change |
| [**OpenSpec**](https://github.com/Fission-AI/OpenSpec) | Lightweight SDD: propose → apply → archive, with a living spec | 30+ agents | Light, spec-centred |
| [**Superpowers**](https://github.com/obra/superpowers) | Composable skills: TDD, systematic debugging, subagent review | Many harnesses, including Claude Code | Disciplined: red-green-refactor enforced |
| **S.A.R.A.H.** | Eight-step lifecycle with per-step specialists, five gates, and observability at the end | Claude Code only | Adaptive: levels 0–3 decide how much process applies |

<sub>Checked against each project's own documentation on 2026-08-06. These
projects move; if something here is out of date or unfair,
[tell us](https://github.com/raphaelfribeiro/sarah-framework/issues) and it gets
corrected.</sub>

**What is genuinely different here:** the scale level. BMAD, Spec Kit and
OpenSpec apply their process to the work in front of them; S.A.R.A.H. first
decides how much process the work deserves, and a Level 0 change gets none of
it. The second difference is the context budget treated as a hard constraint —
never loading the full agent roster, and a session-injected orientation skill
capped at roughly 2,000 tokens, enforced in CI.

**Where the others are ahead.** Superpowers is the closest relative — composable
skills, enforced TDD, subagent review — and it is released and runs across many
harnesses, while S.A.R.A.H. is neither. Spec Kit has GitHub behind it. OpenSpec
is lighter to adopt. BMAD has a real extension ecosystem. **S.A.R.A.H. runs on Claude Code only**, because it is
built on the plugin API, skills, and subagents — a real limitation, not a design
virtue, if your team is not on Claude Code.

If you want a workflow portable across many agents, one of the others is the
better fit today. S.A.R.A.H. is for people who want the process to shrink when
the work is small and to bring the right specialist when it is not.

## Documentation

- [Quality gates](docs/quality-gates.md) — the five gates in full
- [Branching](docs/branching.md) — the gitflow model this project uses
- [Operating a release](docs/operating.md) — how a release is cut, how you know
  it is working, and the way back
- [Changelog](CHANGELOG.md) — what shipped in each version
- [Extending](docs/extending.md) — the tracker and second-model contracts
- [Contributing](CONTRIBUTING.md) — how to work on the framework itself
- [Architecture](ARCHI.md) — how S.A.R.A.H. is built

## Contributing

Questions, bug reports, and feature ideas:
[open an issue](https://github.com/raphaelfribeiro/sarah-framework/issues).
The most valuable report this project can receive is a phrasing that should have
fired a skill and did not — a skill that does not trigger does not exist.

See [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

MIT © Raphael Ribeiro. See [LICENSE](LICENSE) for the full text.

---

*No fate but what we ship.*

[license-shield]: https://img.shields.io/badge/license-MIT-blue.svg
[license-url]: LICENSE
[status-shield]: https://img.shields.io/badge/status-alpha-orange.svg
[status-url]: #evidence
[ci-shield]: https://github.com/raphaelfribeiro/sarah-framework/actions/workflows/validate.yml/badge.svg
[ci-url]: https://github.com/raphaelfribeiro/sarah-framework/actions/workflows/validate.yml
