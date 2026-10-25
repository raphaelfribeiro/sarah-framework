# Habit catalog

What `/sarah-init` walks the user through at step 3.5. Everything the user reads is in plain words: no jargon, no rule IDs, no file names. Technical names appear only when the user says "details" (last section).

## Rules for every panel

1. A decision is an `AskUserQuestion`, never prose. Option 1 is the recommendation, marked `(Recommended)` only where the description opens with a fact checked in this run.
2. No answer is never a yes. A dismissed panel keeps the defaults, installs nothing and records no grant. Say so once: `You gave no answer to <header>, so I kept the lightest choice: <choice>.` Do not ask again in the same run.
3. A tick list ends with `None of these`. If it is ticked together with others, it is ignored.
4. First line of every output is `Decision needed: <what>.` or `No decision needed.`
5. Answer in the user's language; the copy below is the English source. Keep paths, variable names and dates as they are.
6. `_fixture` and `always-ask` are payloads, never choices. `_fixture` is the installer's test habit. `always-ask` is written whenever anything else is (see "Always asked").

## 1. Ground read (silent, before any question)

Never ask the user for these. Never print a credential.

```bash
command -v python3 >/dev/null && echo python3
git rev-parse --is-inside-work-tree 2>/dev/null; git remote -v 2>/dev/null | head -2
command -v gh >/dev/null && gh auth status >/dev/null 2>&1 && echo gh
ls .github/workflows 2>/dev/null; ls CHANGELOG.md 2>/dev/null; git tag 2>/dev/null | head -1
[ -n "${TRELLO_API_KEY:-}" ] && [ -n "${TRELLO_TOKEN:-}" ] && echo trello-vars
```

Also note: side lines of work unfinished for over 30 days, and any hook, workflow or branch rule the project already has.

## 2. The catalog

Each entry has a plain label, the failure it prevents, what it may block, what it needs, and whether its payload exists yet. **Pending entries are omitted from the panels (not offered) until their payload ships**; do not describe them or fake them. When an entry needs something the ground read did not find, omit it too, with one line before Call 1 and never installed half-working:
`Not offered here: <labels> (they need <what>; not found).`

### Keep demands on a Trello board

- Habit: tracker
- Status: available
- Failure: demands living only in chat and being lost between sessions.
- Blocks: nothing. It never blocks.
- Needs: python3, network
- Group: Board

You set `TRELLO_API_KEY` and `TRELLO_TOKEN` outside the project, never in this chat; a token that expires is best. Removing the board also removes the daily board check.

When chosen: ask for the board link (`Paste the link to the Trello board. The link is safe to share; a key is not. The board must be private.`). Write two lines under `## Tracker` in `sarah/habits.md`, keeping every other line (the script writes `Last audit:` itself):

```
- tracker: trello
- board: <id or link>
```

Then run `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/tracker.py" check` and relay only its status. A public board is refused: `That board is public, so I will not use it.` Missing variables: offer `Finish now, connect later (Recommended)`, `I will set them now` or `Skip the board`, and print how to create the key and token. Never ask the user to paste a token into the chat, and never print one.

### Pick the AI model for each task

- Habit: dispatch-guard
- Status: pending (payload not built yet)
- Failure: work running on a model nobody chose.
- Blocks: starting a task whose model is not set.
- Needs: python3
- Group: Board

### Protect the main line

- Habit: gitflow
- Status: pending (payload not built yet)
- Failure: work piling up in one place, and merges nobody tested.
- Blocks: saving straight onto the main line, and joining work whose tests fail. It may join finished work itself once its tests pass.
- Needs: python3, git, gh, remote
- Group: Main line

When this is chosen it adds two grants: save work online, and join finished work once its tests pass. Both appear in the summary, and each can be removed. If the project has no automatic tests, say: `This project has no automatic tests yet, so "passing" will mean only the branch check.`

### A release-note line per delivery

- Habit: changelog-fragment
- Status: pending (payload not built yet)
- Failure: release notes rebuilt from memory.
- Blocks: sending work for review without its one-line note.
- Needs: python3, git, gh
- Group: Main line

### Check the task still makes sense

- Habit: dispatch-guard
- Status: pending (payload not built yet)
- Failure: work built on something that is no longer true.
- Blocks: a task whose starting point is false.
- Needs: python3
- Group: Tasks

### Each task gets its own copy

- Habit: dispatch-guard
- Status: pending (payload not built yet)
- Failure: parallel work colliding in one folder.
- Blocks: a 4th task while 3 are running.
- Needs: python3, git
- Group: Tasks

### Keep working while work is waiting

- Habit: no-idle
- Status: pending (payload not built yet)
- Failure: a session ending with ready work untouched and an idle board.
- Blocks: stopping once, when work is ready. The user can still say stop.
- Needs: python3
- Group: Tasks

