---
name: sarah-phase-brainstorm
description: Explore an idea before anyone commits to building it. Shapes the problem, finds who has the pain, surfaces unstated assumptions, and produces scope options. Use when the user says "I have an idea", "I want to build an app", "new project", "what if we", "I'm thinking about", or brings a problem with no agreed solution - even when they never say brainstorm. Also use when a request is an idea rather than a requirement.
---

# Phase 1 — Brainstorm

The machines write the code. You command the mission.

This phase exists to stop good execution of the wrong idea. It ends with a problem sharp enough to argue with, not a plan.

## When this phase applies

| Level | Applies |
| --- | --- |
| **0** | Never. Go straight to code. |
| **1** | Never. The problem is already known — it is a bug or a small, understood change. |
| **2** | Only when the request arrives as an idea rather than a requirement. If the user knows what they want, skip to spec. |
| **3** | Always. |

Skipping this phase for known work is correct behavior, not a shortcut. Running it on a bug report is the front-loading failure this framework exists to avoid.

## Who works this phase

**Product Analyst** — and nobody else. Do not pull in the architect: technology talk this early anchors the solution before the problem is understood, and it is remarkably hard to undo.

Spawn the `product-analyst` agent for the analysis. It returns the shaped problem; you bring it to the user.

## How it runs

1. **Listen first.** Let the user describe the idea in their own words before asking anything. The vocabulary they use is data.
2. **Spawn the analyst** with what the user said and whatever the repository already reveals.
3. **Bring back the shape**, not a transcript: the problem in three sentences, who has it, what they do today instead, and the assumptions it rests on.
4. **Challenge one thing.** If an assumption would sink the idea when wrong, say so now. This is the cheapest moment in the entire project to be wrong.
5. **Present scope options.** Smallest useful thing, obvious middle, ambitious version — each with what it buys and costs. Recommend one and say why.

Use `AskUserQuestion` when the options are genuinely a choice between paths. Use plain prose when you are asking the user to tell you something you do not know.

## What you never do

- Propose a stack, a framework, or a database. Not yours, not this phase.
- Turn the idea into a feature list and call it analysis. A list of features is an answer to a question nobody asked yet.
- Invent users or research. An admitted gap beats a fabricated persona, which launders a guess into a fact everyone then builds on.
- Produce a document. This phase output is a conversation and a decision, not an artifact.

## Exit gate

The user agrees on the problem and picks a scope. Nothing is written to disk yet.

Then update the task's file in `sarah/state/` — phase, level, and the scope that was chosen — commit it, and move to `sarah-phase-spec`. The conversation produced no document, but the decision it reached is an artefact, and an uncommitted decision is one nobody can find later.

If the user decides the idea is not worth building, that is a successful outcome for this phase. Record it, **commit it**, and stop — this is the one path with no next phase to carry the record forward, so an uncommitted "we decided against it" is lost entirely. Killing an idea in an afternoon is the highest-value thing that happens here.
