# UX spec - the habits that earned their place

**Date:** 2026-10-24 - **Level:** 3 - **Status:** revised after the user's answers to Decisions A-D; for Gate 3 - **Inputs:** [spec](the-habits-that-earned-their-place.md) R1-R24, [architecture](the-habits-that-earned-their-place.architecture.md) D1-D9, ADR-006 to 010

The surface is a conversation: chat text, `AskUserQuestion` panels, one-line status facts. This file is the contract for the skill bodies, `references/habits-catalog.md` and the hook output.

## 0. Rules for everything below

1. A decision is an `AskUserQuestion`, never prose. Every panel keeps its free-text path.
2. Option 1 is the recommendation, labelled `(Recommended)`. **A label appears only if its description cites a fact checked in this run** (R5): the user takes option 1 about 89% of the time without deep reading.
3. **No answer is never a yes** to anything that installs, blocks or grants. A dismissed panel keeps defaults, installs nothing, records no grant. Say so; do not re-ask in the same run.
4. No continuation questions. Stop only on a stop order, a met bounded order, or a gate (lines in 6.5).
5. First line of every output: `Decision needed: <what>.` or `No decision needed.`
6. **Plain language.** The user is not a specialist. Labels and descriptions say what the habit does for them, never how it works. Banned in user-facing text unless the user asks for "details": worktree, WIP, gitflow, CI, pull request, manifest, executor, hook, premise, agreement, rule IDs (R13). Say "its own copy of the code", "automatic tests", "sending work for review", "the main line of work". Technical names, paths and IDs appear only on request.
7. Never re-ask what `sarah/habits.md` or `sarah/decisions.md` answers. Never hand over a command the agent can run.
8. Language: copy here is the English source that ships. In chat the agent answers in the user's language, translating panels and status lines, and keeping paths, env var names and ISO dates as they are.
9. Voice: confident, direct, faintly military. One Resistance line per section, marked **[R]**.

## 1. `/sarah-init`

New **step 3.5, "Working agreement"**, between scale level and Generate. `SKILL.md` grows by at most 40 lines; options and payloads live in `references/habits-catalog.md`. **Init always walks the full catalog** (Decision A); there is no "start light" fork. It stays short because the catalog is seven one-line items in three groups, answered with ticks. Step 0 (welcome) is unchanged on first run, skipped on re-run.

### 1.1 Silent ground read (add to step 1; never ask the user for it)

python3; git repo; GitHub remote, `gh`, `gh auth status`; any automatic-test workflow; count of side lines of work unfinished for over 30 days; `CHANGELOG.md` or tags; existing hooks, CI or branch rules; any remote at all; whether `TRELLO_API_KEY` and `TRELLO_TOKEN` are set (`[ -n "${VAR:-}" ]`, never printed).

### 1.2 Flow and question budget

1. Welcome (first run), ground read, interview, scale level (unchanged).
2. Print `Decision needed: a few quick choices about how we work.` and the defaults list (1.3). **Call 1 (4 questions):** defaults, what I may do unattended, the Board group, the Main-line group.
3. **Call 2 (up to 4):** the Tasks group, then only the settings that apply: daily board check (if Trello), commit attribution (if Main line), one question per collision with a file the user already has.
4. If Trello was chosen: section 2 (may add **Call 3**, one question).
5. If anything is to be installed or an allow rule added: summary and **Call 4** (1.7), one question.
6. Generate, verify (`habits.py status` lists exactly the chosen set), hand over (1.8).

| Path | Questions | Calls |
| --- | --- | --- |
| Minimum (defaults accepted, nothing ticked) | 5 | 2 |
| Typical (a few habits, Trello not chosen) | 7 | 3 |
| Worst (all habits, Trello with missing token, one collision) | 11 | 5 |

Groups with no available habit are dropped, which lowers the count. No sixth call. The Tasks group is in Call 2, not Call 1, so its labels can use the task limit the user just set. (Before this revision the typical path was 9 questions; the pilot averaged about 14 per session.)

### 1.3 Call 1

Printed first, plain text:

