# Delta spec — the habits that earned their place

**Date:** 2026-10-24 · **Level:** 3 · **Status:** approved 2026-10-24 (Gate 1)

## Context

S.A.R.A.H. v0.1.0 gives a project structure (phases, state, gates) and no operating habits. Two bodies of evidence say which habits matter. The reference project (a private product run with Claude Code without the framework) grew habits from incidents, and they held only once they became mechanisms; written rules had already failed. The measurement pilot (S.A.R.A.H. on a private project) shows what the framework lets go missing and what it over-produces: roughly 14 questions per session, 104 of 855 questions being "continue or stop?", 89% of single-choice answers taking the first option, a 155 KB state index read every session, and one feature branch with 779 commits never merged.

Rule of entry: a habit born from an incident, installed in a project that never had it, is weight. Every habit below names the failure it prevents, and is installed only if the user picks it. Conversation rules (R1-R8) are the exception: they answer pilot findings that apply to every user, and they are defaults the user can turn off.

All "Evidence" lines are aggregate. Nothing private from either source project enters this repository.

Anchors to: `ARCHI.md` §3 System shape, §4 Data and state, §5 Boundaries (tracker row), §7 Invariants.

## ADDED Requirements

### R1 - Decisions are structured questions

Every decision the user must make is asked as a structured choice with 2-3 options, honest trade-offs and a recommendation, never buried in prose.
Failure prevented: decisions lost inside long messages; the pilot's free-text answers (8%) were where gates changed outcomes, so the structured question must always leave room for free text.

**Accepted when:**
- A decision point in any phase skill produces a structured question, not a paragraph ending in "what do you think?".
- Every such question offers a free-text path.

### R2 - No continuation questions

Within approved work the agent keeps going. It stops only when the user says stop, when a bounded order is met ("do 3 tasks and stop"), or at a decision gate (spec approved, plan approved, review verdict, release). Gates still stop for the user; "continue or stop?" never does.
Failure prevented: 104 of 855 pilot questions were continuation questions, and the answers were "keep going".

**Accepted when:**
- After a task completes inside approved work, the next task starts with no question.
- After "do 2 tasks and stop", the agent stops after exactly 2 and reports.
- Each of the six approval gates still halts until the user answers.

### R3 - The agent runs what it can run

The agent never hands the user a command it can execute itself, and tests its own work before reporting it. It asks only for what it cannot do (credentials, physical access, a decision).
Failure prevented: pilot users repeatedly asked "you do it" and "test it yourself".

**Accepted when:**
- A report contains no copy-paste command for something the agent had permission and means to run.
- Every report of finished work states what the agent itself ran to check it and the result.

### R4 - Short, plain text; details on request

User-facing text is short and non-technical by default: outcome first, then what is needed from the user. Framework terms (scale level, gates, trade-offs) are explained in the project's own terms the first time they matter. Technical detail is given only on request.
Failure prevented: the scale level was not understood on day 1; reports and state files are almost never read.

**Accepted when:**
- A gate question or status report is readable without framework vocabulary and states in its first line whether a decision is needed.
- Asking "why" or "details" yields the technical explanation.

### R5 - Recommendations rest on verified facts

Before a recommendation is made, each fact it depends on is checked against the code, the docs or the running system; a fact that cannot be checked is labelled unverified in the question.
Failure prevented: 89% of single-choice answers took the first option and the user reports trusting it without deep reading; in the pilot one unverified recommendation was doubted by the user, who was right.

**Accepted when:**
- Each recommendation lists the facts it depends on, each marked verified (with where) or unverified.
- A recommendation resting on an unverified fact says so in the question text itself.

### R6 - Decisions are remembered and reconciled

Decisions the user has made are recorded where the next session reads them. The agent never re-asks a recorded decision. New work is checked against recorded decisions, and a conflict is surfaced as one question naming the earlier decision, never resolved silently.
Failure prevented: already-answered questions asked again ("I already answered", twice in one session); a day-1 "permanent" exclusion resurfaced in the pilot with no visible reconciliation.

**Accepted when:**
- A decision answered in session N is not asked again in session N+1.
- A task that contradicts a recorded decision (including a "permanent" exclusion) produces one question that quotes the decision, its date and the conflict.

