# The Level 3 pipeline, exercised end to end

**Date:** 2026-08-05 · **Level:** 3 · **Phase:** 5-implement

The oldest debt in this repository is paid, most of the way. Levels 0 and 1 were
verified long ago; brainstorm through release as one continuous run never was.
It has now been run against a real greenfield project — a Python CLI storing
markdown notes with front matter, tags and full-text search — chosen to be small
enough to reach a release and real enough to have a filesystem, git, a command
surface and a test pyramid.

**All eight steps completed**, from `/sarah-init` to a tagged release. The
project ended with 144 tests passing, three commits, `v0.1.0` tagged, a CI
workflow, and two changelog entries of its own.

**Gate 4 held with no human in the loop.** The review step spawned
`sarah:code-reviewer` and `sarah:security-advisor` without being asked for
either by name, and the review returned three blockers and four minor findings.
Fixing them took a commit of its own. This is the same gate that dissolved
during Phase B acceptance when its reviewer became unavailable; it now stops
instead of passing quietly.

**Still unproven, and not claimed:**

- **Gate 3 — tests before code.** The step that wrote the tests was not
  instrumented, and the suite was never observed running red before the source
  existed. The only evidence is that `tests/` appeared before `src/`, which is
  ordering, not proof.
- **Steps 1 to 5 ran uninstrumented.** Whether `product-analyst`,
  `software-architect` and `ux-ui-designer` were actually spawned is unknown.
  Only the review and release steps were captured in enough detail to tell.

Re-running instrumented from step 1 settles both, and belongs with the Level 3
walkthrough in Phase D, which has to be written anyway.

**A defect in the method, not the framework.** The first attempt died at the
implementation step, hitting a twelve-minute timeout. The rerun finished the
same step in under three. The framework was never the thing that failed; the
harness around it was.