```
These are my working defaults. Say "details" for the technical version.
1. Decisions come to you as questions, with my recommendation first.
2. I keep going until you say stop, or until a number you gave is met.
3. I run what I can run, and test my own work before I report it.
4. Short, plain reports. Details when you ask.
5. I check facts before I recommend, and I remember what you decided.
6. Once you approve a plan, I carry it out without supervision.
Up to 3 tasks at once. Always asked, whatever you allow: deleting for good,
rewriting history, spending money, touching passwords or keys.
```

```json
{"questions": [
 {"header": "Defaults", "question": "Keep these working defaults?", "multiSelect": false,
  "options": [
   {"label": "Keep them all (Recommended)", "description": "They answer the most common complaints about long sessions. Each can be turned off later."},
   {"label": "Change some", "description": "Tell me the numbers to turn off, or a limit other than 3 tasks at once."}]},
 {"header": "Allowed", "question": "What may I do without asking, while you are away?", "multiSelect": false,
  "options": [
   {"label": "Save my work online (Recommended)", "description": "Lets an overnight run keep its work safe, on a side line, never the main one. Publishing and deleting stay with you. Applies to anyone using the agent in this project."},
   {"label": "Save online, plus one machine I name", "description": "For work that needs another computer or a device. I will ask which one and why."},
   {"label": "Nothing yet, ask each time", "description": "Safest. You can allow things later by telling me."}]},
 {"header": "Board", "question": "Board and task setup. Which do you want?", "multiSelect": true,
  "options": [
   {"label": "Keep demands on a Trello board", "description": "Stops requests getting lost between sessions. You set up a Trello key yourself, never in this chat. Never blocks you."},
   {"label": "Pick the AI model for each task", "description": "Stops work running on a model nobody chose. A task will not start until its model is set."},
   {"label": "None of these", "description": "Skip this group."}]},
 {"header": "Main line", "question": "Protection for your project's main line of work. Which do you want?", "multiSelect": true,
  "options": [
   {"label": "Protect the main line", "description": "Stops work piling up in one place and untested merges. Blocks saving straight onto the main line and joining work whose tests fail. I may join finished work myself once its tests pass."},
   {"label": "A release-note line per delivery", "description": "Stops release notes being rebuilt from memory. Blocks sending work for review without its one-line note."},
   {"label": "None of these", "description": "Skip this group."}]}]}
```

Rules:
- "Allowed" is dropped when no online copy (remote) exists; the summary says `Allowed without asking: nothing`. It is labelled only because a remote was found.
- "Change some": one plain follow-up line; echoed in the summary; never asked twice. The named-machine option: one plain question (which, why); no wildcards.
- When any blocking habit is ticked, print once (R16): `Any of these can be bypassed by an exception you grant: it names the rule, gives a reason and an end date, 14 days at most.`
- "None of these" is last in every tick list; if ticked with others it is ignored.

### 1.4 Call 2 - the Tasks group, then settings

```json
{"header": "Tasks", "question": "How each task runs. Which do you want?", "multiSelect": true,
 "options": [
  {"label": "Check the task still makes sense", "description": "Stops work built on something no longer true. Blocks a task whose starting point is false."},
  {"label": "Each task gets its own copy", "description": "Stops parallel work colliding. Up to 3 at once. Blocks a 4th until one finishes."},
  {"label": "Keep working while work is waiting", "description": "Stops a session ending with ready work untouched. You can still tell me to stop."},
  {"label": "None of these", "description": "Skip this group."}]}
```

Settings questions (all `multiSelect: false`; more than 4 questions total start a second call):
- **Daily check** (Trello chosen): `Check the Trello board against my notes once a day?` `Yes, daily (Recommended)` - "Stops the board and the real work drifting apart. At most one line a day; silence when nothing changed."; `No daily check`.
- **Attribution** (Main line chosen): `Add Co-Authored-By lines to commits?` `No (Recommended)` - "Commits carry only your name."; `Yes` - "Commits and reviews name Claude as co-author, as Claude Code does by default."
- **Your files** (one per collision, unstamped file): `You already have <file>. What should I do with it?` `Run alongside it (Recommended)` - "My check is added next to yours. Your file is not touched."; `Let me manage it` - "I take it over; the summary shows the change."; `Skip this habit`. If the two cannot coexist, option 1 is `Skip this habit (Recommended)`.
- **Edited file** (re-run, stamped file changed): `<file> was edited after I installed it. What now?` `Keep my version (Recommended)` - "I stop managing it and leave it as it is."; `Replace with the stock one` - "Your edits are lost unless committed."