### R7 - Unattended execution within approved work

Once a plan is approved, the agent executes it without supervision, including long or overnight runs, and records anything it could not finish rather than stopping to ask.
Failure prevented: pilot users asked to "run overnight without me".

**Accepted when:**
- After plan approval, a multi-task run completes with zero non-gate questions.
- Blocked items are listed in the final report with the reason; the run does not halt on them unless every remaining task depends on them.

### R8 - Habit catalog in `/sarah-init`

`/sarah-init` offers the catalog (R9-R17 and R24) as opt-in habits, each shown with the failure it prevents and, for agreements, what it may block. The chosen set is recorded in the project, and nothing unchosen is installed.
Failure prevented: habits installed into projects that never had the incident are pure weight.

**Accepted when:**
- Each habit is presented with its failure statement and a plain accept/decline choice.
- After declining all, the project has no tracker config, no installed hook or CI file, and the framework works as in v0.1.0.
- The recorded set can be read by every later session in one small read.

### R9 - Optional tracker (Trello first)

If chosen, demands enter a Trello board and the framework manages them there; the board is the intake and the task list of record for chosen projects.
Failure prevented: demands living only in chat and being lost between sessions.

**Accepted when:**
- A demand given in chat appears as a card with its task state linked.
- Credentials are never written into the repository, state files or logs.
- Absent, invalid or revoked credentials, or an unreachable tracker: see Edge cases.

### R10 - Task declares its executor

Each task declares executor, model, effort and fallback before it starts.
Failure prevented: work run at a model and effort nobody chose, in the pilot's "specific agents at specific effort" demand.

**Accepted when:**
- A task cannot move to "in progress" without the four fields.
- If the declared model is unavailable, the declared fallback is used and the report says so.

### R11 - Fixed brief and fixed report

The orchestrator hands each executor a brief of fixed shape, with more detail for weaker executors. The executor returns a report of fixed shape: done / proof / not finished / requested tasks.
Failure prevented: reports that bury what was not finished and executors guessing at intent.

**Accepted when:**
- Every executor report has the four sections, each present even when empty.
- "Done" claims without a "proof" entry are rejected by the orchestrator.

### R12 - Daily board audit

If R9 is chosen, a daily audit compares board and state, and records its findings as one deduplicated issue that closes itself when the findings clear.
Failure prevented: drift between board and reality that is found only by accident.

**Accepted when:**
- Two consecutive days with the same finding produce one issue, not two.
- A day with no findings closes the open audit issue.

### R13 - Gitflow guard and green-CI merge (agreement)

If chosen, the project's pull requests and merges follow the branch model in `docs/branching.md`, and a merge needs green CI. May block.
Failure prevented: integration never happens (one branch, 779 commits, never merged) and unverified merges.

**Accepted when:**
- A direct commit to a protected permanent branch, or a merge with red CI, is refused with a message naming the rule and the exception path (R16).
- Commit-attribution lines (e.g. `Co-Authored-By`) are a separate yes/no choice inside this module, asked by `/sarah-init`, **default off** (decided by the user, Q4).

### R14 - Changelog fragment per delivery (agreement)

If chosen, each delivery carries a changelog fragment with one user-facing sentence that feeds the release notes. May block.
Failure prevented: release notes reconstructed from commit logs after the fact.

**Accepted when:**
- A delivery without a fragment is refused; with one, its sentence appears in the next release notes.

### R15 - Premise re-check before a task starts (agreement)

If chosen, before a task starts its premises are re-checked against the current code and against recorded decisions (R6). May block.
Failure prevented: tasks built on assumptions that stopped being true.

**Accepted when:**
- A task whose stated premise is false does not start, and the user gets one question with the evidence.

### R16 - Named, reasoned, expiring exception

Any blocking agreement can be bypassed only by an exception that names the rule, states a reason and carries an expiry date. Exceptions are recorded, listed in `/sarah-status`, and lapse automatically.
Failure prevented: a blocking rule blocks something the user needs now, and the only escape is disabling the rule for good.

**Accepted when:**
- A bypass without reason or expiry is refused.
- After the expiry date the rule blocks again with no action by the user.
- Active and recently expired exceptions are visible in `/sarah-status`.

