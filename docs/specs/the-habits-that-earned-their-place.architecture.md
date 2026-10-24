# Architecture — the habits that earned their place

**Date:** 2026-10-24 · **Level:** 3 · **Status:** approved by the user at Gate 2, 2026-10-24 · **Spec:** [the-habits-that-earned-their-place.md](the-habits-that-earned-their-place.md)

This design answers the spec's Q1, Q2 and Q8 and the questions handed to architecture. Each decision keeps its options and trade-offs so the record survives. The user approved D1-D7 as proposed, changed D8, added D9 (autonomy grants) and chose the tracker credential path. The security advisor's constraints are integrated in §5. Decision records: [ADR-006](../adr/006-one-executor-per-call-model-and-effort.md) to [ADR-010](../adr/010-autonomy-grants-and-unattended-merge.md).

---

## 0. Platform facts this design rests on

Checked against the Claude Code documentation (code.claude.com/docs: sub-agents, plugins-reference, worktrees, model-config, context-window, hooks, settings, settings-reference; fetched 2026-10-24) and the installed CLI, `2.1.308`. "Observed" means seen in a live session's tool schema rather than in the public docs.

| # | Fact | Status |
| --- | --- | --- |
| F1 | Plugin agents accept `model` and `effort` in frontmatter. `hooks`, `mcpServers` and `permissionMode` are ignored for plugin agents | verified |
| F2 | A `model` set on the call overrides the agent's frontmatter `model` | verified |
| F3 | The Agent tool takes `model` (aliases only: `sonnet`, `opus`, `haiku`, `fable`), `effort` (`low` to `max`) and `isolation: "worktree"` per call | verified by probe P1, CLI 2.1.308: each subagent request carried its dispatched effort (`low`, `high`, `low`) while the session ran at `medium` |
| F4 | Per-call `effort` may be set only when the user or a skill explicitly asks for that effort. A skill that says "dispatch at the effort the task file declares" meets that condition | observed. It is a rule on model behavior, not an API guarantee |
| F5 | `CLAUDE_CODE_EFFORT_LEVEL` overrides frontmatter effort, and `maxEffortLevel` caps it | verified. Probe P1, CLI 2.1.308: with the variable set, the Agent tool **loses its `effort` parameter entirely** and every subagent runs at the variable's level. Per-call effort is then silently unavailable; the operating docs must say so |
| F6 | The `fallbackModel` chain applies to subagents on overload or unavailability. Rate-limit (429), auth and billing errors never trigger it | verified |
| F7 | Every plugin agent's description is listed to the main agent in every session | observed |
| F8 | Subagent worktrees branch from the remote default branch unless `worktree.baseRef: "head"` is set. `.worktreeinclude` copies gitignored files. Dependencies are not installed | verified |
| F9 | After compaction, project `CLAUDE.md` and unscoped rules are re-injected. Invoked skill bodies are re-injected only up to 5,000 tokens each and 25,000 in total, oldest dropped first. SessionStart hooks matching `compact` run again | verified |
| F10 | A SessionStart hook with no matcher fires on every source, including `compact` | verified |
| F11 | Plugin, user and project hooks merge, and all of them run | verified |
| F12 | Project hooks can block: PreToolUse exit 2 blocks the call, Stop exit 2 keeps Claude working, and stderr carries the message | verified |
| F13 | Plugin `userConfig` with `sensitive: true` reaches only hooks and MCP servers, never Bash commands | verified |
| F14 | Optional `userConfig` prompting at plugin enable | dropped: irrelevant once D4 chose environment variables |
| F15 | `attribution.commit` and `attribution.pr` can be set in project settings | verified (settings index row) |
| F16 | The PreToolUse matcher for subagent dispatch is `Agent`, and its `tool_input` carries `subagent_type`, `model`, `effort` and `isolation` | verified by probe P2, CLI 2.1.308: `tool_input` was `{"subagent_type","model","effort","run_in_background","isolation"}` |
| F17 | A subagent can name the model it actually ran on | verified by probe P3 for a normal dispatch, CLI 2.1.308: `resolvedModel` matched the subagent's own answer in 6 of 6. A forced platform fallback could not be triggered, so that case stays covered by the D1 fallback |
| F18 | A project `permissions.ask` rule still prompts when the user runs in a permissive mode | verified by probe P4, CLI 2.1.308: the ask rule refused `git push` under `bypassPermissions` and under `acceptEdits`; a control run without it pushed |