**When `(Recommended)` may appear on a habit** (the description opens with the checked fact, in plain words):

| Habit | Only if | Description opens |
| --- | --- | --- |
| Trello board | never | n/a |
| Pick the model | default level 2 or 3 | `Your default level is 3.` |
| Protect the main line | online copy on GitHub found and 3 or more side lines unfinished over 30 days | `Found 4 side lines of work unfinished for over 30 days.` |
| Release-note line | `CHANGELOG.md` or tags exist | `This project already numbers its releases.` |
| Check the task | default level 3 | `Your default level is 3.` |
| Own copy per task | git exists and the limit is 2 or more | `You allowed 3 tasks at once; they would share one copy.` |
| Keep working | never | n/a |

If "Protect the main line" is shown and no automatic tests exist, append: `This project has no automatic tests yet, so "passing" will mean only the branch check.`

### 1.5 Unavailable habits are omitted

One line before Call 1, once, and the item is not in the panel:

```
Not offered here: Protect the main line and Release-note line (they need a GitHub copy of the project and the gh tool; neither found).
```

Main-line habits need git, a GitHub copy and `gh`; "own copy per task" needs git; the others need only Python 3. No git: also say once `This folder has no git history. I can set it up if you want those; say so.` (the agent runs `git init` itself; no panel).

### 1.6 Prerequisite and empty states

| State | Behaviour and copy |
| --- | --- |
| No `python3` | Call 1 keeps Defaults and Allowed only. Before it: `The optional habits need Python 3, and I cannot find it here. Everything else works without it.` Handover: `Habits: none installed (Python 3 not found). Install it and ask me to add habits.` plus `I follow the always-asked list myself, but it is not enforced in settings until Python 3 is available.` |
| Tracker token missing, rejected, or Trello unreachable | Section 2 |
| Habit already installed | Not offered on re-run; `Already on: <list>.` precedes any panel. If asked to add: `Protect the main line has been on since 2026-10-24. Nothing to change. Say so if you want different settings.` Matching file: silent |
| No GitHub automatic tests | Habit still offered, with the "passing will mean only the branch check" sentence. The daily board check needs none |
| User ticks nothing | `No optional habits. Nothing was installed and nothing can block you. Ask me to add one whenever a problem shows up.` Later sessions: silence |
| Panel dismissed or empty | Lightest choice: `You gave no answer to <header>, so I kept the lightest choice: <choice>.` |

Verify at build whether a tick list can be submitted empty; the design does not depend on it.

### 1.7 Summary and Call 4

Printed from `habits.py plan`, not the raw diff. Header row, 3 columns, one line per cell, at most 12 lines.

```
Decision needed: write this. Nothing existing is overwritten.
| Habit | What it adds | Can stop you from |
| --- | --- | --- |
| Protect the main line | A check on your computer and automatic tests online | Saving onto the main line; joining work whose tests fail |
| Release-note line | A check on your computer | Sending work for review without its note |
| Trello board | Nothing in your project | Nothing |
Always written: your settings file (sarah/habits.md), ARCHI.md, README.md, sarah/state.md.
Allowed without asking: save work online; join finished work once its tests pass.
Always asked: deleting for good, rewriting history, spending money, touching passwords or keys.
Up to 3 tasks at once. Commit attribution lines: off. Everything added is a copy; nothing is downloaded.
```

`Nothing existing is overwritten` prints only if the plan reports zero conflicts; otherwise the conflict list replaces it. Call 4, header `Write`, `Write these files and settings?`: `Write it (Recommended)` - "Exactly what the list shows. The plan found no conflicts."; `Show me the exact files` - "I print every file and setting before writing."; `Change my choices` - "Back to the habit list, answers kept." With conflicts, option 1 becomes `Show me the exact files (Recommended)`. "Change my choices" reopens Call 1's catalog groups only.

### 1.8 Handover (12 lines max)

