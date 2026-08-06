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
> **v0.1 is not released.** The pipeline is built and has been exercised end to
> end, but the comparative study that would justify the claims below is not
> done. See [Evidence](#evidence) for exactly what has and has not been
> measured.

## Why S.A.R.A.H.?

Unsupervised AI ships fast and breaks everything. S.A.R.A.H. exists so the
machines never run the mission — you do.

Five commitments, held together:

1. **Specialist expertise, on demand.** The full team exists — architecture,
   UX, security, DevOps, QA — but only the current phase's specialists enter
   context. Having the roster is not the same as activating it.
2. **Scale that actually adapts.** A typo reaches code in minutes. A new product
   goes through the whole pipeline. The process depth *and* the number of active
   agents follow the size of the work.
3. **Decisions taught, not made for you.** Every real choice arrives as two or
   three options with honest trade-offs and a justified recommendation. You
   decide. You come away understanding why.
4. **A workflow that disappears.** Skills fire on intent. There are five
   commands, and that ceiling is hard.
5. **Brownfield without ceremony.** Existing projects work in delta-specs
   anchored to a curated architecture memory, never a monolithic upfront rewrite
   of documentation nobody asked for.

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

Every request passes through `sarah-bootstrap`, which reads `sarah/state.md` and
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

**Not measured, and not claimed.** No controlled comparison exists yet. Nothing
published here separates what the framework contributed from what the model
would have done anyway, and the runs above cannot settle that because they have
no control arm. The human gates have never been exercised either: driving the
CLI headlessly requires telling it not to ask questions, which is precisely what
gates 1 and 2 are made of.

**A comparative study is a release requirement for v0.1** — the same brief built
with and without the framework, scored blind, with the method and its limits
published alongside the numbers. Until that exists, treat the five commitments
above as design intent rather than demonstrated results.

## How it compares

Honest positioning, with the caveat that the comparative evidence above does not
exist yet for any of these — including S.A.R.A.H.

| | Scope | Runs on | Process weight |
| --- | --- | --- | --- |
| [**BMAD-METHOD**](https://github.com/bmad-code-org/BMAD-METHOD) | Agile team simulation with specialist agent personas | Tool-agnostic | Heavy by design: detailed PRDs and architecture documents up front |
| [**GitHub Spec Kit**](https://github.com/github/spec-kit) | Spec-driven: spec → plan → tasks → implement → review | Many agents | Spec-first on every change |
| [**OpenSpec**](https://github.com/Fission-AI/OpenSpec) | Lightweight SDD: propose → apply → archive, with a living spec | Many agents | Light, spec-centred |
| [**Superpowers**](https://github.com/obra/superpowers) | Composable skills: TDD, systematic debugging, subagent review | Many harnesses, including Claude Code | Disciplined: red-green-refactor enforced |
| **S.A.R.A.H.** | Phase pipeline with per-phase specialists and five gates | Claude Code only | Adaptive: levels 0–3 decide how much process applies |

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
skills, enforced TDD, subagent review — and it is mature, widely installed, and
runs across many harnesses while S.A.R.A.H. is unreleased and runs on one. Spec
Kit has GitHub behind it. OpenSpec is lighter to adopt. BMAD has a real
extension ecosystem. **S.A.R.A.H. runs on Claude Code only**, because it is
built on the plugin API, skills, and subagents — a real limitation, not a design
virtue, if your team is not on Claude Code.

If you want a workflow portable across many agents, one of the others is the
better fit today. S.A.R.A.H. is for people who want the process to shrink when
the work is small and to bring the right specialist when it is not.

## Documentation

- [Quality gates](docs/quality-gates.md) — the five gates in full
- [Branching](docs/branching.md) — the gitflow model this project uses
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