---

## 1. Structure

### Plugin side (ships with S.A.R.A.H., updates with the plugin)

| Component | New or changed | Owns |
| --- | --- | --- |
| `agents/executor.md` | new | The fixed report shape (R11). Model and effort come per call (D1) |
| `hooks/scripts/session-start.sh` | changed | Prints the conversation defaults, the chosen-habit line and the state-size warnings. Stays a sensor |
| `hooks/conversation-defaults.txt` | new | The R1-R7 text, kept in its own file so CI can measure it (D2) |
| `skills/sarah-init/` | changed | The catalog interview. `references/habits-catalog.md` is read by the model; `habits/<name>/` holds the payloads the installer copies |
| `scripts/habits.py` | new | `plan` (prints the exact diff), `apply`, `remove`, `status` |
| `scripts/tracker.py`, `scripts/tracker_trello.py` | new | The tracker seam (D4) |
| `skills/sarah-phase-implement/` | changed | The orchestrator: dispatch, fallback, checking the executor's report. `references/executor-brief.md` holds the fixed brief |
| `skills/sarah-compact/` | changed | Also compacts state files (D6) |
| `skills/sarah-bootstrap/references/task-template.md` | moved here | R23 (D7) |

### User-project side (written only by the user's choice, owned by the user's project)

| Path | Written when | Holds | Versioned |
| --- | --- | --- | --- |
| `sarah/habits.md` | `/sarah-init`, always | Chosen set and settings, autonomy grants, install manifest, exceptions | yes |
| `sarah/decisions.md` | the first decision that outlives its task | Durable user decisions (R6) | yes |
| `sarah/exceptions.log` | the first time an exception is used | One line per use of an exception (R16) | yes |
| `sarah/hooks/*.sh` | an agreement or R10 is chosen | The project's blocking checks, in POSIX sh | yes |
| `.claude/settings.json` (entries only) | the same | Hook registrations, `permissions.ask` rules for the always-ask list, `worktree.baseRef` (R17), `attribution` (R13) | yes |
| `.github/workflows/sarah-gitflow.yml` | R13 chosen and the repo uses GitHub Actions | The CI side of the branch model | yes |
| `.worktreeinclude` (entries only) | R17 | Gitignored files a worktree needs | yes |
| `sarah/.local/` | as needed | Session marker, local overrides | **no**: `/sarah-init` adds it to `.gitignore` |

**Nothing crosses from the user project into the plugin.** The plugin reads `sarah/habits.md`; the project never depends on the plugin's path. An installed agreement keeps working if the plugin is uninstalled.

---

## 2. Data ownership

| Fact | Authority | Note |
| --- | --- | --- |
| Chosen habits and their settings | `sarah/habits.md` | The session-start hook prints a one-line summary, so R8's "one small read" needs no tool call |
| What the agent may do unattended | the Autonomy section of `sarah/habits.md` (D9) | An approved plan never adds to it |
| Which files the framework installed | the manifest section of `sarah/habits.md` | The only basis for removal |
| Active exceptions | the exceptions section of `sarah/habits.md` | Created only by the user |
| What is in flight | `sarah/state.md` | **Only the orchestrator writes it** |
| One task's state, executor declaration, premises | `sarah/state/<slug>.md` | Executors write only this file |
| Durable user decisions | `sarah/decisions.md` | Architecture decisions stay in `ARCHI.md` §6 |
| Demand intake, backlog order, "ready" | the Trello board | Card text is untrusted data (§5) |
| Card position for in-flight work | local task state, pushed to the board | A human drag on a framework-owned list becomes an audit finding |
| Tracker credential | an environment variable, or the OS keychain, outside the repo | The repo holds only the board ID and the variable names |

