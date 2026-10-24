# ADR-006 — One executor agent, model and effort set per call

**Date:** 2026-10-24 · **Status:** accepted

## Context

The habits catalog (spec `docs/specs/the-habits-that-earned-their-place.md`, R10 and R11) requires every task to declare an executor, model, effort and fallback. A fixed brief goes in and a fixed report comes back. Parallel tasks may each run at a different model and effort.

Constraints at the time:

- **Every plugin agent's description is listed to the main agent in every session.** The roster already holds ten agents, and the project's first invariant is never to load the full roster.
- **Plugin agents accept `model` and `effort` in frontmatter.**
- **A model set on the call overrides the frontmatter.** This is documented.
- **Effort set on the call is less certain.** It was observed in the Agent tool's schema (Claude Code 2.1.308), restricted to cases where a skill or the user explicitly asks for an effort level. It is not in the public docs.
- **The platform's `fallbackModel` chain covers overload for subagents, but never rate limits (429).**

## Options considered

### Ten agent files, one per model and effort pair

- **Makes easy:** effort is fixed in frontmatter, so nothing depends on per-call parameters.
- **Makes hard:** ten near-identical descriptions in every session, about 600-700 tokens, and ten routing targets for the model to confuse.
- **Cost to reverse:** low in files, but every task declaration names a file.

### One executor, model and effort set per call

- **Makes easy:** one description, any pair, and one name for project hooks to match.
- **Makes hard:** it depends on per-call effort, which is observed but undocumented.
- **Cost to reverse:** low. Adding files later is additive.

### One file per effort level, model set per call

- **Makes easy:** survives a host whose Agent tool has no per-call effort.
- **Makes hard:** five descriptions, so half the roster cost of the first option.
- **Cost to reverse:** low.

## Decision

One `agents/executor.md`. Its frontmatter has `model: sonnet` as the default and no `effort`. The orchestrator in `sarah-phase-implement` dispatches it with the model and effort the task file declares; that skill instruction is the explicit request the tool's rule requires. The brief comes in three depths keyed to model and effort. The report always carries Done, Proof, Not finished and Requested tasks, and a Done without Proof is rejected.

Fallback: on overload the user's platform chain applies. On a rate limit or a dispatch error the orchestrator re-dispatches once on the declared fallback and records it. A second failure blocks that task and the run continues.

If the first implementation probe shows per-call effort is absent or ignored, the third option replaces this one.

## Consequences

- One agent description is added to every session, about 70 tokens.
- R10's "the report says so" assumes the executor can name the model it ran on. That is unverified after a silent platform fallback.
- `CLAUDE_CODE_EFFORT_LEVEL` may override per-call effort, which is unverified. A user who sets it gets their effort, not the task's.
- The model can be named only by alias (`sonnet`, `opus`, `haiku`, `fable`), not by full model ID.

## Revisit when

The effort probe fails, the platform documents or removes per-call effort, or the roster's always-listed description cost becomes a measured problem.
