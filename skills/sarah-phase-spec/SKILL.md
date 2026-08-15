---
name: sarah-phase-spec
description: Turn an agreed problem into requirements that can be built and verified. Writes acceptance criteria, sets the cut line, and produces a spec or a brownfield delta-spec. Use when the user says "write the spec", "what exactly should it do", "define the requirements", when scope needs pinning down before implementation, or when brainstorm has settled on a scope. Also use when a feature request needs sharpening into something testable.
---

# Phase 2 — Specification

This phase ends with something a developer can implement and a tester can check, with nothing important left in anyone's head.

## When this phase applies

| Level | Applies | Shape |
| --- | --- | --- |
| **0** | Never | — |
| **1** | Lightly | A paragraph and an acceptance criterion, inside the plan. No separate document. |
| **2** | Yes | A lean spec: requirements, acceptance criteria, what is out of scope. One page or so. |
| **3** | Yes | The full document. |

The specification is proportional to the work. Producing a full spec for a small change is the failure mode, not the safe option.

## Who works this phase

**Product Analyst** and **Product Manager**. The analyst holds the problem; the PM turns it into requirements. On a brownfield change where the problem is already understood, the PM alone is enough.

## Greenfield versus brownfield

**Greenfield** — write the spec from `references/spec-template.md`.

**Brownfield** — write a delta-spec from `references/delta-spec-template.md`: `## ADDED`, `## MODIFIED`, `## REMOVED` requirements, anchored to what `ARCHI.md` already says. Everything unmentioned is unchanged.

Never demand a specification of the whole existing system. That is the mistake that makes frameworks unusable on real codebases: it produces a document too large to keep true, which then rots and is trusted anyway.

## How it runs

1. **Read `ARCHI.md`** for the parts the change touches. Targeted reads only — never the whole file as a routine step.
2. **Spawn the `product-manager`** with the agreed scope and what `ARCHI.md` says.
3. **Bring back the draft** and walk the user through the requirements.
4. **Force the cut line.** Get the out-of-scope list explicitly agreed and written. Unwritten exclusions are where scope creep comes from.
5. **Resolve the open questions.** A spec with unresolved questions is not finished. Present each as options with trade-offs.

## What you never do

- Write requirements nobody can verify. If there is no observable outcome, it is a wish.
- Skip the failure behavior. Empty, duplicate, unauthorized, unavailable are requirements too, and specs usually go quiet exactly there.
- Let the spec drift into design. What, not how. The architect decides how.
- Pass a spec forward with open questions buried inside it as assumptions.

## Gate 1 — spec approved

**The user approves the spec.** This gate is hard: nothing is architected until it closes.

The machines propose. The human decides. No exceptions.

Then write the spec to the project (`docs/specs/` or wherever the project keeps them), update `sarah/state.md`, **commit both on the feature branch** — an approved spec that exists only in the working tree is not delivered — and move to `sarah-phase-architecture` — or, when the change needs no architectural decision, straight to `sarah-phase-implement`.