### R17 - Worktree per task under a WIP limit (agreement)

If chosen, each task runs in its own worktree that is ready to work in when created (dependencies present, state file in place). A WIP limit caps simultaneous tasks. May block starting a task over the limit.
Failure prevented: parallel agents colliding in one working tree.

**Accepted when:**
- Starting task N+1 over the limit is refused with the list of running tasks.
- A fresh worktree runs the project's checks without manual setup.

### R18 - Default of up to 3 parallel tasks

`/sarah-init` proposes up to 3 simultaneous tasks as the default WIP limit, each with its own executor at a declared model and effort (R10). The user can change the number.
Failure prevented: the pilot's demand for "3 parallel fronts max".

**Accepted when:**
- With defaults accepted, the recorded limit is 3.
- Three tasks can be in progress at once, each with its own executor declaration.

### R19 - State files stay small enough to be read

State is sized for a reader who almost never reads it. Failure prevented: the pilot's index reached 155 KB, task files 125 KB and 91 KB, all read every session.

**Accepted when:**
- The state index stays under 8 KB and each task file under 16 KB (decided by the user, Q5).
- Past the limit, the session start reports it and offers compaction (as `/sarah-compact` does for `ARCHI.md`); it is never silent and never blocks.
- A session reads only the index plus the one relevant task file (already true; stays true).

### R24 - Work does not idle at session end (agreement)

If chosen, a session does not end with nothing in progress while ready work exists in the tracker or the task index: the agent takes the next ready item instead of stopping. It still stops when the user says stop, when a bounded order is met, or at a decision gate (R2).
Failure prevented: in the reference project, sessions ending with an idle board while ready work waited drew a complaint every day until it was enforced.

**Accepted when:**
- With ready work and no stop order, the agent starts the next item rather than ending the turn.
- With a stop order, a bounded order met, or a gate open, it stops and reports.
- With no ready work, it stops and says so in one line.

## MODIFIED Requirements

### R20 - `/sarah-init`

**Today:** interviews for greenfield/brownfield, scale level and the three base files.
**Becomes:** also presents the catalog (R8), records chosen habits, sets the parallelism default (R18), and is safe to re-run.

**Accepted when:**
- Re-run on a project that already chose habits shows the current set, changes nothing unless the user says so, and never re-asks answered questions.
- Adding or removing a habit later (R22) works through the same entry point, with no sixth command.

### R21 - `/ill-be-back` and `/hasta-la-vista`

**Today:** full situation report and debrief (46 and 67 lines of instruction).
**Becomes:** same purposes, each producing a short output: the opening proposes the day as options; the closing says what shipped, what is open and what is decided. Both stay.

**Accepted when:**
- Each ritual's output fits one screen and states in its first line whether a decision is needed.
- The closing still updates state and changelog and checks the documentation gate.

### R22 - Removing a habit

**Today:** not applicable.
**Becomes:** the user can remove any chosen habit; the framework removes what it installed and leaves the user's own files alone.

**Accepted when:**
- After removal, no file the framework installed for that habit remains, and the recorded set no longer lists it.
- A hook, CI file or branch rule the user had before is untouched.

### R23 - Bootstrap points at a template that exists

**Today:** `skills/sarah-bootstrap/SKILL.md` says to create a task file "from `references/task-template.md`"; `skills/sarah-bootstrap/references/` holds only `itinerary.md`, so the instruction cannot be followed.
**Becomes:** it names a template that exists and is reachable from that skill, without growing the file past the token ceiling.

**Accepted when:**
- Following the instruction literally in a fresh project finds the template.
- `skills/sarah-bootstrap/SKILL.md` remains under its ~2,000-token budget (the CI check passes).

## REMOVED Requirements

None. No existing skill contains a continuation prompt to remove (checked by search); R2 is purely additive.

## Unchanged but affected

- `sarah-bootstrap` token budget (~1,950 of 2,000) - R1-R7 need a home that is not this file (Q2).
- Hooks as sensors - R13-R17 and R24 must not turn plugin hooks into blockers (Q3).
- Agent roster rule - R10/R11 executors must not add to every session's context (Q1).
- Five-command ceiling - R8, R20, R22 reuse `/sarah-init`.
- `sarah-phase-release`, `/sarah-status`, `/sarah-compact` - read the new fragments, exceptions and size limits.
- ARCHI.md §5: the tracker row already lists Trello as optional and "never raised if absent"; R9 turns it from detected to configured.
- Approval gates - unchanged; R2 only removes non-gate questions.

