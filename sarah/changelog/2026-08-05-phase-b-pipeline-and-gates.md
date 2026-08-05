# Phase B — The specialist roster, the phase pipeline, and the gates

**Date:** 2026-08-05 · **Level:** 3 · **Phase:** 5-implement

The pipeline became real. Ten specialists, seven phases, five gates, and the
artifact templates each phase produces.

- **Ten specialists** in `agents/` — product-analyst, product-manager,
  software-architect (opus, high effort), security-advisor, ux-ui-designer,
  developer, test-engineer, code-reviewer (high effort), devops-engineer,
  release-manager (haiku). Each carries the ask/options/approve protocol, an
  output contract, and an explicit statement of what it refuses to decide on the
  user's behalf.
- **Seven phase skills** in `skills/sarah-phase-*` — brainstorm, spec,
  architecture, design-ux, implement, review, release. Each states when it does
  *not* apply at a given level, which specialists it spawns, and its exit gate.
  Skipping a phase for known work is documented as correct behavior rather than
  as a shortcut.
- **Artifact templates live inside the skill that uses them** — spec and
  delta-spec, ADR, implementation plan — following the Phase A lesson that a
  skill must read its own references. Root `templates/` mirrors them by symlink,
  for humans browsing the repository.
- **`docs/quality-gates.md`** — the five gates in full, with the documentation
  gate scaled proportionally to the level.

**Budget.** Specialists are platform subagents, so a phase loads only its own.
The full roster costs ~1.1k tokens always-on for its frontmatter; each
specialist's body is paid only when it fires. Total always-on with nine skills
and ten agents: ~2,370 tokens.

**Verified** with a Level 1 bug fix end to end: classified Level 1, planned,
wrote boundary tests first, fixed the off-by-one, and closed the documentation
gate with an `ARCHI.md` note and a changelog entry. All four assertions pass.

**Found here, fixed in Phase C:** acceptance surfaced a case gate 4 had no answer
for — a session setting silently blocked the reviewer subagent, and the review
gate dissolved instead of stopping. `sarah-phase-review` now refuses to pass
quietly when no independent reviewer can run.

**Not yet real at the end of this phase:** the five commands, the hooks, and the
enforcement layer. Phase C.
