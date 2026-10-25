# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-10-25

Documentation only. Nothing the plugin runs has changed.

### Documentation

- The README says how to update from an earlier version, and how a project set
  up before 0.2.0 gets the habits catalog.
- The branching guide describes the protection the origin actually enforces:
  `main` and `develop` refuse deletion and non-fast-forward pushes.

## [0.2.0] - 2026-10-24

The habits that earned their place. v0.1.0 gave a project structure (phases,
state, gates) and no operating habits. This release adds a catalog of them,
each tied to a failure it prevents, offered by `/sarah-init` in plain words and
**installed only if you pick it**. Decline them all and nothing is installed and
nothing can block you.

### Added

- **The habit catalog in `/sarah-init`.** Seven choices: a Trello board, a model
  per task, a task re-check before it starts, a separate copy per task, keeping
  working while work waits, protecting the main line, and a release-note line per
  delivery. The interview covers the whole catalog every time and shows what each
  one may stop, with technical names only on "details".
- **`scripts/habits.py`, the installer.** Copies pinned, stamped payloads into the
  project after you approve the exact diff, records them in `sarah/habits.md`,
  registers their hooks, and removes only what it installed. A file you edited, or
  one you already had, is a conflict you decide, never overwritten.
- **Agreements that live in your project.** The plugin's own hooks still only
  report. The checks that may block are files in your repository: the gitflow
  guard, the changelog-fragment guard, the dispatch guard
  (model set, premise re-checked, task limit, own worktree) and a Stop hook that
  blocks once while ready work waits. Exceptions need a reason and expire within
  14 days.
- **Autonomy grants.** Set at init, quoted in your words, revocable: pushing
  feature branches, and merging a feature branch on green CI. Deleting for
  good, rewriting history, spending money and touching credentials are always
  asked, installed as `permissions.ask` rules, and so are edits to the agreements
  themselves (`sarah/habits.md`, `sarah/hooks/`, `sarah/exceptions.log`).
- **An `executor` agent**, dispatched with the model and effort each task
  declares, answering in a fixed four-part report (done, proof, not finished,
  requested tasks), plus a three-depth brief and a premises check before dispatch.
- **A tracker seam.** `scripts/tracker.py` with a Trello adapter: intake of ready
  cards, card sync, moving a shipped task's card to Done, and a once-a-day audit as one self-closing card. Local state is
  the source of truth; credentials come from `TRELLO_API_KEY` and `TRELLO_TOKEN`,
  never from the chat, and a public board is refused.
- **Working defaults** printed at session start (decisions as questions, no
  "continue?" inside an approved plan, run it yourself, short plain reports,
  verified facts, remembered decisions), each switchable in `sarah/habits.md`, and
  lasting decisions kept in `sarah/decisions.md`.
- **Habit status lines at session start** (habits, tracker, daily audit,
  exceptions) inside a 400-token budget, and a size sensor for the state files.
- **Shorter rituals.** `/ill-be-back` and `/hasta-la-vista` print at most ten lines,
  verdict first; the close asks one question, and the agent commits.
- **Release notes read `User-facing:` lines** from the changelog entries of
  projects that chose the changelog habit.
- **Tests.** Unit, integration, static and shell suites, run in CI.

### Changed

- With the `merge-on-green` grant recorded, a feature branch merges without a
  human on green CI; `grant revoke merge-on-green` ends it. This supersedes "every merge has a human behind it" for those projects
  only; cutting a release stays a user decision.
- `sarah-bootstrap` points at `references/task-template.md` inside its own
  directory, where a skill can read it, and a static test now checks every skill's
  `references/` links.
- The development `CLAUDE.md` moved to `.claude/CLAUDE.md`, so
  `claude plugin validate . --strict` passes again.
- `sarah/state.md` is held to 8 KB and each task file to 16 KB, measured at session
  start.
- The allowed-hosts list gains the Trello API and board-link hosts.

### Known limits

- **The guards are a guardrail against mistakes, not a security boundary.** They
  judge the usual invocation forms; `sh -c`, `eval`, `xargs`, `sudo` and
  variables are not parsed, and an agent determined to get round them can.
- **The tracker has never met the live Trello API.** It is tested against a local
  stub and ships untested against the real service; a smoke test on a throwaway
  board comes before any claim that it works.
- **A forced platform model fallback is not reported**, and with
  `CLAUDE_CODE_EFFORT_LEVEL` set the Agent tool loses per-call `effort`, so every
  executor runs at that level. See [operating](docs/operating.md).
- The habits rest on platform behaviour probed on Claude Code CLI 2.1.308 and not
  promised by the public docs; re-probe on a major version.
- Python 3 is needed by any habit that installs or calls a script, and `jq` by the
  guards. Without them those habits are not offered.
- **No study measures whether these habits help.** The v0.1.0 findings stand.
- Grants in a team repository apply to every collaborator's agent.

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
  leak guards written as allowlists rather than denylists — `scripts/allowed-hosts.txt`
  names the hosts this repository may reference, and a path guard that includes
  itself in its own search. Neither has an exclusion, because an exclusion is a
  place a leak can hide.
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

[Unreleased]: https://github.com/raphaelfribeiro/sarah-framework/compare/v0.2.0...develop
[0.2.0]: https://github.com/raphaelfribeiro/sarah-framework/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/raphaelfribeiro/sarah-framework/releases/tag/v0.1.0