---

## 3. Decisions

### D1 — One executor, model and effort set per call (Q1; R10, R11) · [ADR-006](../adr/006-one-executor-per-call-model-and-effort.md)

Options: (a) ten files `executor-<model>-<effort>`; (b) one `executor` agent, with model and effort set on each call; (c) one file per effort level, with the model set per call.

- (a) puts ten descriptions in every session's agent list (F7), about 600-700 tokens of near-duplicates.
- (b) has one description, any model and effort pair, and one name for hooks to match. Its only open point is per-call `effort` (F3, F4).
- (c) holds up if per-call effort fails.

**Approved: (b), with (c) as the named fallback** if the effort probe fails.

How it works:
- **The agent file.** `agents/executor.md` has a narrow description, `model: sonnet` as the default and no `effort`. Its report has four sections, Done, Proof, Not finished and Requested tasks, each present even when empty.
- **The brief.** `skills/sarah-phase-implement/references/executor-brief.md` comes in three depths keyed to the declared model and effort: full for weak executors, standard, and lean for opus or fable at high effort or above.
- **Report check.** The orchestrator rejects any Done item with no Proof and re-briefs once. A second failure goes to Not finished.
- **Fallback.**
  - On overload, the user's `fallbackModel` chain switches the model, if the user has set one. The executor reports the model it ran on (F17).
  - On a rate limit or a dispatch error, the platform does nothing. The orchestrator re-dispatches once on the declared fallback and records it in the task file and the report. A second failure blocks the task, and the run continues with the others (R7).

### D2 — Conversation defaults via the session-start hook, plus `sarah/decisions.md` (Q2; R1-R7) · [ADR-007](../adr/007-conversation-defaults-in-session-start-hook.md)

Options: (a) raise the bootstrap ceiling; (b) compress the bootstrap and put R1-R7 in it; (c) write a rules file into the user's project; (d) have the session-start hook print them.

- (b) fails in long unattended runs: the bootstrap is the oldest invoked skill, so it is the first one dropped once invoked skills pass the re-injection budget (F9).
- (c) writes a file into every user repository, and that file goes stale when the plugin updates.
- (d) is re-injected after compaction (F10), updates with the plugin and writes nothing into the user's repo.

**Approved: (d).**
- **Budget:** `conversation-defaults.txt` at most 200 tokens, the whole hook output at most 400, checked in CI.
- **Toggles:** each default can be turned off in `sarah/habits.md`.
- **Phase skills** keep one line each where a default applies.

**R6** needs a record that outlives the task, because task files are deleted when work ships. `sarah/decisions.md` holds one line per decision, newest first. The documentation gate moves decisions that still bind into it. It is read when a task starts and by R15. The hook's defaults text points at it, so the bootstrap does not grow.

### D3 — Agreements are installed into and owned by the user's project; plugin hooks stay sensors (R8, R13-R17, R20, R22, R24) · [ADR-008](../adr/008-agreements-owned-by-the-users-project.md)

**D3.1 Who writes the files.** A plugin script, `scripts/habits.py` (Python 3 standard library), not the model. Hand-merging JSON into a settings file the user already has is where the model would most likely break their setup. Two requirements force the script: R20 (a re-run changes nothing) and R22 (removal takes out exactly what was installed).

The catalog text the model reads lives in `skills/sarah-init/references/`. The payloads live in `skills/sarah-init/habits/<name>/` and are read by the script through `${CLAUDE_PLUGIN_ROOT}`; the sharp edge in ARCHI §8 binds only files the model reads.

`python3` is required only for the opt-in habits that install or call scripts. Declining every habit needs nothing.