Three entries share the `dispatch-guard` payload; the tracker entry has no payload directory. Group rules: a group with no offered entry is dropped from the panels.

## 3. Panels

Print the defaults first, plain text:

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

**Call 1** (drop `Allowed` when the project has no online copy; drop a habit group with nothing offered). "Change some" gets one plain follow-up line (the numbers to turn off, or a limit other than 3), echoed in the summary and never asked twice. The named-machine option gets one plain question (which, why); no wildcards.

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

When any blocking habit is ticked, print once: `Any of these can be bypassed by an exception you grant: it names the rule, gives a reason and an end date, 14 days at most.`

**Call 2** (the Tasks group, then only the settings that apply):

```json
{"questions": [
 {"header": "Tasks", "question": "How each task runs. Which do you want?", "multiSelect": true,
  "options": [
   {"label": "Check the task still makes sense", "description": "Stops work built on something no longer true. Blocks a task whose starting point is false."},
   {"label": "Each task gets its own copy", "description": "Stops parallel work colliding. Up to 3 at once. Blocks a 4th until one finishes."},
   {"label": "Keep working while work is waiting", "description": "Stops a session ending with ready work untouched. You can still tell me to stop."},
   {"label": "None of these", "description": "Skip this group."}]},
 {"header": "Daily check", "question": "Check the Trello board against my notes once a day?", "multiSelect": false,
  "options": [
   {"label": "Yes, daily (Recommended)", "description": "Stops the board and the real work drifting apart. At most one line a day; silence when nothing changed."},
   {"label": "No daily check", "description": "The board is used only when you ask."}]},
 {"header": "Credit line", "question": "Add Co-Authored-By lines to commits?", "multiSelect": false,
  "options": [
   {"label": "No (Recommended)", "description": "Commits carry only your name."},
   {"label": "Yes", "description": "Commits and reviews name Claude as co-author, as Claude Code does by default."}]}]}
```

Ask Daily check only if the board was chosen, Credit line only if Protect the main line was.

**One question per collision** with a file the user already has (the installer reports it), and one for a file edited after install:

```json
{"questions": [
 {"header": "Your files", "question": "You already have <file>. What should I do with it?", "multiSelect": false,
  "options": [
   {"label": "Run alongside it (Recommended)", "description": "My check is added next to yours. Your file is not touched."},
   {"label": "Let me manage it", "description": "I take it over; the summary shows the change."},
   {"label": "Skip this habit", "description": "Nothing is added for it."}]},
 {"header": "Edited file", "question": "<file> was edited after I installed it. What now?", "multiSelect": false,
  "options": [
   {"label": "Keep my version (Recommended)", "description": "I stop managing it and leave it as it is."},
   {"label": "Replace with the stock one", "description": "Your edits are lost unless committed."}]}]}
```

`Run alongside` maps to the installer's `wrap`, `Let me manage it` to `adopt`, `Skip` to `skip`; `Keep my version` to `keep`, `Replace` to `overwrite`. If the two cannot coexist, option 1 becomes `Skip this habit (Recommended)`.

**`(Recommended)` on a habit** only when its description opens with the checked fact: `Your default level is 3.` (model, task check), `Found 4 side lines of work unfinished for over 30 days.` (main line: GitHub copy found and 3 or more), `This project already numbers its releases.` (release note), `You allowed 3 tasks at once; they would share one copy.` (own copy). Never on the board or keep-working entries.

## 4. Summary, write, handover

Print the summary from `habits.py plan`, not the raw diff (3 columns, at most 12 lines):

```
Decision needed: write this. Nothing existing is overwritten.
| Habit | What it adds | Can stop you from |
| --- | --- | --- |
Always written: your settings file (sarah/habits.md), ARCHI.md, README.md, sarah/state.md.
Allowed without asking: <grants>.
Always asked: deleting for good, rewriting history, spending money, touching passwords or keys.
Up to 3 tasks at once. Commit attribution lines: off. Everything added is a copy; nothing is downloaded.
```

`Nothing existing is overwritten` prints only if the plan reports zero conflicts.

```json
{"questions": [
 {"header": "Write", "question": "Write these files and settings?", "multiSelect": false,
  "options": [
   {"label": "Write it (Recommended)", "description": "Exactly what the list shows. The plan found no conflicts."},
   {"label": "Show me the exact files", "description": "I print every file and setting before writing."},
   {"label": "Change my choices", "description": "Back to the habit list, answers kept."}]}]}
```

With conflicts, option 1 becomes `Show me the exact files (Recommended)`.

**Commands** (`HABITS="python3 ${CLAUDE_PLUGIN_ROOT}/scripts/habits.py"`):

| Situation | Run |
| --- | --- |
| Show the plan | `$HABITS plan always-ask <habits>` |
| Approved | `$HABITS apply always-ask <habits>` |
| A grant was chosen | `$HABITS grant add push-feature --scope 'feature/*' --quote "<the user's words>"` |
| The user declined every habit | `$HABITS apply --none` (a re-run then knows; nothing else is written) |
| Verify | `$HABITS status` lists exactly the chosen set |

