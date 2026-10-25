# ADR-008 — Agreements are installed into and owned by the user's project; plugin hooks stay sensors

**Date:** 2026-10-24 · **Status:** accepted

## Context

The habits catalog offers agreements that may block: gitflow with green-CI merge (R13), a changelog fragment (R14), a premise re-check (R15), worktree-per-task under a WIP limit (R17), and work that does not idle (R24). A named, reasoned, expiring exception (R16) is the only bypass.

The framework's invariant was "hooks never block". The user decided on 2026-10-24 that installed agreements belong to the user's project and plugin hooks stay sensors.

Further constraints:

- **Every habit is opt-in.** Nothing unchosen is installed (R8).
- **Re-running init changes nothing** (R20).
- **Removal takes out exactly what was installed** and leaves the user's own files alone (R22).
- **Some projects already have their own hooks, CI or branch model.**
- **A skill can read only files inside its own directory**, while executed scripts can use `${CLAUDE_PLUGIN_ROOT}`.
- **Project Claude Code hooks can block**, and they merge with plugin hooks.

## Options considered

### The model writes and removes the files by hand

- **Makes easy:** no code.
- **Makes hard:** merging JSON into a settings file the user already has is where a setup breaks, and removal depends on memory.
- **Cost to reverse:** removing what was installed is unreliable.

### A plugin script installs from pinned payloads, with a manifest; agreements run as project Claude Code hooks

- **Makes easy:** deterministic, idempotent, exact removal. The checks see the full tool call and report the rule back to Claude.
- **Makes hard:** about 200 lines of standard-library Python to own. `python3` becomes required for users who choose agreements. The hooks bind the agent, not a human using the GitHub UI.
- **Cost to reverse:** low per project, because the manifest says what to remove.

### Git hooks or server-side branch protection

- **Makes easy:** also stops humans.
- **Makes hard:**
  - git hooks collide with existing hook managers and are local to each clone;
  - server rules are not files, so the framework cannot own or cleanly remove them;
  - neither can see agent dispatch or a stop.
- **Cost to reverse:** server rules may already belong to the user.

## Decision

`scripts/habits.py` installs from `skills/sarah-init/habits/<name>/`:

- **Copied, stamped, listed.** Every file is copied, never linked or fetched. Its first line is a stamp with the habit, plugin version and content sha256, and it is listed in the manifest in `sarah/habits.md`.
- **Exact diff first.** `/sarah-init` shows the exact diff and waits for approval.
- **Never auto-updated, nothing fetched at run time.**
- **Where they run.** Agreements run as `sarah/hooks/*.sh`, registered in the project's `.claude/settings.json`.
- **When they block.** Only on a positive finding. When a check cannot evaluate, it allows and says so.
- **R13 also ships a CI check**, because session hooks are local. It triggers on `pull_request`, never `pull_request_target`, with `contents: read` at top level and no unpinned third-party actions.
- **Exceptions.** Each one is a row in `sarah/habits.md`, created only on the user's explicit instruction, valid at most 14 days. A malformed date fails closed, and every use is logged to `sarah/exceptions.log`.
- **Removal** deletes only manifest files whose hash still matches, and asks about the rest.
- **Plugin hooks keep exiting 0 on every path.**

## Consequences

- The invariant now reads precisely: *plugin* hooks never block. A blocking check in a user's project is theirs, visible, and removable.
- Agreements bind the agent. A human merging in the GitHub UI is outside them except for R13's CI check, and server-side protection is offered as advice only.
- The plugin now ships executable payloads into other people's repositories. Their supply chain (pinning, stamping, approval) is part of this decision, not an implementation detail.
- An agreement keeps working if the plugin is uninstalled, and goes stale until the user re-runs `/sarah-init`.

## Revisit when

The platform offers plugin-scoped blocking hooks that a project can opt into, or a user reports a collision with an existing hook setup that adopt, wrap or skip cannot resolve.

## Note, 2026-10-24: what "the only bypass" covers

The Context calls an exception the only bypass. Read it as the only sanctioned one. The installed guards judge the usual invocation forms (plain commands, `env` and path wrappers, backslash continuations) and do not judge `sh -c`, `bash -c`, `eval`, `xargs`, `sudo`, variables, or a chain such as `git checkout X && git commit`, which is judged on the branch at hook time. They are a guardrail against mistakes, not a security boundary.