**Install and remove:**
- **Pinned copies.** Every installed file is copied, never linked or fetched. Its first line is a stamp: habit, plugin version, content sha256. It is listed in the manifest.
- **Approval first.** `/sarah-init` runs `habits.py plan`, shows the exact diff and waits for approval before `apply`.
- **Never auto-updated.** A newer plugin version proposes a new diff at the next `/sarah-init`.
- **No downloads at run time.** No remote fetch and no `curl | sh`, ever.
- **Re-install.**
  - A file whose hash matches is left alone.
  - A stamped file that has changed is one the user edited, so the user is asked.
  - An unstamped file already at the target path belongs to the user, who chooses adopt, wrap or skip.
- **Settings entries** are identified by their command path under `sarah/hooks/`. A key the user had already set stays theirs.
- **Remove** deletes the manifest files whose hash still matches, asks about the rest, and drops the settings entries that point into `sarah/hooks/<habit>`. Nothing outside the manifest is touched.

**D3.2 Where each agreement is enforced.** Mainly in project Claude Code hooks, `.claude/settings.json` pointing at `sarah/hooks/*.sh`. They constrain the agent, which is who the agreements are for; they see the whole tool call; and their exit 2 message names the rule (F12).

Git hooks were rejected: they collide with existing hook managers and are local to each clone. Server-side branch protection is advice only, because the framework cannot own or cleanly remove it.

Hooks are local, so R13 also ships a CI check.

| Habit | Event and check |
| --- | --- |
| R13 gitflow and green CI | PreToolUse Bash refuses: a commit on a protected branch, a push to one, a PR whose base breaks the branch model, and `gh pr merge` before `gh pr checks` is green. The CI side is `sarah-gitflow.yml` (§5.2). Attribution is a separate yes/no, **default off** |
| R14 changelog fragment | `gh pr create` is refused unless the branch adds a `sarah/changelog/` entry with a user-facing sentence |
| R15 premise re-check | The executor-dispatch check (D5) refuses a task whose Premises section lacks a current dated check |
| R17 WIP limit | The executor-dispatch check (D5) |
| R24 work does not idle | The Stop hook blocks once when all of these hold: nothing is in progress, ready work exists, no task is waiting on the user, and no stop marker is set in `sarah/.local/`. When `stop_hook_active` is set it allows, so it nudges once and never loops |

Every agreement script **blocks only on a positive finding.** If it cannot evaluate a rule, it allows the call and prints one line saying so.

**D3.3 The R16 exception.** A row in the exceptions section of `sarah/habits.md`: rule, reason, expires, granted by, date.

- **Only the user creates one.** The agent writes the row only in response to the user's explicit instruction in that turn, and quotes the instruction. It never writes one on its own initiative and never proposes one as a way past a block.
- **Valid only within the window.** A script honors a row only if the reason is non-empty and today is between the grant date and the expiry, with expiry at most 14 days after the grant.
- **Fails closed.** A malformed or missing date means the row is not honored and the rule applies. This does not contradict "allow when the rule cannot be evaluated": the bypass fails closed, the rule does not.
- **Every use is logged.** Each time an exception lets a call through, one line goes to `sarah/exceptions.log`.
- **Visible and pruned.** `/sarah-status` shows active rows, those expired in the last 14 days, and their use counts. `/hasta-la-vista` prunes older rows.

### D4 — Tracker adapter with local state as the source of truth (R9, R12) · [ADR-009](../adr/009-tracker-adapter-local-state-env-credential.md)

**Approved: a plugin script over the Trello REST API**, not an MCP server and not `curl` run by the model.

- An MCP server would run and list its tools in every session of every project.
- `curl` run by the model puts the token on a command line, in the transcript and in the logs.

**The seam.** `tracker.py` dispatches to `tracker_<name>.py` according to `sarah/habits.md`. Each adapter implements five verbs:

| Verb | Does | Idempotency |
| --- | --- | --- |
| `check` | Credential valid, board reachable, board not public | read-only |
| `intake` | Ready cards not yet linked to a task | read-only |
| `sync` | Pushes the state of every in-flight task to its card | Upserts by card ID |
| `audit` | Diffs the board against the index | read-only |
| `report` | Updates or closes the single audit card | Keyed by a fixed label |

A second tracker is one adapter file plus a catalog line.

**Offline.** There is no queue file. Local state is the authority, so the next successful `sync` reconciles everything. A demand given while offline gets `Card: pending` and is created on the next sync.

**Audit.** It runs at the first session of each calendar day (approved), and the date of the last run is recorded in `sarah/habits.md`. The "one deduplicated issue" is a single labelled card on the board: updated while findings persist, archived when they clear. **No CI audit and no CI secret exist.** The credential has exactly one home, the developer's machine.

**Credential (decided by the user).**
- **Where it lives:** an environment variable (`TRELLO_API_KEY`, `TRELLO_TOKEN`) set in the user's shell or in Claude Code's user-level configuration, outside the repository. The OS keychain is the optional alternative: the variable then names a lookup command, never a value.
- **Never in chat or output:** the user never pastes a token into the chat, and the scripts never print it.
- **An expiring token is recommended.**
- **On 401:** the session says once "the Trello token was rejected; renew it" and continues locally, with no retry.
- **What the repository holds:** the board ID and the variable names, nothing else.

### D5 — Parallelism under a WIP limit (R17, R18)

**Approved:** the WIP limit lives in `sarah/habits.md` (default 3). `sarah/hooks/dispatch-guard.sh` (PreToolUse, matcher `Agent`, F16) acts only on `sarah:executor` dispatches. It refuses:
- a dispatch over the limit, listing the running tasks (R17);
- a dispatch without `model` (R10);
- a task with a stale premise check (R15).

The count comes from the in-progress rows of the working-tree index, which is the single authority.

When only R18 is chosen, the limit is advisory and the orchestrator honors it.

**Dispatch.**
1. The orchestrator marks the task in progress.
2. It dispatches the executor in the background with `model`, `effort` and `isolation: "worktree"`.
3. Step 0 of the brief, before any work: rename the branch to `feature/<slug>`, write the task file if it is missing, run the setup and checks recorded in `sarah/habits.md`, and report the baseline.

R17 installs `worktree.baseRef: "head"` and `.worktreeinclude` entries. A `WorktreeCreate` hook was rejected: it replaces the platform's git logic and disables `.worktreeinclude`.

### D6 — State ceiling (R19)

**Measure.** The session-start hook runs `wc -c` on `sarah/state.md` (limit 8,192 bytes) and on each `sarah/state/*.md` (limit 16,384). It prints one line per file over its limit and offers `/sarah-compact`. It never blocks.

**Compact.** `/sarah-compact` gains a state section, in this order:
1. Delete the files of shipped tasks.
2. Move finished narrative to the changelog.
3. Move durable lessons into `ARCHI.md` §8 or `docs/`.
4. Move decisions that still bind into `sarah/decisions.md`.

It proposes before it writes.

**This repository's own `sarah/state.md` is 8,768 bytes.** The delivery must compact it below the limit.

### D7 — The bootstrap's task template (R23)

**Approved: move** `task-template.md` from `skills/sarah-init/references/` to `skills/sarah-bootstrap/references/`. `sarah-init` never creates a task file, and the move adds zero tokens to the bootstrap. Repoint the `templates/` symlink and update `sarah-init` lines 109 and 138. The moved template gains the executor declaration table (R10) and a Premises section (R15). A CI check for dead `references/` links closes the ARCHI §8 gap that let this happen.

### D8 — Unattended commit, push and merge (Q8; R2, R7, R13) · [ADR-010](../adr/010-autonomy-grants-and-unattended-merge.md)

I recommended that merge always wait for the user. **The user changed this:** when R13 is installed, the agent **may merge a `feature/*` branch into the integration branch on its own once CI is green**.

