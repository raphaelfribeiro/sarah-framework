# Working on S.A.R.A.H. itself

This file configures Claude Code for developing **this repository** — the
S.A.R.A.H. framework. It is not part of what the framework ships.

That distinction matters, because Claude Code does not load a plugin's
`CLAUDE.md` as project context. A plugin contributes context through skills,
agents, and hooks. The framework's own operating instructions therefore live in
`skills/sarah-bootstrap/SKILL.md`, injected by the `SessionStart` hook. If you
came here looking for how S.A.R.A.H. works, read that file instead.

## S.A.R.A.H. develops S.A.R.A.H.

This repository uses the framework it defines. `ARCHI.md` is real, `sarah/state.md`
is real, and `sarah/changelog/` records real deliveries. The templates under
`templates/` are what `/sarah-init` copies into other projects.

The consequence is a hard rule: **if a change makes the framework's own state
files wrong, the change is not done.** A framework whose documentation gate its
own repository violates is a framework nobody should trust.

## What this repository is made of

Almost all of it is prose that a model reads at runtime. There is very little
executable code, and that changes what "quality" means here.

| Artifact | Lives in | Must satisfy |
| --- | --- | --- |
| Skills | `skills/<name>/SKILL.md` | YAML frontmatter with `name` and `description`; body under 500 lines |
| Agents | `agents/<name>.md` | Frontmatter limited to fields Claude Code accepts for plugin agents |
| Hooks | `hooks/hooks.json`, `hooks/scripts/` | POSIX `sh`, no bashisms, exit 0 on every path |
| Templates | `templates/` | HTML-comment guidance that generation strips |
| Manifests | `.claude-plugin/` | `claude plugin validate . --strict` passes |

## Rules

**Skill descriptions are load-bearing.** A skill that does not trigger does not
exist. Every `description` states what the skill does *and* the phrasings that
should fire it, including the ones a user would say without knowing the skill
exists. Under-triggering is the default failure; write against it.

**Progressive disclosure is a budget, not a preference.** Frontmatter is always
in context. Bodies load on invocation. Reference files load only when needed.
`skills/sarah-bootstrap/SKILL.md` has the tightest budget in the repository —
it is injected into every session — and must stay under roughly 2,000 tokens.

**Hooks are sensors.** They report and never block. A missing tool, an
unreadable file, or a project that does not use S.A.R.A.H. produces silence and
exit 0. Breaking a user's session to announce yourself is a defect.

**The five-command ceiling is hard.** `/sarah-init`, `/sarah-status`,
`/sarah-compact`, `/ill-be-back`, `/hasta-la-vista`. Everything else triggers on
intent. Adding a sixth requires removing one.

**Never load the full agent roster.** The roster exists so the right specialist
is available, not so every specialist is present. Phase skills name their own
agents and no others.

**Prose is in English.** Every shipped artifact — README, skills, agents,
templates, docs, commit messages — is written in English, because the audience
is global.

**Public artifacts reference the GitHub repository.** Clone URLs, badges, issue
links, and CI workflows point at
`https://github.com/raphaelfribeiro/sarah-framework` and use standard GitHub
Actions syntax. Contributors interact with the project entirely through GitHub.

## Voice

Confident, direct, faintly military. Never silly.

The Resistance framing is the branding translation of the framework's central
claim: powerful machines under human command. It is not decoration, so it is
also not filler. **At most one such line per section**, and only where the
surrounding text has earned it. Everything else is sober and technical.

Cultural references stay at the level of short textual allusion. No franchise
imagery, artwork, logos, or extended quotation anywhere in the repository.

## Before opening a pull request

```bash
claude plugin validate . --strict
sh -n hooks/scripts/*.sh
```

Then confirm the documentation gate: `sarah/state.md` current, `ARCHI.md`
updated if the architecture moved, `README.md` updated if anything user-visible
changed, and an entry in `sarah/changelog/` for the delivery.

If it isn't documented, it isn't done.