Without `python3` there is no installer: say `The optional habits need Python 3, and I cannot find it here. Everything else works without it.`, keep only Defaults and Allowed, write a grant row by hand in the Autonomy table (`| action | scope | date | said |`), and add: `I follow the always-asked list myself, but it is not enforced in settings until Python 3 is available.`

**Handover** (12 lines at most):

```
No decision needed. S.A.R.A.H. is set up.
Written: ARCHI.md (<size> of 10 KB budget), README.md, sarah/state.md, sarah/habits.md.
Habits on: <list, or none>. Off: everything else.
Working defaults: on. Up to 3 tasks at once. Commit attribution: off.
Allowed without asking: <grants, or nothing>. Always asked: deleting for good, rewriting history, spending money, passwords or keys.
Those allowances are saved with the project, so they apply to anyone using the agent here.
Mission parameters set. Tell me what to build first.
```

Print the "saved with the project" line only if a grant exists. If nothing was ticked: `No optional habits. Nothing was installed and nothing can block you. Ask me to add one whenever a problem shows up.` Later sessions say nothing about it.

## 5. Autonomy: grants and the always-asked list

- The recommended grant is **pushing `feature/*` branches**. Merging, force-pushing and deleting still ask, whatever is granted.
- **Always asked, whatever the list says**, and it cannot be granted away: deleting for good (recursive delete, force-push, deleting branches, rewriting history), spending money, touching passwords or keys. `habits.py` installs these as `permissions.ask` rules (the `always-ask` payload). They only tighten, they are in the project's settings, and `remove always-ask` takes out exactly what was added. Probe F18 verified they still prompt under permissive modes. Patterns are textual, so money has few of them; the rest is the agent's own rule.
- A plan does not authorise a risky action. Only a row in the Autonomy section does.
- **Grants are written only on the user's explicit instruction in that turn, quoted**: at init the panel answer, later the user's own sentence. `grant add` refuses an empty quote and any always-asked wording (`That one is always asked, whatever you allow: <item>. I will keep asking.`). Scope not named: one question `Which?` with the narrowest option first.
- Confirm with `Allowed from now on: <action> (you said: "<quote>").`, then offer the prompts question:

```json
{"questions": [
 {"header": "Prompts", "question": "Also stop the permission prompts for it?", "multiSelect": false,
  "options": [
   {"label": "Yes, add it (Recommended)", "description": "Goes in your personal settings file, not shared. Without it the platform still asks in default mode."},
   {"label": "No, keep the prompts", "description": "The platform keeps asking each time."}]}]}
```

- **The framework never writes an `allow` rule on its own.** `$HABITS grant allow` only shows the diff for `.claude/settings.local.json`. Run `$HABITS grant allow --write` only after a yes on the question above. Revoke: `$HABITS grant revoke <action> --scope <scope>` deletes the row and the rules the framework wrote; one line, no question.

## 6. Re-run and later changes (no new command)

If `sarah/habits.md` exists, init has already asked: never re-ask an answered question. Print, then ask:

```
No decision needed unless you want a change.
| Habit | State | Since |
| --- | --- | --- |
Working defaults: on. Up to 3 tasks at once. Allowed without asking: <grants>.
```

```json
{"questions": [
 {"header": "Set-up", "question": "S.A.R.A.H. is already set up here. What do you want to do?", "multiSelect": false,
  "options": [
   {"label": "Leave it as it is (Recommended)", "description": "Nothing changes."},
   {"label": "Add a habit", "description": "Shows only the habits that are off."},
   {"label": "Remove a habit", "description": "Tell me which; I remove only what I added."},
   {"label": "Refresh ARCHI.md or start over", "description": "Old files are backed up first."}]}]}
```

- **Add:** show that habit's tick list, then the summary and the Write question.
- **Remove:** `$HABITS remove <habit>`. If every file is unchanged there is no question. Report in 3 lines: `Removed: <habit>.` / `Also removed with it: <dependents, or omit>.` / `Your own files were not touched.`
- **Allow or revoke:** section 5.
- Exceptions to a blocking habit arrive with the main-line habit and are handled there.

## Details

Shown only when the user says "details".

| Plain label | Technical name |
| --- | --- |
| Keep demands on a Trello board | tracker (R9, R12) |
| Pick the AI model for each task | declared executor, model, effort (R10, R11) |
| Protect the main line | gitflow guard, green-CI merge (R13) |
| A release-note line per delivery | changelog fragment (R14) |
| Check the task still makes sense | premise re-check (R15) |
| Each task gets its own copy | worktree per task, WIP limit (R17, R18) |
| Keep working while work is waiting | board never empty (R24) |
