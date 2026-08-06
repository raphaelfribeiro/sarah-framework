# Extending S.A.R.A.H.

Every boundary except the Claude Code plugin API is optional by construction. A
default install with nothing else present is a supported and fully functional
configuration, not a degraded one. Extensions add reach; they never become
requirements.

That principle is what this document is really about. An extension that makes
the framework worse when it is absent has broken the contract, no matter how
useful it is when present.

## The three rules every extension obeys

**Detected at runtime, never declared.** Nothing in `sarah/state.md`,
`ARCHI.md`, or any manifest lists which extensions a project uses. The framework
looks, finds or does not find, and proceeds either way. A project that moves
from Jira to Linear changes nothing in its S.A.R.A.H. files.

**Absent means silent.** When an extension is not there, the subject never comes
up. No warning, no suggestion to install it, no "you could connect a tracker
here". A framework that advertises its unused integrations trains users to
ignore what it says.

**Present means offered, never automatic.** When an extension is there, its
capability is offered as an option the user accepts or declines. S.A.R.A.H. does
not write to a system of record on the user's behalf. This is the same rule that
governs every other decision here: the machines propose, the human decides.

## The tracker contract

A tracker MCP — Jira, Linear, Trello, GitHub Issues, anything — plugs into
exactly two moments, and no others.

| Moment | Skill | What is offered |
| --- | --- | --- |
| The merge gate | `sarah-phase-review` | Sync the card or issue for the change that just passed review |
| Release | `sarah-phase-release` | Move the related cards, or close the issues, for what shipped |
| Session debrief | `hasta-la-vista` | Sync the cards touched during the session |

Those are the only integration points. A tracker is not consulted to decide
scope, is never read to reconstruct project state, and never becomes the source
of truth for anything: `sarah/state.md` holds the workflow state, and a tracker
that disagrees with it is wrong.

The reason is a failure this framework exists to avoid. A workflow that reads
its own state out of an external service acquires a network dependency, an auth
dependency, and a second place where the truth lives. Reconciling those is a
project of its own, which is exactly what a workflow framework must never
become.

### What an implementation must do

1. **Fail invisibly.** If the MCP is unreachable, the tool errors, or auth has
   expired, the offer is withdrawn and the work continues. A broken tracker
   never blocks a merge or a release.
2. **Ask before writing.** Present what would be written — which card, which
   transition — and write only on an explicit yes.
3. **Report honestly.** If a sync partly succeeded, say which parts. "Synced" is
   a claim, and a false one is worse than no sync at all.
4. **Never invent identifiers.** If the card or issue cannot be identified with
   confidence, say so and ask. Guessing a ticket number and moving the wrong
   card is a real cost paid by a real team.

## The second-model contract

Gate 4 — review before merge — can use a second-model CLI (`codex`, `gemini`, or
another) so that the reviewer is not the same model that wrote the code.

**This path ships unexercised.** The maintainer's environment runs Claude only,
so runtime detection exists but has never been run against a real second-model
CLI. It is recorded as a sharp edge, not a tested feature, and anyone who does
run one should expect to be the first.

The fallback is the primary path, and it is the one that is exercised: a fresh
subagent with clean context that never saw the change written. That subagent has
blocked real deliveries, including in this repository's own history, so the
absence of a second model is not the absence of a review.

## The degradation ladder

Two more boundaries degrade rather than fail, and both are worth understanding
before you extend anything.

`git` is used for state inspection during `/sarah-init` and by the commit and
push hooks. Without it, `/sarah-init` falls back to greenfield assumptions and
the hooks exit 0.

`jq` is used to parse hook payloads. Without it, hooks fall back to positional
parsing, and then to a reduced message. They still exit 0.

Notice the pattern: every rung down the ladder produces less information and
never an error. **Hooks are sensors.** They report and never block, and a hook
that breaks a session to announce a missing dependency has inverted the purpose
of the framework it belongs to.

## Adding a skill

The framework's behaviour lives in `skills/<name>/SKILL.md`. Two constraints
shape every one of them.

**The description is load-bearing.** Frontmatter is always in context, and it is
all the model has when deciding whether to load the body. A description must
state what the skill does *and* the phrasings that should fire it — including
the ones a user would say without knowing the skill exists. Under-triggering is
the default failure mode; write against it.

**Progressive disclosure is a budget.** Frontmatter is always loaded, bodies
load on invocation, and reference files load only when needed. Put the
decision-making prose in the body and the long reference material in separate
files the body points to.

`skills/sarah-bootstrap/SKILL.md` is the exception that proves the rule: it is
injected into every session by the `SessionStart` hook, so its size is charged
to every task any user ever runs. Its ceiling is roughly 2,000 tokens, CI
enforces it, and additions there come in words rather than lines.

## What you cannot add

**A sixth command.** The ceiling is five — `/sarah-init`, `/sarah-status`,
`/sarah-compact`, `/ill-be-back`, `/hasta-la-vista` — and it is hard. Everything
else triggers on intent. Adding one requires removing one, and the trade has to
be argued.

**A required extension.** If your extension makes the framework worse when it is
absent, it is not an extension. Rework it until a default install is unaffected.

**A second source of workflow truth.** `sarah/state.md` is the state. Anything
that would need to be reconciled with it belongs outside the framework.