- **What does not change:**
  - Every phase that produces an artefact still ends with a commit on the task's own branch, unattended runs included.
  - Deciding to release stays a user gate, consistent with R2's gate list; a merge to `main` is part of a release.
  - Without R13, merge waits for the user.
- **What this supersedes:** for opted-in projects only, the bootstrap line "Every merge has a human behind it". It is recorded as superseded with its reason, not erased. The bootstrap edit itself happens in implementation.
- **Grants:** installing R13 adds two rows to the autonomy grants (D9), "merge feature/* to the integration branch on green CI" and "push feature/*". Both are shown in the install diff, and each can be removed.

### D9 — Autonomy grants (new; answers the security advisor) · [ADR-010](../adr/010-autonomy-grants-and-unattended-merge.md)

At `/sarah-init` the user grants, once per project, a named list of actions the agent may take unattended. Examples: push to `feature/*`, ssh to a named host, run device tests.

- **Where:** the Autonomy section of `sarah/habits.md`. Each row has the action, its scope and the grant date.
- **Expansion:** the list can grow later in conversation without re-running init. As with exceptions, the agent writes a row only on the user's explicit instruction in that turn, and quotes it.
- **Not on the list:** asked.
- **Always asked, whatever the list says:**
  - destructive actions (recursive delete, force-push, deleting branches, rewriting history);
  - spending money;
  - touching credentials.

  This list is fixed in the plugin and cannot be granted away. Where a pattern exists, `habits.py` also installs it as `permissions.ask` rules in the project settings. Those rules only tighten, they are in the manifest, and they can be removed (F18 verifies they still prompt in permissive modes).
- **An approved plan does not by itself authorise any listed-risk action.** The plan says what to build; the grant list says what may be done unattended to build it.
- **The platform's permission configuration stays the user's.** The framework never writes `allow` rules on its own. At init it offers matching allow rules for granted actions in `.claude/settings.local.json`, as a shown diff that waits for approval.

---

## 4. Failure behavior at each boundary

| Boundary | Slow or unavailable | Wrong |
| --- | --- | --- |
| Plugin hook → `sarah/habits.md` | Missing or unreadable: v0.1.0 behavior with defaults on, exit 0 | A malformed row is ignored, with one line saying so |
| Agreement script → `gh`, `jq`, files | Cannot evaluate: allow, and say the rule was not checked | Positive finding: block, naming the rule and the exception path |
| Agreement script → exception row | n/a | Malformed or expired: not honored (fails closed) |
| Orchestrator → executor | Overload: the platform chain. Rate limit (429): one re-dispatch on the fallback, then blocked-and-continue | A report missing a section, or Done without Proof: re-brief once, then Not finished |
| Executor → worktree | Setup fails: Not finished with the output; the run continues | Wrong base: step 0 checks the merge-base and stops |
| `tracker.py` → Trello | Unreachable: continue locally, and the next sync reconciles | 401: "renew it", once, no retry. A public board is refused at `check`. A board that disagrees with local state is an audit finding |
| `habits.py` → user files | No `python3`: offer the habit with the prerequisite stated, install nothing | A file the user edited: ask, never overwrite |
| Session-start size sensor | Unreadable file: skip silently | n/a |

---

## 5. Security

The security advisor advised; these constraints are integrated.

**5.1 What the repository may hold.** The board ID and the environment variable names. Never a token, a key or a credential path that reveals secrets. Any local configuration lives under `sarah/.local/`, which `/sarah-init` adds to `.gitignore`.

**5.2 CI.** D4 removes the CI audit and its secret. The only workflow ever installed is R13's `sarah-gitflow.yml`, which checks a PR's base against the branch model. It:
- triggers on `pull_request`, **never `pull_request_target`**;
- sets top-level `permissions: contents: read`, widened per job only where a job needs it;
- uses no third-party action. If one is ever added, it is pinned by full commit SHA.

