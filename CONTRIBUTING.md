# Contributing to S.A.R.A.H.

The framework develops itself. This repository runs the workflow it defines, so
contributing here means following the same gates that S.A.R.A.H. asks of any
project using it. That is deliberate: a framework whose own repository violates
its documentation gate is one nobody should trust.

Read [`CLAUDE.md`](CLAUDE.md) first. It is the operating manual for working on
this repository, and it overrides anything here that contradicts it.

## What this repository is made of

Almost none of it is executable. It is prose that a model reads at runtime,
which changes what a defect looks like: a skill that fails to trigger is a bug,
an ambiguous instruction is a bug, and a description that under-triggers is the
most common bug of all.

| Artefact | Lives in | Must satisfy |
| --- | --- | --- |
| Skills | `skills/<name>/SKILL.md` | YAML frontmatter with `name` and `description`; body under 500 lines |
| Agents | `agents/<name>.md` | Frontmatter limited to fields Claude Code accepts for plugin agents |
| Hooks | `hooks/hooks.json`, `hooks/scripts/` | POSIX `sh`, no bashisms, exit 0 on every path |
| Templates | `templates/` | HTML-comment guidance that generation strips |
| Manifests | `.claude-plugin/` | `claude plugin validate . --strict` passes |

## Before you open a pull request

Open it against `develop`. Never against `main`.

```bash
claude plugin validate . --strict
sh -n hooks/scripts/*.sh
```

Then confirm the documentation gate, which is not optional here:

- `sarah/state.md` is current.
- `ARCHI.md` is updated if the architecture moved.
- `README.md` is updated if anything user-visible changed.
- There is an entry in `sarah/changelog/` for the delivery.

**If it isn't documented, it isn't done. If it isn't committed, it didn't
happen.**

## Branching

This repository follows gitflow, documented in full in
[`docs/branching.md`](docs/branching.md). `main` holds released versions,
`develop` holds the next one, and work happens on `feature/*` branched from
`develop`. Never commit directly to either permanent branch.

Every phase that produces an artefact ends with a commit. The pull request sits
at the delivery boundary, not at every phase — the approval gates already put a
human at each step.

## The rules that are easy to break by accident

**Skill descriptions are load-bearing.** A skill that does not trigger does not
exist. Every `description` must state what the skill does *and* the phrasings
that should fire it, including the ones a user would say without knowing the
skill exists. Under-triggering is the default failure; write against it.

**Progressive disclosure is a budget, not a preference.** Frontmatter is always
in context. Bodies load on invocation. Reference files load only when needed.
`skills/sarah-bootstrap/SKILL.md` has the tightest budget in the repository —
it is injected into every session — and must stay under roughly 2,000 tokens.
Additions there come in words, not lines, and CI enforces the ceiling.

**Hooks are sensors.** They report and never block. A missing tool, an
unreadable file, or a project that does not use S.A.R.A.H. produces silence and
exit 0. Breaking a user's session to announce yourself is a defect, and CI
rejects any hook that can exit non-zero.

**The five-command ceiling is hard.** `/sarah-init`, `/sarah-status`,
`/sarah-compact`, `/ill-be-back`, `/hasta-la-vista`. Everything else triggers on
intent. Adding a sixth requires removing one, and that trade has to be argued in
the pull request.

**Never load the full agent roster.** The roster exists so the right specialist
is available, not so every specialist is present. Phase skills name their own
agents and no others.

**Prose is in English.** Every shipped artefact — README, skills, agents,
templates, docs, commit messages — is written in English, because the audience
is global.

**Public artefacts reference GitHub.** Clone URLs, badges, issue links and CI
point at `https://github.com/raphaelfribeiro/sarah-framework` and nothing else.
CI fails the build if anything else appears.

## Voice

Confident, direct, faintly military. Never silly.

The Resistance framing is the branding translation of the framework's central
claim: powerful machines under human command. It is not decoration, so it is
also not filler. **At most one such line per section**, and only where the
surrounding text has earned it. Everything else is sober and technical.

Cultural references stay at the level of short textual allusion. No franchise
imagery, artwork, logos, or extended quotation anywhere in the repository.

## Reporting a defect

The most useful bug report for a prose framework names the phrasing that should
have fired a skill and did not, or quotes the instruction that was followed
differently than intended. "The agent did the wrong thing" is hard to act on;
"I said *X* and expected `sarah-phase-spec`, and nothing fired" is a fix.

## What gets a pull request rejected

- Adding a sixth command without removing one.
- A change that leaves `sarah/state.md` or `ARCHI.md` describing a system that
  no longer exists.
- A hook that can break a session.
- Growing `sarah-bootstrap` past its budget.
- Prose in any language other than English.
- Referencing infrastructure other than GitHub.
