---
name: sarah-research
description: Investigate without changing anything - how something works, why it behaves this way, whether an approach is viable, what the options are. Produces findings, not code. Use when the user says "how does this work", "why does it do that", "investigate", "look into", "figure out", "is it possible to", "what are our options", or asks a question about the system rather than for a change to it.
---

# Research — find out, change nothing

Some questions are not tasks. "How does authentication actually work here?" and "could we move this to a queue?" both need investigation before anyone decides whether there is work at all.

This skill answers the question. It does not start the work the answer might imply.

## The one rule

**Change nothing.** No edits, no fixes, no "while I was in there". If the investigation reveals something broken, that is a finding — report it and let the user decide whether it becomes a task.

This rule is the whole value of the skill. An investigation that quietly turns into an implementation leaves the user with a change they never approved and an answer they never got.

## How to investigate

**Start from `ARCHI.md`** for anything architectural. It is the curated map and it is cheaper than reading the code. Then go to the code for the specific thing, because `ARCHI.md` is a map and maps are not the territory.

**Read what answers the question.** Not everything nearby. A research task that reads the whole codebase produces a summary of the codebase, which is not what anyone asked for.

**Trace one real path end to end** when the question is about behavior. One concrete trace teaches more than any amount of component description, and it exposes the assumptions that descriptions hide.

**Check whether the answer is already written down.** An existing ADR, a comment explaining a workaround, a design document. Rediscovering a decision from scratch and reaching a different conclusion is worse than useless — it produces confident contradiction.

## Distinguish what you found from what you infer

This matters more than anything else in the output.

- **Found:** "`RoutePlanner` calls the provider synchronously — `RoutePlanner.kt:88`."
- **Inferred:** "This probably means a slow provider blocks the request thread."
- **Unknown:** "Whether there is a timeout configured. I did not find one, which is not the same as there not being one."

Label all three. A research report that blends them into confident prose is the most dangerous artifact this framework can produce, because decisions get made on it — and an inference presented as a finding is a guess that has been laundered into a fact.

## What you return

- **The answer**, first, in a few lines. Someone asked a question; lead with the answer.
- **The evidence**, as file and line references. A claim without a reference is not checkable and will not be checked.
- **What you could not determine**, and what it would take to determine it.
- **What this implies**, clearly marked as implication, when the user asked whether something is viable.
- **Options, if the question was a decision.** Two or three, with trade-offs and a recommendation.

## Then stop

End with what the user could do next, in one line — not a plan for doing it.

If the research reveals work worth doing, the user says so and the phase skills take over from there, at whatever level the work actually is. That routing is not this skill's job, and doing it anyway is how "just take a look at this" becomes an afternoon of unrequested changes.