**5.3 Supply chain of installed files.** As in D3.1: copied, pinned, stamped with plugin version and content hash, listed in the manifest, applied only after the user approves the exact diff, never auto-updated, never fetched at run time. The Claude Code hooks are local to each session, so R13's guarantee for the branch model also rests on its CI check.

**5.4 Exceptions.** As in D3.3: only the user creates them, at most 14 days, every use logged, a malformed date fails closed.

**5.5 Blast radius of unattended executors.** Up to the WIP limit, executors run at once, each in its own worktree with a brief scoped to one task. Worktree isolation limits **file edits**. It does not limit **credentials**: every executor inherits the same environment, which can include:
- the git push credential;
- the `gh` token;
- the Trello token, which is account-wide;
- the ssh agent for any granted host.

So one executor turned by injected text could act with everything the user's session can reach.

Mitigations:
- executors never receive tracker verbs (only the orchestrator runs `tracker.py`);
- the always-ask list holds for executors too;
- grants are narrow and named;
- an expiring Trello token;
- untrusted-input handling (5.6).

The residual risk is stated, not designed away. Separate credentials per executor would need a credential broker that this project does not have.

**5.6 Untrusted input.**
- **Card and board text** reaches a brief only inside a delimited block marked as untrusted data. The brief's instructions come only from the approved plan.
- **Board-sourced work** needs plan approval before it executes. Intake creates proposals, not runs.
- **Executor reports** are untrusted by the orchestrator. Requested tasks become proposals for the user. Instructions found in a report are never followed, and Proof is checked, not believed.
- **Public boards** are refused at `check`.
- **No secrets** ever go into a brief.

---

## 6. Invariants this design depends on

1. **Plugin hooks never block.** Installed agreements may, and they belong to the user's project: they sit under `sarah/hooks/`, are registered in the project's settings, are listed in the manifest, and are removed by the same entry point that installed them.
2. **The manifest is the only basis for removal.**
3. **An agreement blocks only on a positive finding. An exception is honored only when it is well formed and unexpired.**
4. **Only the user creates exceptions and autonomy grants.** The agent writes them only on the user's explicit instruction in that turn.
5. **The always-ask list cannot be granted away. An approved plan authorises no listed-risk action.**
6. **Only the orchestrator writes the index.** Executors write only their own task file.
7. **The tracker credential never enters context, the repository, state, logs, briefs or the transcript.**
8. **Untrusted text (board, executor report) is data, never instructions.**
9. **The session-start hook's output stays at or under 400 tokens.**
10. **Every phase that produces an artefact ends with a commit on its task branch. Release is a user gate. Merge without the user happens only under R13 with green CI.**

Unchanged: never load the full roster (D1 adds one description); five commands; the bootstrap stays under 2,000 tokens (D2 and D7 add nothing to it).

## 7. Deliberately left open

| Item | Why it is safe to leave |
| --- | --- |
| Index merge conflicts across parallel branches | Invariant 6 removes most of the surface. Revisit with evidence |
| Grants in a multi-person repository | `sarah/habits.md` is committed, so a grant applies to every collaborator's agent. That is fine for a single-maintainer project. Revisit when a team adopts it |
| Per-executor credentials | Would need a broker. The blast radius is stated in §5.5 |
| A ceiling on `sarah/decisions.md` | The file does not exist yet |
| Server-side branch protection | Advice only |

## 8. Verified first in implementation

All four probes ran on 2026-10-24 against CLI 2.1.308, in a throwaway project,
and **all held**: no fallback applies. Verdicts are in the F3, F5, F16, F17 and
F18 rows above. Two consequences:

1. **`CLAUDE_CODE_EFFORT_LEVEL` silently removes per-call effort.** The
   operating docs say so, and the executor report names the effort it actually
   ran at.
2. **A forced platform fallback cannot be triggered on demand**, so F17 holds for
   a normal dispatch only; the D1 fallback re-dispatch covers the rest.

Re-run the probes when the CLI's major version changes.