```
No decision needed. S.A.R.A.H. is set up.
Written: ARCHI.md (4.1 KB of 10 KB budget), README.md, sarah/state.md, sarah/habits.md.
Habits on: protect the main line, release-note line. Off: everything else.
Working defaults: on. Up to 3 tasks at once. Commit attribution: off.
Allowed without asking: save work online. Always asked: deleting for good, rewriting history, spending money, passwords or keys.
Those allowances are saved with the project, so they apply to anyone using the agent here.
Mission parameters set. Tell me what to build first.
```

**[R]** is the last line. The "saved with the project" line prints only if a grant exists. `Habits on: none` if nothing was ticked. No "run /something" instruction.

## 2. Trello setup (R9)

1. Plain prompt: `Paste the link to the Trello board. The link is safe to share; a key is not. The board must be private.`
2. The agent runs the check itself (variables set, not printed; `tracker.py check`). Only status is shown. The project keeps the board ID and the two variable names, nothing else.
3. Missing credential, **Call 3**, header `Trello`, `I cannot see a Trello key in my environment. How do you want to go on?`: `Finish now, connect later (Recommended)` - "You set the two variables outside this chat. A running session usually cannot see new ones, so I connect the board myself at your next session."; `I will set them now` - "I wait. You set TRELLO_API_KEY and TRELLO_TOKEN, then tell me. I check once."; `Skip the board`. Printed with it:

```
Create an API key and a token in your Trello account. Prefer a token that expires (30 days is a sensible length).
Put them in two variables, TRELLO_API_KEY and TRELLO_TOKEN, in your shell profile or Claude Code's user settings.
Not in this project's files, which are shared. Never paste them here.
```

| State | Copy | Then |
| --- | --- | --- |
| Connected | `Trello connected: board "<name>", private.` | `connected` |
| Token rejected (401) | `Trello rejected the token. Renew it and I will reconnect next session. Working from local notes.` | Said once, no retry, no question |
| Unreachable | `Trello did not answer. I saved the board and will connect when it is back. Everything works from local notes.` | No question |
| Public board | `That board is public, so I will not use it.` | Panel: `Use another board (Recommended)` / `Skip the board` |
| Not a Trello link | `That is not a Trello board link. Paste the board's link, or say skip.` | One retry, then skip |

**Later sessions.** Waiting for credentials: one silent check at session start; if it passes, say `Trello connected: board "<name>".` once and start intake; if not, say nothing. Mid-session, once per session: `Trello rejected the token. Renew it. I am working from local notes and will not retry.` or `Trello is not answering. Working from local notes; I will sync when it is back.` A demand given offline gets `Card: pending`. The token is never printed, quoted, logged or briefed, even in errors.

## 3. Re-running `/sarah-init` (R20)

Print, then ask:

```
No decision needed unless you want a change.
| Habit | State | Since |
| --- | --- | --- |
| Protect the main line | on | 2026-10-24 |
| Trello board | waiting for credentials | 2026-10-24 |
Working defaults: on. Up to 3 tasks at once. Allowed without asking: save work online.
Exceptions: none active.
```

The first line says `Decision needed:` only if something is broken. Panel, header `Set-up`, `S.A.R.A.H. is already set up here. What do you want to do?`: `Leave it as it is (Recommended)`; `Add a habit` - "Shows only the habits that are off."; `Remove a habit` - "Tell me which; I remove only what I added."; `Refresh ARCHI.md or start over` - "Old files are backed up first." Answered questions are not re-asked.

## 4. Changing things later (no new command)

Through `sarah-init`, which must fire on "remove the release-note habit", "add the Trello board", "you can use <machine> without asking", "stop letting yourself save online", "make an exception". Same entry as init (R20, R22).