## Edge cases and failure behavior

| Case | Expected behavior |
| --- | --- |
| User declines every optional habit | R8 criteria: v0.1.0 behavior plus conversation defaults only; no nagging on later sessions |
| Tracker credentials absent | Tracker never raised after the user declined; if chosen but missing, one question to supply them, then work continues without the board |
| Credentials invalid or revoked | One clear message naming the tracker and what to renew; work continues from local state; no retry loop; credentials never printed |
| Tracker unavailable mid-session | Local state is the source of truth; board writes queue and reconcile when it returns; no session halt |
| Project already has hooks, CI or its own branch model | Detected at init; the framework does not overwrite or duplicate them; the user is asked whether to adopt, wrap or skip the module |
| No GitHub Actions | CI-dependent habits (R12, R13 green-CI) are offered with the missing prerequisite stated, or skipped; never installed half-working |
| Blocking agreement blocks something needed now | Exception per R16; never a silent bypass, never a permanent disable by default |
| `/sarah-init` re-run on chosen project | R20 |
| User wants to remove a habit later | R22 |
| Recommendation fact cannot be verified | R5: labelled unverified in the question |
| Plugin hook cannot read config or tool missing | Silence and exit 0 (invariant unchanged) |

## Out of scope

- Trackers other than Trello (the interface must not make adding one a rewrite, but none ships).
- A sixth command.
- Three habits not yet offered: regression test per incident proven by mutation; "green is not proof" CI gates; shared-resource lock between agents. (The fourth, board never empty, is R24.) Reason: each needs its own incident evidence in this framework's users, not only the reference project's; revisit after v0.2.0 (Q7).
- Any private detail of the reference project or the pilot.
- Changing the pilot's install (it stays pinned to v0.1.0).
- Auto-updating a user's chosen habits when the catalog changes.
- Dashboards or metrics over habit usage.

## Open questions

| Question | Blocks | Options on the table |
| --- | --- | --- |
| Q1 Executors: ten agent files vs one parameterized executor | R10, R11 | (a) ten files: simple selection, but ten descriptions in context every session and a direct strain on "never load the full roster". (b) one executor taking model and effort as parameters: one description, flexible, but model tiers in plugin agents may not be parameterizable. **Recommend (b)**; architecture confirms feasibility |
| Q2 Where do conversation defaults R1-R7 live, given the bootstrap has ~50 tokens of headroom | R1-R7 | (a) raise the 2,000-token ceiling: cheapest, but taxes every task forever. (b) shrink bootstrap by moving content to a skill that loads on demand: keeps the ceiling, costs a rewrite. (c) put them in the user's project at init, as a short rules file: no plugin cost, but depends on the project loading it. **Recommend (b)**, falling back to (c) |
| Q3 Blocking habits vs "hooks never block" | R13-R17, R24 | (a) agreements are installed into the user's project (project-owned hooks/CI/branch rules), plugin hooks stay sensors: **Decided by the user 2026-10-24.** Invariant intact; ARCHI.md §7 wording should state that installed agreements are the user's, not the plugin's |
| Q4 Commit attribution: Claude Code adds Co-Authored-By through its own attribution setting (the plugin ships none); the reference project bans it | R13 | **Decided by the user 2026-10-24: the user chooses at init, default off.** |
| Q5 State size limits (8 KB index, 16 KB task) | R19 | **Decided by the user 2026-10-24: 8 KB index, 16 KB per task file.** |
| Q6 "Keep going" vs gates | R2 | **Decided by the user 2026-10-24** (friction interview): decisions are always questions; continuation is never asked |
| Q7 The four habits not yet offered: in or out | cut line | **Decided by the user 2026-10-24: board never empty enters as R24; the other three stay out.** |
| Q8 Does R2/R7 conflict with the "Every phase ends with a commit" invariant? | R7 | Unattended runs commit within their branch (allowed); push and merge still need the user unless R13 is chosen. **Recommend** stating that in ARCHI.md §7 |
