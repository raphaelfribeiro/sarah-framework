# ADR-009 — Tracker through a script adapter; local state is the source of truth; audit at the first session of the day; credential by environment variable

**Date:** 2026-10-24 · **Status:** accepted

## Context

R9 makes a Trello board the intake and task list of record for projects that choose it. R12 adds a daily audit recorded as one deduplicated, self-closing issue. A second tracker must not be a rewrite.

Constraints at the time:

- **Credentials must never reach the repository, state, logs or the transcript.**
- **Work continues when the tracker is down.**
- **Before this, `ARCHI.md` §5 only detected a tracker MCP at run time.**
- **Plugin `userConfig` secrets reach only hooks and MCP servers, never commands run through Bash.**
- **The security advisor treats board text as untrusted input.**

## Options considered

### A plugin script over the REST API, run through Bash

- **Makes easy:** fixed, testable verbs; the credential is read inside the process and never printed; no cost to projects without a tracker.
- **Makes hard:** the credential must come from the environment, since plugin secure storage does not reach it.
- **Cost to reverse:** low, one adapter.

### An MCP server (third-party or plugin-shipped)

- **Makes easy:** a plugin-shipped server could read a secret from secure storage.
- **Makes hard:** runs and lists tools in every session of every project; a third-party server is a dependency the project does not control.
- **Cost to reverse:** medium.

### The model calls the API with `curl`

- **Makes easy:** no code.
- **Makes hard:** the token lands in the command line, the transcript and the logs.
- **Cost to reverse:** n/a, ruled out.

For the audit, a scheduled CI workflow was weighed against the first session of each day. CI would run on idle days, but it needs the credential as a repository secret and the script vendored into the user's repository.

## Decision

`scripts/tracker.py` dispatches to `tracker_<name>.py` by the `tracker` key in `sarah/habits.md`. Every adapter implements `check`, `intake`, `sync`, `audit` and `report`.

- **Who owns what.** Local state owns execution. The board owns intake, backlog order and "ready". `sync` is an idempotent upsert keyed by the card ID in the index, so there is no queue: the next successful sync reconciles.
- **Audit.** It runs at the first session of each calendar day and keeps one labelled audit card, updated while findings persist and archived when they clear. No CI audit and no CI secret exist.
- **Credential.**
  - It is an environment variable set in the user's shell or Claude Code user-level configuration; the OS keychain is optional, through a lookup command.
  - The repository holds only the board ID and the variable names.
  - The user never pastes a token into chat, and scripts never print it.
  - An expiring token is recommended.
  - On 401 the session says "renew it" once and does not retry.
- **Untrusted input.**
  - Board text enters briefs only as a delimited untrusted block.
  - Work that comes from the board needs plan approval before it runs.
  - Public boards are refused.
  - Only the orchestrator runs tracker verbs; executors never do.

## Consequences

- `python3` is required for projects that choose the tracker.
- On a day with no session there is no audit. The finding appears when someone next works, which is when it can be acted on.
- The audit "issue" is a card on the board, not a GitHub issue. The spec's edge-case table listed R12 as CI-dependent; that row no longer applies.
- A Trello token is account-wide. Every executor's environment can reach it, which is part of the blast radius in the architecture document's security section.
- `ARCHI.md` §5's tracker row changes from "detected MCP" to "configured adapter".

## Revisit when

A second tracker is added (the five verbs get their first real test), the platform lets secure plugin config reach Bash-launched processes safely, or users report missed audits that mattered.
