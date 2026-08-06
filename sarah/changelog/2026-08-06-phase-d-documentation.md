# Phase D — the documentation a stranger needs

**Date:** 2026-08-06 · **Level:** 3 · **Phase:** 5-implement

The framework was built and exercised, but everything a person needed in order
to adopt it, contribute to it, or judge whether it was worth adopting lived in
the maintainer's head. Phase D writes that down.

**Delivered:**

- **`.github/workflows/validate.yml`** — the repository had no automated
  validation at all. It deliberately does not shell out to `claude plugin
  validate`, which would need an authenticated CLI on a runner. Everything it
  checks is deterministic and offline: manifests parse, hooks pass `sh -n` and
  cannot exit non-zero, every skill carries loadable frontmatter, bodies stay
  under 500 lines, `sarah-bootstrap` stays inside its ~2,000-token budget, and
  no artefact references infrastructure other than GitHub.
- **`CONTRIBUTING.md`**, two issue templates and a pull request template. The
  issue templates lead with *a skill did not trigger*, because in a framework
  made of prose that is the failure that matters most and the one users are
  least likely to think worth reporting.
- **`docs/extending.md`** — the contract the optional boundaries obey, which
  `ARCHI.md` implied in a table but never stated. Detected at runtime, silent
  when absent, offered rather than automatic when present. It spends more words
  on what a tracker must never be — a second source of workflow truth — than on
  what it may do.
- **`docs/walkthrough-level-3.md`** — the instrumented run, with its measured
  numbers and its three limitations.
- **`docs/walkthrough-level-1.md`** — labelled illustrative at the top, and
  stating no figures at all, because no Level 1 run has been instrumented and
  plausible invented numbers are indistinguishable from real ones after the
  fact.
- **`README.md`**, rewritten. Its warning had claimed the phase pipeline and
  agent roster were not built yet, which stopped being true at Phase B — the
  most prominent sentence on the front page was false.

**The README now separates measured from claimed.** An Evidence section reports
what the instrumented run produced and then states, without softening it, that
no controlled comparison exists, that nothing published separates the
framework's contribution from the model's, and that the human gates have never
been exercised because headless runs must forbid the questions those gates are
made of. Until the comparative study exists, the five commitments are labelled
design intent rather than demonstrated results.

**The comparison names where the alternatives are ahead.** BMAD-METHOD, GitHub
Spec Kit, OpenSpec and Superpowers were each characterised from their own
documentation. Superpowers is the closest relative and is mature and widely
installed while this project is unreleased; Spec Kit has GitHub behind it;
OpenSpec is lighter to adopt; BMAD covers more roles. The Claude Code-only
constraint is stated as a limitation, and readers who want agent portability are
told to use something else.

**Not done, deliberately:** TRIP was named in the Phase D plan and is absent. No
framework or methodology by that name could be verified, and characterising a
project that may not exist would be worse than an incomplete comparison. If a
reference turns up it takes a paragraph to add.

**Still open:** the CI badge points at a workflow that has never run, because
nothing has been pushed to GitHub yet. It will show as failing or unknown until
the first push.
