---
name: sarah-phase-architecture
description: Decide the structure and the choices that are expensive to reverse - boundaries, data ownership, failure behavior - and record the reasoning. Use when the user says "how should we build this", "which stack", "what database", "how do we structure it", when a change crosses component boundaries, when a decision would be costly to undo, or when an approved spec needs a design before implementation.
---

# Phase 3 — Architecture

This phase decides the small number of things that are hard to change later. Everything else belongs to the people writing the code.

## When this phase applies

| Level | Applies |
| --- | --- |
| **0** | Never. |
| **1** | Only if the fix reveals a structural problem. Then stop and escalate the level rather than architecting inside a bug fix. |
| **2** | Only for the parts the change actually touches — a new boundary, a schema change, a new dependency. Not a redesign. |
| **3** | Always. |

## Who works this phase

**Software Architect** — running on the most capable model, because errors here are paid for over years.

**Security Advisor** — consulting, not deciding. Bring them in whenever the design touches authentication, authorization, secrets, personal data, or an external boundary. They advise; the architect integrates; the user decides.

Horizontal consultation, no cross-domain authority: the architect does not overrule the security advisor within their domain, and the security advisor does not make architecture calls.

## How it runs

1. **Read the approved spec and the relevant parts of `ARCHI.md`.** Targeted reads.
2. **Spawn the `software-architect`** with the spec, the existing architecture, and any constraints already on record.
3. **Spawn the `security-advisor`** in parallel when the change touches their surface. Give them the same input.
4. **Present the options to the user.** For each: what it makes easy, what it makes hard, what it costs to reverse, and what must be true for it to be right. Then the recommendation, with reasons.
5. **Record the decision.** Every decision that survives becomes an ADR from `references/adr-template.md`, and a one-line entry in the `ARCHI.md` decisions table.

## Cost discipline

Every layer of indirection is paid on every future change. When the architect proposes something elaborate, make them name the specific requirement forcing it. "We might need it later" is not a requirement, and the layer added for it will still be there when later never comes.

## What you never do

- Design for scale the project does not have and has not committed to having.
- Let the architect decide security posture or deployment mechanics alone. Consult the specialist who owns it.
- Accept a decision without its reasoning. A choice whose why is lost gets reversed by the next person who does not know it.
- Leave `ARCHI.md` stale. An architectural change updates it before this phase closes — that file is what the next task reads instead of the codebase.

## Exit gate

**The user approves the design.** Then, before moving on:

- ADRs written for the decisions that matter.
- `ARCHI.md` updated: structure, boundaries, invariants, decisions table.
- `sarah/state.md` updated.

Next is `sarah-phase-design-ux` when there is a user-facing surface, otherwise `sarah-phase-implement`.
