# The map the user never saw

**Date:** 2026-08-15 · **Level:** 2 · **Phase:** 5-implement

The framework routed correctly and told nobody. `/sarah-init` interviewed and
configured without ever showing the workflow; `sarah-bootstrap` chose a phase in
silence. A user could not tell which steps existed, which had run, or which had
been skipped for the size of the work — and a process nobody can audit is a
process nobody should trust.

## What changed

- **`/sarah-init` opens with a welcome and the map.** Eight steps, their owners,
  their deliverables, and the two rules that govern them: the process shrinks to
  the work, and every real decision is the user's. Printed before the first
  question, because someone signing up for a workflow should see it first.
- **`sarah-bootstrap` names what it steps over.** One line before the work: the
  phase being entered, and any earlier phase the level skips, named. Skipping is
  correct at low levels; skipping silently is not.
- **`README.md` carries the same map**, plus who the framework is for, who it is
  not for, and what it does not do.
- **Gates are numbered where they fire.** Gate 1 in spec, gates 2 and 3 in
  implement, gate 4 in review, gate 5 in release. The README promised five gates
  and the phases never used the word.

## Gaps this closed

| Gap | Status |
| --- | --- |
| `test-engineer` was invoked by no skill — QA had no owner | Fixed: implement spawns it for the failing test |
| Observability and rollback existed nowhere in the framework | Fixed: fourth deliverable of the release phase, scaled by level |
| No welcome, no map, no visible position in the workflow | Fixed |
| Gates unnamed in the phases that enforce them | Fixed |

## Not a gap, though it looked like one

The two-to-three-options decision protocol appears in only two phase skills. It
is not missing from the other five: it lives in `sarah-bootstrap`, which is
injected into every session, so repeating it per phase would cost context to
restate a rule already in scope.

## Deliberately not done

The phase fusion from the cut proposal — brainstorm, spec, architecture and
design-ux into one shaping phase — is still open. It is the change most likely
to reduce the measured 21% cost premium, and it is a bigger decision than a day
of visibility work. `sarah-bootstrap` now sits at ~1,724 tokens against its
2,000 ceiling.