- **Remove (R22).** Unknown: `That habit is not installed. Installed: <list>.` If every added file is unchanged, **remove with no question**: the order is the approval. If a file was edited, one question: `<file> was edited after I installed it. What should I do with it?` `Keep it, stop managing it (Recommended)` / `Delete it too`. Report in 3 lines: `Removed: release-note line per delivery.` / `Also removed with it: <dependents, or omit>.` / `Your own files were not touched.` Dependents: Trello takes the daily check; Protect the main line takes its two allowances and attribution setting. All removed: `Removed everything I added. This project now runs as before, plus the working defaults.` A default is turned off the same way ("turn off 4"): one echoed line.
- **Add.** Show that habit's one-line item as a tick list, then the 1.7 summary for it, then Call 4. Skip the list if the user already named it.
- **Allowances (D9).** Written only on the user's explicit instruction this turn, quoted. Always-asked item: `That one is always asked, whatever you allow: <item>. I will keep asking.` Scope not named: one question `Which?` with the narrowest option first, `(Recommended)`. Confirm: `Allowed from now on: <action> (you said: "<quote>").` Then one question, header `Prompts`, `Also stop the permission prompts for it?` `Yes, add it (Recommended)` - "Goes in your personal settings file, not shared. Without it the platform still asks in default mode."; `No, keep the prompts`. Revoke: delete the row and the framework's prompt rule; one line, no question.
- **Exceptions (R16).** Only on the user's instruction, never proposed by the agent. Missing reason: `What is the reason?` Missing date: `3 days (Recommended)` / `7 days` / `14 days`. Longer: `The longest is 14 days. I set <date>.` Confirm: `Exception recorded: <rule>, until <date>, reason "<reason>". It lapses by itself.`

## 5. Status lines

Shape: `<Subject>: <fact>. <what I did or what is next>.` One line, two at most. Lead words `Done`, `Blocked`, `Not finished`, `Skipped`. The hook prints facts; the model relays only a change.

**Session-start hook output (model context, within 400 tokens with the 200-token defaults text):**

```
Habits: protect the main line, release-note line, Trello (waiting for credentials). Limit: 3 tasks. Defaults: on.
Size: sarah/state.md is 9.1 KB, over its 8 KB limit. Offer to compact once, at the first pause.
Tracker: token rejected 2026-10-20.
Audit: due today.
Exceptions: 1 active (release-note line, until 2026-11-03).
```

`Habits: none` when nothing is on. `Tracker:` values: `connected`, `waiting for credentials`, `token rejected <date>`, `not answering`. A marker `sarah/.local/compact-snoozed` with today's date silences `Size:` for the day.

**Compaction offer (R19, Decision D decided).** Once a day, at the first natural pause: inside the `/ill-be-back` call, otherwise after the first task. Never before the user's request, never mid-task, never blocking. Header `Notes size`, `The state index is 9.1 KB (limit 8 KB). Trim it?` `Trim it (Recommended)` - "Nothing is lost: finished tasks move to the changelog. I show what moves before I write."; `Not today` - "I will not ask again until tomorrow." Result: `Trimmed: state index 9.1 KB to 5.8 KB. 2 task files removed; their text is in the changelog.`

**Daily board check (R12).** Relayed only on change, 4 lines at most, never a question: `Board check: 2 differences. "Export screen" is in Doing but the task is blocked; "Sync" has no card.` / `Details are on the audit card.` Cleared: `Board check: clean. The audit card is closed.` Unchanged: silence. Moved by hand counts as a difference. Unreachable: `Board check skipped: Trello did not answer. I will retry tomorrow.` (once).

**An executor's report as relayed (R11).** The four sections stay in the task file. At most 4 lines per task, empty lines omitted:

```
Done: export screen. Checked by running the tests (42 passed) and opening it in the emulator.
Not finished: dark-mode colours. The screenshot test needs a device I was not allowed to use.
Waiting for you: 1 proposal from the run (add retry to sync).
```

`Checked by` is mandatory on any `Done`; without proof the orchestrator re-briefs once, silently, then: `Not finished: <task>. No proof was given, so I am not calling it done.` Backup model used: `Ran on <model> instead of <declared> (backup used).`; otherwise model and effort are hidden. Requested tasks never interrupt; they become proposals in the next decision call. Run start, one line: `Started 3 tasks: <A>, <B>, <C>.`

**Exception in use (R16).** First use per session per rule: `Exception in use: release-note line, until 2026-11-03 (reason: release hotfix). Used 2 times.` With 3 days or fewer left, add `It lapses in 2 days.` `/sarah-status` lists `Rule | Until | Reason | Uses`, active first, then rows expired in the last 14 days marked `expired`.

**Task limit (R17).** A queue, so unattended runs continue: `Limit reached: 3 of 3 tasks running (export, login, sync). "Search" starts when one finishes.` / `To run more at once, tell me the new limit.`

### 5.5 Blocks and stops

