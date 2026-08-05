---
name: sarah-compact
description: Measure ARCHI.md against its context budget and compact it without losing coverage. Use when the user runs /sarah-compact, says "ARCHI is too big", "compact the architecture doc", "trim ARCHI.md", when a session start reports the file over budget, or when the architecture memory has grown into a dump instead of a map.
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
---

# /sarah-compact — hold the line on ARCHI.md

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

## What never happens here

- Compacting a file that is within budget.
- Cutting invariants, sharp edges, or reasoning to hit a number.
- Rewriting without approval.
- Reporting the estimate as an exact count.
