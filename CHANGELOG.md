# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-08-16

First public release. S.A.R.A.H. is a Claude Code plugin that runs a structured
development workflow: it sizes each request, routes it through the phases that
request actually needs, brings a specialist to each one, and stops at five gates
where a human decides.

This release ships with the comparative study that measured it. Read
[Evidence](README.md#evidence) before installing — it reports what the framework
did not do as well as what it did.

### Added

- **The routing layer.** `sarah-bootstrap` reads the state index, the file of the
  task the request belongs to, and the relevant parts of `ARCHI.md`; sizes the
  work into a scale level; and loads exactly one phase skill, which loads only
  its own specialists. Held under a 2,000-token budget because it is injected
  into every session.
- **Eight phases, as skills** — brainstorm, spec, architecture, design/UX,
  implement, review, release, and hotfix — each naming its own specialists and
  no others.
- **Ten specialist agents**, activated per phase: product analyst, product
  manager, software architect, security advisor, UX/UI designer, test engineer,
  developer, code reviewer, devops engineer, and release manager.
- **Five commands, and no sixth.** `/sarah-init`, `/sarah-status`,
  `/sarah-compact`, `/ill-be-back`, `/hasta-la-vista`. Everything else triggers
  on intent.
- **Five quality gates** with a human behind each: spec approved, plan approved,
  test written first at Level 2+, the author never reviews their own work, and
  documented-and-committed is part of done.
- **The itinerary.** At Level 2 and above, work opens with all eight steps as a
  table — in or out, the reason drawn from *this* request, the cost in your
  time — and any row can be overruled. Dropping a step is recorded, not argued
  with. Documentation is the one row that cannot be dropped.
- **Per-task state.** A `sarah/state.md` index plus one `sarah/state/<slug>.md`
  per task, created when work starts and deleted when it ships. Two features in
  parallel no longer collide on one file.
- **Session hooks.** `session-start` detects an initialized project, injects the
  bootstrap pointer, and suggests `/ill-be-back` when work is already in flight.
  Hooks are sensors: they report and never block, and exit 0 on every path.
- **Templates** copied into your project by `/sarah-init`: `ARCHI-template.md`
  (long-term architecture memory, held to a 10% context budget) and
  `README-template.md`.
- **Observability and rollback as release deliverables.** Gate 5 does not close
  on a release that cannot be observed and reversed, scaled by level.
  [docs/operating.md](docs/operating.md) states what that means for this plugin.
- **CI.** Manifest validation, hook syntax and never-blocks checks, skill
  frontmatter and body-size ceilings, the `sarah-bootstrap` token budget, and two
  guards against a public artefact naming private infrastructure or a
  developer's home directory.
- **Documentation.** [Quality gates](docs/quality-gates.md),
  [branching](docs/branching.md), [extending](docs/extending.md),
  [contributing](CONTRIBUTING.md), a [Level 1](docs/walkthrough-level-1.md)
  walkthrough and a [Level 3](docs/walkthrough-level-3.md) walkthrough of a real
  instrumented run.
- **The evidence.** Two comparative studies under [docs/study/](docs/study/),
  including the instrument failures that voided parts of them.

### Known limits

Stated here rather than discovered after installing.

- **On a well-specified brief, S.A.R.A.H. does not make Claude write better
  code.** Six blind-judged runs scored the framework 20.7/48 against 19.7 for
  plain Claude Code, at 21% more cost. An earlier study could not discriminate at
  all. Three attempts, three times without a verdict in the framework's favour.
  Full results in [docs/study/](docs/study/).
- **The human gates have never been measured.** Every instrumented run carried
  "do not ask me anything", which proves the automatic gates and cannot prove the
  ones a person stands behind.
- **Second-model review ships unexercised.** Runtime detection for a second-model
  CLI is in the framework for users who run one, but the tested path is the
  fresh-subagent fallback. This is a sharp edge, not a feature.
- **The pre-push guard is opt-in per clone.** `git config core.hooksPath
  .githooks` is a manual step, because git offers no way around it.
  [CONTRIBUTING.md](CONTRIBUTING.md) says so.

[Unreleased]: https://github.com/raphaelfribeiro/sarah-framework/compare/v0.1.0...develop
[0.1.0]: https://github.com/raphaelfribeiro/sarah-framework/releases/tag/v0.1.0
