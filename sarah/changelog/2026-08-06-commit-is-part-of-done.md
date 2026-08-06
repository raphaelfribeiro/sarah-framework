# Commit is part of done

**Date:** 2026-08-06 · **Level:** 2 · **Phase:** 5-implement

The framework promised small, frequent commits in `agents/developer.md` and
demanded them nowhere. `skills/sarah-phase-implement/SKILL.md` never mentioned
committing; `docs/quality-gates.md` never mentioned it either. A promise in a
persona with no gate behind it is decoration.

The instrumented Level 3 runs of 2026-08-05 and 2026-08-06 both ended the
implementation phase with **147 tests passing and zero commits** — the same
failure twice, from two independent runs, which makes it a defect in the
framework rather than a bad day.

Running the 2026-08-06 pipeline to completion sharpened the diagnosis. The
framework does not fail to commit; it **defers everything to the release phase**
and then catches up. Eight phases collapsed into three commits: one carrying
spec, architecture, design and governance together, one carrying the entire
implementation **and the review fixes fused into it** at 2,849 lines, and one
for CI and release notes. A 2,849-line commit is the exact negation of "each one
a point you could rewind to", and merging the review fixes into the code under
review destroys the record of what the reviewer caught. Late bulk committing is
the failure mode, and it is worse than none at all because it looks like
compliance.

**What changed:**

- **Gate 5 is now "Documented and committed is part of done."** It carries a
  table of what committing means per level, and states that the pull request
  belongs at the delivery boundary rather than at every phase.
- **Six phase skills close the loop themselves** — spec, architecture, design,
  implementation, review and release each end by committing what they produced.
  Brainstorm does not, because it writes nothing to disk.
- **`sarah-bootstrap` non-negotiable 5** was rewritten to match, in words rather
  than lines: the file sits at roughly 1,570 tokens against its 2,000 ceiling.
- **A new invariant in `ARCHI.md`**, because this is now a property of the
  system and not merely a policy.

**Why the pull request is not per phase.** A Level 3 delivery has seven phases,
four of which produce only documents. Gates 1, 2 and 4 already require a human
at each of those points. A pull request per phase would bolt a second approval
mechanism onto the same control point and buy ceremony instead of rigour. The
pull request stays where `docs/branching.md` already put it: at delivery, into
`develop`, merged by a human.

**Not done here:** nothing enforces this at runtime. The framework is prose a
model reads, so the gate holds because the model follows it — which is exactly
what the next instrumented run has to check. Whether phase-closing commits
actually happen is now an open question for the Phase E study, and it is
measurable from the same logs that measured everything else.