The agent complies first (reroutes, waits, fixes) and says what it did. The exception path is stated as a fact only when no compliant route exists, never offered as a panel option.

| Event | Copy |
| --- | --- |
| Save onto the main line | `Blocked: saving straight onto the main line breaks your project rules. I moved the work to a side line, feature/export.` |
| Join with failing tests | `Blocked: joining waits for passing tests. 2 checks are failing: lint, tests. I am fixing them.` |
| Missing release note | `Blocked: sending this for review needs a release-note line. I wrote one: "<sentence>".` |
| False starting point | `Task not started: <what changed> is no longer true (<evidence>).` Panel: `Rewrite the task (Recommended)` / `Drop the task` |
| No model on a task | `Task not started: it has no model set. I set it from the plan.` (panel if the plan lacks it) |
| No compliant route | `Blocked: <rule>. I cannot do this without breaking it. A named exception of up to 14 days is the only way past.` |
| Rule could not be checked | `Rule not checked: <rule> (<reason>). I let it through.` |
| Next item taken / none ready | `Next up: <item>.` / `Nothing is ready to start. Stopping here.` |
| Bounded order met / stop order | `Done: 3 of 3 cards. Stopping as ordered.` / `Stopped. State is saved.` |

## 6. Rituals (R21)

### 6.1 `/ill-be-back` - at most 10 lines plus one panel

Reads only `sarah/state.md`, the one or two moving task files, the newest changelog file, `git status --short` and commits since the last close. Lines in order, omitted when empty, about 110 characters each: verdict; `Last session:` (concrete; omit if nothing shipped); `Waiting on you:` (oldest pending decision with age in days, the headline); `In flight:` (up to 5 as `name (phase)`, then `and N more`); `Heads-up:` (git versus state, uncommitted work; 2 max). No headings. **When a line would list more than 2 items, it becomes one short table instead** (decided by the user at Gate 3); otherwise plain lines. Panel of at most 3 questions: the day's plan; the oldest pending decision with its real options; the compaction offer if due. **Choosing is the go signal**: no work before it, no "shall I start?" after. Writes nothing.

```
Decision needed: today's plan.
Last session: shipped the export screen. The login change is still in review.
Waiting on you: how sync should work (4 days).
In flight: export screen (done), login change (review), sync (blocked).
Heads-up: 3 files changed and not committed.
```

Panel `Today`, `Which plan for today?`: `Finish the review, then ship (Recommended)` - "Closes the login change and releases the export screen. Sync waits."; `Unblock sync first` - "Needs your answer to the next question." Panel `Sync`, `How should sync work?`: `Polling every minute (Recommended)` - "Simple, and works offline-first. Unverified: battery cost on the target phones."; `Push from the server` - "Faster, but needs a server change." Nothing in flight: `No decision needed. Nothing in flight.` then plain `What shall we build?` Instruction body: at most 30 lines (from 46). No Resistance line; the command name is the allusion.

### 6.2 `/hasta-la-vista` - at most 10 lines, a panel of at most 2 questions

Still writes: task files, index, changelog entry, `sarah/decisions.md` for decisions that still bind, silent pruning of exceptions older than 14 days. With Trello on it syncs without comment and reports failures only. The old "offer to sync the cards" line goes. Lines in order: verdict; `Shipped:` (delivered, with what was run and the result; code never run goes under Open); `Open:` (up to 3, what each waits on, readable with no memory); `Decided today:` (up to 3, "Saved."); `Docs:` (`Missing: <item>.` reported, never silently fixed); `Still running:` only if verified that background tasks stop at session end.

```
Decision needed: two small ones.
Shipped: export screen. Ran the tests (42 passed) and opened it in the emulator.
Open: login change (needs review); sync (needs your choice).
Decided today: sync uses polling. Saved.
Docs: state and changelog updated. Missing: the README still shows the old export button.
```

Panel `README`, `The README still shows the old export button. Fix it now?`: `Fix it now (Recommended)` - "One edit, included in the commit."; `Carry it to next time`. Panel `Commit` (only if files changed; Decision C decided), `Commit the 4 changed files to feature/export?`: `Commit (Recommended)` - "Message: \"feat: export screen with share button\". Not sent online."; `Leave them uncommitted`. Then do the answers and sign off once. **[R]** `Hasta la vista.` Nothing after it. A day with no delivery: `No decision needed. Nothing shipped today; recorded as such.` and no changelog entry. Sending online is not part of the close unless an allowance covers it. Instruction body: at most 35 lines (from 67).

