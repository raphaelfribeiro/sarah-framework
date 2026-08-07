# Phase E — the study ran, and the instrument did not discriminate

**Date:** 2026-08-07 · **Level:** 3 · **Phase:** 5-implement

Six builds of one brief — three with S.A.R.A.H., three with plain Claude Code —
scored blind by three judges each against a rubric committed before the first
run. Eighteen scores. $280.76.

**Every artefact scored 43 or 44 out of 44.** Judges agreed closely, so this is
not noise hiding a signal: the rubric had no room left to record a difference.
The comparison is inconclusive about the framework **in both directions**. It is
not evidence that S.A.R.A.H. helps, and it is not evidence that it does not.

Reporting the one-point median gap as a result would be the same error as
claiming a win.

**One finding stands without the comparison.** Section B scored four
requirements the brief deliberately never states — timing-safe signature
comparison, a replay window from the timestamp header, idempotency keyed on
delivery identity, and signing over the raw body. These were pre-registered as
where a process should earn its cost. **Plain Claude Code scored full marks on
all four, in all three runs, unprompted.** The implicit-security-requirement gap
that process is often sold to close was already closed here, and any framework
claiming to fill it should check whether it is still open.

**Two measurements are reliable regardless of the rubric.** The framework arm
cost more ($46.28 against $29.19 median) and, more interestingly, its cost was
far less predictable: a 2.7× spread across three runs against the control's
1.06×. Nobody was looking for that, and at n=3 it is a lead rather than a
result.

**Why the instrument failed**, recorded so the next attempt does not repeat it:
the rubric optimised for objectivity and became easy; the task is abundant in
training data; the human gates were switched off because headless runs must
forbid the questions those gates ask; and blinding stripped the ADRs, specs and
plans, which is exactly the output a process framework produces.

**What is in the repository.** The brief, rubric, harness, packaging and judging
scripts — all committed before the first run — plus the eighteen raw scores with
the judges' per-item evidence, and an incident log recording every deviation.
That log includes two errors of the author's own: a blinding leak caught after
judging had already begun, and a defect wrongly attributed to an artefact that
turned out to be a bad test environment on the author's side.

**Not decided here:** whether v0.1 ships with an inconclusive study published as
such, or waits for a discriminating rubric and a re-run. That is the
maintainer's call.
