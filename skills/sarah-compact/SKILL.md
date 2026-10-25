---
name: sarah-compact
description: Measure ARCHI.md against its context budget and compact it without losing coverage, and trim sarah/state.md and the task files in sarah/state/ when they outgrow their size limits. Use when the user runs /sarah-compact, says "ARCHI is too big", "compact the architecture doc", "trim ARCHI.md", "the state file is too big", "trim the notes", when a session start reports a `Size:` line or the file over budget, or when the architecture memory has grown into a dump instead of a map.
allowed-tools:
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - AskUserQuestion
  - Bash(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/token_budget.py" *)
  - Bash(git *)
  - Bash(wc *)
  - Bash(date *)
---

# /sarah-compact — hold the line on ARCHI.md

This command trims two things: `ARCHI.md` (steps 1-5) and the state files (the last section; go straight there when the session start reported a `Size:` line). Neither is touched unless it is over its limit.

`ARCHI.md` has a hard ceiling: 10% of the context window. The ceiling is not tidiness. A file too expensive to read gets skimmed, and a skimmed memory is worse than no memory — it is trusted without being read.

## 1. Measure first

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/token_budget.py" ARCHI.md
```

Pass `--window` when the session's context window is not 200,000.

The count is an estimate — there is no tokenizer offline — calibrated to within roughly 10%. Report it as an estimate. A reading near the ceiling is near the ceiling; do not argue over the last hundred tokens.

**If the file is `OK`, stop here.** Report the number and do nothing. Compacting a file that fits is how curated memory gets ground down into notes — and this command is invoked precisely by people inclined to tidy.

## 2. Find what does not belong

Read `ARCHI.md` and judge each section against one question: *would a competent engineer joining tomorrow need this, and could they cheaply find it themselves?*

Cut, in this order:

1. **Rediscoverable facts.** Directory listings, full schemas, exhaustive file inventories, API signatures. `ls` is free and always current; this file is neither.
2. **Fixed sharp edges.** The `Sharp edges` section is a live list, not a graveyard. An entry describing something already repaired is pure cost.
3. **Prose that restates a table.** Say it once.
4. **Decision records copied in full.** Section 6 is an index. One line and a link; the reasoning lives in the ADR.
5. **Superseded architecture.** Structure that no longer exists. History belongs to git.

## 3. What never gets cut

These are the highest-value lines in the file and they are also the shortest, so they are rarely why it is over budget:

- **Invariants.** The rules that must stay true. Exactly what an agent or a newcomer would otherwise violate without knowing.
- **Sharp edges that are still sharp.** The traps.
- **Failure behavior at boundaries.** What happens when a dependency is down.
- **Why a decision was made.** A decision whose reasoning is lost gets reversed by the next person who does not know it.

Compression means saying the same thing in fewer words. It does not mean saying less. If coverage drops, this command has done damage rather than work.

## 4. Propose before writing

Show the user what you would cut and what it saves, as a short list. Then the new estimate.

Never rewrite `ARCHI.md` unasked. It is hand-curated by design, and it is the one file where an unrequested edit destroys something a person deliberately put there.

**ask → present the cuts → the user decides → write → measure again.**

## 5. When cutting is not enough

A file that is still over budget after honest compaction is telling you something structural. Present the options:

- **Extract to linked documents.** Detail moves into `docs/`, `ARCHI.md` keeps the map and the links. Usually the right answer.
- **Split by subsystem.** A root `ARCHI.md` pointing at per-subsystem files. For genuinely large systems.
- **Accept the overrun deliberately.** Sometimes a system really is complex. That is the user's call to make explicitly — not a default to drift into.

## The state files

`sarah/state.md` (the index) may reach 8,192 bytes and each `sarah/state/*.md` task file 16,384. The session start prints a `Size:` line for a file over its limit. Measure before anything else:

```bash
wc -c sarah/state.md sarah/state/*.md
```

**If every file is within its limit, stop and say so.** Same rule as above: do not tidy what fits.

Otherwise, work through these four steps in order and stop as soon as the files fit:

1. **Delete the files of shipped tasks.** A task whose work is merged and recorded in `sarah/changelog/` no longer needs its file. Remove its row from the index too.
2. **Move finished narrative to the changelog.** Completed phases, long histories and "what happened" prose belong in a `sarah/changelog/` entry, not in state.
3. **Move durable lessons** into `ARCHI.md` section 8 or into `docs/`, one line and a link where the detail already lives.
4. **Move decisions that still bind** into `sarah/decisions.md`: one dated line per decision, newest first, creating the file if it does not exist. A "permanent" exclusion is stored as permanent, not as an ordinary line.

**Propose before writing.** Show which files would be deleted, what moves where, and the sizes before and after. Then ask with `AskUserQuestion`, header `Notes size`, for example question `The state index is 9.1 KB (limit 8 KB). Trim it?`:

- `Trim it (Recommended)`: "Nothing is lost: finished tasks move to the changelog. I show what moves before I write."
- `Not today`: "I will not ask again until tomorrow."

The user decides, then you write, then you measure again and report one line: `Trimmed: state index 9.1 KB to 5.8 KB. 2 task files removed; their text is in the changelog.`

**On "Not today"**, write today's date (from `date +%Y-%m-%d`) as the only line of `sarah/.local/compact-snoozed`, creating the directory if needed. The session-start hook reads that marker and stays quiet about size for the rest of the day. Change nothing else.

Never delete a task file whose work is not shipped, and never drop a decision to save bytes.

## What never happens here

- Compacting a file that is within budget.
- Cutting invariants, sharp edges, or reasoning to hit a number.
- Rewriting without approval, for `ARCHI.md` and for the state files alike.
- Deleting a task file whose work has not shipped.
- Reporting the estimate as an exact count.