## 7. Limits

| Surface | Limit |
| --- | --- |
| Option label | 40 characters with `(Recommended)` |
| Option description | 200 characters; a habit says what it prevents, then what it can block |
| Question text | 120 characters |
| Panel | 4 questions, 4 options |
| Init summary, handover | 12 lines each |
| Ritual text | 10 lines, 110 characters; one short table allowed for more than 2 items, its rows counting toward the 10 |
| Executor relay / board check | 4 lines |
| Status or block line | 2 lines |
| Session-start hook | 400 tokens total |
| `SKILL.md` | under 500 lines; `sarah-init` adds at most 40; `sarah-bootstrap` adds nothing |

## 8. Accessibility (terminal text)

- No meaning in colour, emoji or symbols. State is a word: `Done`, `Blocked`, `on`, `off`, `expired`. No check marks, arrows or box drawing.
- `(Recommended)` is literal text in the label, not only position. Labels stand alone and start with distinct words; `None of these` is always last.
- Tables: header row, 3 columns (4 for exceptions), one line per cell, no merged cells, meaning also stated in the sentence before. Rituals use a table only for more than 2 items, never for one or two.
- ISO dates; units on durations and sizes. Never refer to layout ("the table above").
- Prose lines under about 100 characters. All input is arrow keys, Enter or typing, with the free-text path. No spinners or countdowns.

## 9. New patterns to approve (together with the design at Gate 3)

- Evidence-gated `(Recommended)`: many habits show no label, but a label can be trusted.
- `None of these` last in every tick list, and an unanswered panel meaning the lightest choice.
- Habits whose prerequisites are missing are left out, with one `Not offered here` line.
- Trello state "waiting for credentials", connecting itself at the next session.
- The hook prints facts and the model relays only a change.
- Block messages that comply first and never offer an exception as a choice.
- A task limit that queues instead of refusing.
- A compaction offer once a day, snoozed by a local marker.
- Rituals without headings; a short table only when there are more than 2 items (user decision, Gate 3).
- The close asks a commit question (replaces "suggest, do not run").
- Add, remove, allow and exception handled in conversation through `sarah-init` only.

## 10. Plain-language rule applied: catalog names and their technical names

Shown to the user only on "details".

| Plain label | Technical name |
| --- | --- |
| Keep demands on a Trello board | tracker (R9, R12) |
| Pick the AI model for each task | declared executor, model, effort (R10, R11) |
| Protect the main line | gitflow guard, green-CI merge (R13) |
| A release-note line per delivery | changelog fragment (R14) |
| Check the task still makes sense | premise re-check (R15) |
| Each task gets its own copy | worktree per task, WIP limit (R17, R18) |
| Keep working while work is waiting | board never empty (R24) |

## 11. Decisions (decided by the user, 2026-10-24)

| | Decision | Answer |
| --- | --- | --- |
| A | Order of the habits fork | **Changed:** no fork. Init always walks the full catalog, in plain words, grouped, one line per item, ticks with recommended choices marked. "I want the full one, and the user chooses things in a simple, objective way, without many technical terms." |
| B | Init's recommended unattended allowance | Save work online (push to feature branches), recommended |
| C | Does the close commit | One question, `Commit (Recommended)` |
| D | Compaction offer | After the first task or inside the opening, once a day |

## 12. Left to the developer's judgment

- Wording in languages other than English; the English source is the contract.
- The verified Trello page for creating a key (do not guess the URL).
- What "Let me manage it" does without git history (suggest a `.bak` outside the manifest); how "run alongside" is realised per habit. The contract: the user's file is untouched and both run.
- Shell date arithmetic and exact format of the `Size:`, `Audit:`, `Exceptions:` lines.
- Whether background tasks survive session end (decides `Still running:`).
- Whether a tick list can be submitted empty; how `(Recommended)` and `None of these` render live.
- How "details" is answered. Sections 5 and 6 copy doubles as test fixture text (line counts, lead words, first-line rule).
