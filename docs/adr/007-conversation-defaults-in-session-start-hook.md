# ADR-007 — Conversation defaults are injected by the session-start hook; durable decisions live in `sarah/decisions.md`

**Date:** 2026-10-24 · **Status:** accepted

## Context

R1-R7 of the habits spec are conversation rules that apply to every user and every turn: structured questions, no continuation questions, run what you can run, short plain text, verified recommendations, remembered decisions, unattended execution. A user can turn them off.

Constraints at the time:

- **The bootstrap had no room.** `sarah-bootstrap` measured about 1,964 of its 2,000-token ceiling.
- **Compaction drops old skills first.** After compaction, invoked skill bodies are re-injected only up to 5,000 tokens each and 25,000 in total, oldest first, so the bootstrap is the first one lost in a long run.
- **Hooks and rules come back.** SessionStart hooks with no matcher run again on the `compact` source, and project rules files are re-injected from disk.
- **Decisions die with their task.** R6 needs decisions remembered across sessions, but task files are deleted when work ships.

## Options considered

### Raise the bootstrap ceiling

- **Makes easy:** one edit.
- **Makes hard:** taxes every task forever and removes the only hard budget on that file. It is also lost on compaction, like option two.
- **Cost to reverse:** low.

### Compress the bootstrap and put the defaults in it

- **Makes easy:** keeps the ceiling.
- **Makes hard:** the bootstrap is dropped first in exactly the long unattended runs where R2 and R7 matter.
- **Cost to reverse:** medium, a rewrite.

### A rules file written into the user's project

- **Makes easy:** re-injected after compaction.
- **Makes hard:** a file in every user repository that goes stale on plugin updates, written even for users who decline every habit.
- **Cost to reverse:** high, files in every user project.

### The session-start hook prints them from a plugin file

- **Makes easy:** re-injected after compaction, updates with the plugin, writes nothing to the user's repository, and can read the user's toggles from `sarah/habits.md`.
- **Makes hard:** the hook's output grows from about 130 to about 300 tokens and needs its own budget.
- **Cost to reverse:** low.

## Decision

The defaults text lives in `hooks/conversation-defaults.txt` (at most 200 tokens), printed by `session-start.sh` unless `sarah/habits.md` turns a rule off. Total hook output is held at or under 400 tokens by a CI check. Phase skills keep one line each where a default bites.

Decisions that outlive their task move into `sarah/decisions.md` in the user's project, one line each, newest first. They are read at task start and on a premise re-check. The hook's text points at the file, so the bootstrap does not grow.

## Consequences

- Every session in a S.A.R.A.H. project pays roughly 170 more tokens of hook output. The spec makes that cost mandatory; this decision only chooses where it is paid.
- The hook is still a sensor, but it now also injects behavior text. That widens what "sensor" means, and §7 of `ARCHI.md` says so.
- A new user-project file, `sarah/decisions.md`, with no size ceiling yet.
- The documentation gate gains a step: move decisions that still bind out of a finishing task file.

## Revisit when

The platform offers a plugin-level instruction channel that survives compaction, or the hook budget is breached.
