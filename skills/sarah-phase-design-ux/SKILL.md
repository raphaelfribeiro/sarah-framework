---
name: sarah-phase-design-ux
description: Design the interaction before the interface - user flows, every screen state including empty and error, and the surface a developer will build. Use when the user says "how should it look", "design the screen", "what's the user flow", "what should the UI do", when a feature has any user-facing surface, or when a CLI's command shape and error messages need deciding.
---

# Phase 4 — Design and UX

Interaction first, surface second. A beautiful screen for a broken flow is wasted work, and it is expensive to discover that after it is built.

## When this phase applies

| Level | Applies |
| --- | --- |
| **0** | Never. |
| **1** | Only when the fix changes what a user sees or does. |
| **2** | For the surface the change touches. Not a redesign of everything nearby. |
| **3** | Always, for any feature with a user-facing surface. |

**A command-line tool has a user experience.** Command shape, defaults, behavior with no arguments, what the errors say, whether destructive actions confirm. Most tools are hostile because nobody treated this as design work. If the project is a CLI, this phase applies.

If the change has no user-facing surface at all, skip it. Say you are skipping it and why.

## Who works this phase

**UX/UI Designer**, alone. Spawn the `ux-ui-designer` agent.

## How it runs

1. **Read the approved spec** and whatever design language the project already has — existing screens, components, copy, conventions.
2. **Spawn the designer** with the spec and those conventions.
3. **Present flows and states**, concretely enough for the user to picture: numbered steps, state lists, sketches in text. An option nobody can picture is not a choice.
4. **Confirm the states nobody thinks about.** Empty, error, loading, unauthorized, offline. The empty state is the first thing every new user sees and the last thing anyone designs.
5. **Hand the developer a specification**, not a mood. Elements, hierarchy, states, copy, and the accessibility requirements the build must meet.

## Consistency beats local optimality

A slightly worse pattern used everywhere beats a slightly better one used once. When the designer introduces a pattern the project does not have, that is a decision to surface to the user, not a detail to slip in.

## What you never do

- Design a surface for a flow the user has not agreed to. Go back to the spec.
- Treat accessibility as a later audit. Contrast, target size, keyboard reach, and meaningful labels are part of the design.
- Write copy in a voice or language the product does not use.
- Leave the error path vague. "Something went wrong" is an abdication, and it is what ships when this phase is rushed.

## Exit gate

**The user approves the flows and states.** Then update `sarah/state.md`, commit the design and the state on the feature branch, and move to `sarah-phase-implement`.
