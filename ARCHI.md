# Architecture — S.A.R.A.H.

> Long-term architecture memory. Read at the start of every task, updated at the
> end of every architectural change. Curated by hand, never auto-generated.

**Last updated:** 2026-08-05 · **Scale level:** 3 · **Mode:** greenfield

---

## 1. What this system is

S.A.R.A.H. — Skills, Agents, Reviews & Adaptive Hierarchy — is a Claude Code
plugin that imposes a structured development workflow on AI-assisted software
work, from the first idea to the release tag. It is aimed at developers who want
the speed of an agent without surrendering judgment to it: specialist personas
activate per phase rather than all at once, hard gates stand between phases, and
every meaningful decision reaches the user as options with trade-offs.

The framework carries almost no executable code. It is a body of instructions
that a model reads at runtime, which makes its architecture a question of what
loads into context, when, and at what cost.

## 2. Stack

| Layer | Technology | Notes |
| --- | --- | --- |
| Runtime host | Claude Code plugin system | Requires v2.1.142+ for current skill-loading rules; validated against v2.1.221 |
| Content | Markdown with YAML frontmatter | Skills, agents, and templates are prose read by the model |
| Manifests | JSON | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` |
| Hooks | POSIX `sh` | No bashisms; runs on macOS, Linux, and Git Bash |
| Scripts | Python 3, standard library only | Token measurement for `/sarah-compact` |
| CI | GitHub Actions | Manifest validation, frontmatter and size linting |

## 3. System shape

The repository is three things at once: a **marketplace** (it publishes a
catalog), a **plugin** (it is the sole entry in that catalog, sourced from the
repository root), and a **project running S.A.R.A.H. on itself**.

- **`.claude-plugin/`** — the manifests. `marketplace.json` lists one plugin
  whose `source` is `"./"`, so the repository root is the plugin root.
- **`skills/`** — the framework's behavior. Each subdirectory holds a `SKILL.md`
  whose frontmatter is always in context and whose body loads on invocation.
  This is where nearly all of S.A.R.A.H. actually lives.
- **`agents/`** — the specialist roster. Personas with a model tier, loaded by
  phase skills, never all at once.
- **`hooks/`** — `hooks.json` plus POSIX shell scripts. Sensors only: they
  report and never block.
- **`templates/`** — the artifacts `/sarah-init` and the phase skills copy into
  the *user's* project. Authoring guidance lives in HTML comments that
  generation strips.
- **`docs/`** — documentation of the framework for humans, not for the model.

### How a request flows

A user opens a session in a project that has S.A.R.A.H. installed. The
`SessionStart` hook looks for `sarah/state.md`; finding it, it prints a short
orientation pointer naming the current phase and level. The user asks for
something. The `sarah-bootstrap` skill fires, reads `sarah/state.md` and the
relevant parts of `ARCHI.md`, sizes the request into a level from 0 to 3, and
loads exactly one phase skill. That phase skill loads only its own agents. The
agents apply the ask → options → approve protocol to every real decision. Work
happens. A gate closes only when the user says it does, and the documentation
gate closes only when the state files are current.

Nothing in that path reads a whole specification or architecture document.

## 4. Data and state

The framework is stateless. All state belongs to the *user's* project, and this
is forced by the platform rather than chosen: `${CLAUDE_PLUGIN_ROOT}` changes on
every plugin update, so nothing durable may be written there.

| File | Lives in | Holds | Lifetime |
| --- | --- | --- | --- |
| `ARCHI.md` | User project root | Curated architecture memory | Permanent, hand-maintained |
| `sarah/state.md` | User project | The index: what is in flight, what each task waits on | Rewritten continuously |
| `sarah/state/<slug>.md` | User project | One task: itinerary, phase, gates, decisions, next | Created when work starts, deleted when it ships |
| `sarah/changelog/` | User project | One short record per delivery | Append-only; feeds release notes |

**State is per task, not per repository.** It used to be one file holding one
`Current task`, versioned and rewritten continuously, which meant two branches
produced two divergent copies and a conflict at every merge. Each task now owns
a file named after its branch, so branches never touch each other's state. The
index carries only what is in flight and what each piece waits on, and a task
file is deleted when the work ships — the changelog is the permanent record, and
a directory of finished task files is a graveyard that makes the index worse
every week.

`ARCHI.md` carries a size contract: a hard ceiling of 10% of the context window,
with `/sarah-compact` measuring and compacting it. The ceiling exists because an
`ARCHI.md` that is too expensive to read gets skimmed, and a skimmed memory is
worse than none — it is trusted without being read.

## 5. Boundaries

| Boundary | Used for | Failure behavior |
| --- | --- | --- |
| Claude Code plugin API | Everything: skill loading, agents, hooks, `${CLAUDE_PLUGIN_ROOT}` | Hard dependency. Schema changes break the framework; CI validates the manifests against the installed CLI |
| Second-model CLI (`codex`, `gemini`, …) | Adversarial review at gate 4 | Detected at runtime. Absent, review falls back to a fresh subagent with clean context, silently |
| Tracker MCP (Jira, Linear, Trello, GitHub Issues) | Optional card and issue sync at the merge gate and debrief | Detected at runtime. Absent, the subject is never raised |
| `git` | State inspection during `/sarah-init` and the commit and push hooks | Degrades to greenfield assumptions; hooks exit 0 |
| `jq` | Parsing hook payloads | Hooks fall back to positional parsing, then to a reduced message |

Every boundary except the plugin API is optional by construction. A default
install with nothing else present is a supported and fully functional
configuration, not a degraded one.

## 6. Decisions

Full records land in `docs/adr/` during Phase B. Until then this table is the
authority.

| # | Decision | Why, in one line | ADR |
| --- | --- | --- | --- |
| 005 | Distribute as a Claude Code plugin rather than a copied `.claude/` directory | Native install and update path; does not collide with the user's own `.claude/` | pending |
| 004 | Master configuration lives in `sarah-bootstrap`, not in `CLAUDE.md` | Claude Code does not load a plugin's `CLAUDE.md` as project context | pending |
| 003 | Second-model review is detected at runtime with a fresh-subagent fallback | Requiring a second CLI would put a wall of setup in front of every install | pending |
| 002 | The framework runs on itself | The repository is the first working example, and the gates get tested by being obeyed | pending |
| 001 | `README-template.md` follows the `standard-readme` specification | A published specification beats an invented structure, and readers already know it | pending |

## 7. Invariants

- **Never load the full agent roster.** Phase skills name their own specialists.
  Violating this reproduces the paralysis that makes heavyweight frameworks
  unusable, and it is the failure this project exists to avoid.
- **No routine step reads a whole PRD or architecture document.** Targeted reads
  plus `ARCHI.md` as the summary. A routine step crossing roughly 30k tokens of
  input is the wrong step and must be split.
- **Hooks never block.** Every path exits 0. A hook that fails a session to
  announce the framework has inverted the framework's purpose.
- **Five top-level commands, hard ceiling.** Adding one requires removing one.
- **`sarah-bootstrap` stays under roughly 2,000 tokens.** It is injected into
  every session; its size is charged to every task the user ever runs.
- **The user decides.** No specialist commits to a consequential choice without
  presenting options and receiving an answer.
- **Every phase that produces an artefact ends with a commit.** Work that exists
  only in a working tree is not delivered, cannot be bisected, and survives no
  crash. The pull request sits at the delivery boundary, not at every phase —
  the approval gates already put a human at each step.

## 8. Sharp edges

- **Skill names are visible whether or not they are advertised.** Every plugin
  skill registers a namespaced `/` shortcut, so the phase and support skills
  appear in the command menu even though they are meant to trigger on intent.
  The five-command ceiling therefore constrains what a user must *memorize*, not
  what the menu can display. Documented rather than worked around; there is no
  platform mechanism to hide a skill.
- **A skill can only read files inside its own directory.** An installed plugin
  lives in `~/.claude/plugins/cache`, outside the session's working directory,
  and Claude Code blocks reads there. Anything a skill must read at runtime
  therefore lives in `skills/<name>/references/` as a **real file** — never an
  absolute path, never `${CLAUDE_PLUGIN_ROOT}` (that is for executed scripts),
  and never a symlink pointing outward, because permission falls on the target.
  The root `templates/` directory is the reverse: symlinks into the skills, kept
  for human browsing and never read at runtime. Found by testing; the first
  version failed silently by paraphrasing the templates it could not open.
- **Descriptions are the only trigger mechanism.** If a description is weak, the
  skill silently never fires and the framework appears to do nothing. There is
  no test that catches this — only real use.
- **The second-model review branch ships unexercised.** Gate 4 detects a second
  LLM CLI at runtime and falls back to a fresh subagent when none is present.
  The maintainer runs Claude only, so the fallback is the path that gets used
  and tested on every review, while the detection branch is written but never
  executed here. Treat it as untested code until a contributor with a second CLI
  reports otherwise.
- **`claude plugin validate` checks manifests, not content.** Nothing yet
  verifies that a skill body stays under 500 lines, that agent frontmatter uses
  only accepted fields, or that internal links resolve. Phase D adds this to CI.

## 9. Map

| Path | Purpose |
| --- | --- |
| `.claude-plugin/` | Plugin and marketplace manifests |
| `skills/` | Skill definitions; one directory per skill |
| `agents/` | Specialist personas, loaded per phase |
| `hooks/` | Hook registration and POSIX shell scripts |
| `templates/` | Artifacts copied into the user's project |
| `docs/` | Framework documentation for humans |
| `examples/` | End-to-end walkthroughs |
| `sarah/` | This repository's own S.A.R.A.H. state |
