# Framework v2 passed gate 4, on the sixth attempt

**Date:** 2026-08-09 · **Level:** 3 · **Phase:** 6-review

Five commits of framework v2 went into review unreviewed and came out after six
rounds. Every round but the last returned **changes required**: 7 findings, then
2, then 5, then 3, then 1, then clean. Both reviewers signed off on round six.

## What v2 actually delivers

The review gate probes with hostile input and rehearses a cold start instead of
only reading; it refuses a README nobody ran and a test seam that ships in
production. Phase-boundary ceremony is cut. Three artefacts an independent
analysis found genuinely valuable are kept: invariants stated with the
consequence no test would catch, superseded decisions with their reason, and the
deliberately-not-tested list — which now has a receiver, because the implement
phase promised to hand it to review and the review skill had never been told to
take it.

**The branch's main risk did not materialise.** The reviewers checked all four
prose changes line by line: they are purely additive, and the subtractive pass
cut nothing that was doing security work.

## What the review found in the instruments

Most findings were not in the framework at all. They were in the study scripts
the branch touched — and they mattered, because Phase F is about to spend roughly
$280 running them.

A rate-limited step exits 0 and reports the failure in-band, so the harness
recorded it as done and wrote `COMPLETE` over work that never happened. The
packager crashed mid-sanitise on a filename containing a space, after rewriting
some files and before the integrity check the same branch had added. Unvalidated
arguments composed paths that reached `rm -rf`. Symlinks, then hardlinks, then
FIFOs carried content into judging packets. Absolute paths named the maintainer's
machine in a repository that mirrors publicly on push.

## The confound, which no instrument caught

Found while repricing the rubric, not by any check: the harness gave the control
`--setting-sources project` and the framework arm the default, which also loads
user settings. One arm ran with the maintainer's own `CLAUDE.md` and the other
did not. **Phase E did not compare framework against no framework — it compared
framework plus personal context against a bare CLI.**

The symptom had been visible in the artefacts since the day they were built: two
of three framework-arm builds are written in Portuguese, none of the control's,
because the language rule lives in a file only one arm could see. Eighteen blind
scores, three judges per packet, and an author's spot check all missed it.

Phase E was already inconclusive because the rubric saturated. This is a second,
independent reason, and the worse of the two: a saturated instrument measures
nothing, a confounded one measures the wrong thing while looking like it worked.
Both arms now load identical sources, the framework reaches its arm through
`--plugin-dir` alone, and both are told to write in English in the same words.

## The lesson worth keeping

Four consecutive rounds found the same shape in the same file: **a check that
skipped exactly what it existed to catch.** Dotted capitals only. A warning that
could not refuse. Filenames `sed` never sees. Binaries and UTF-16 that `grep`
skips.

The fixes that never came back are the ones written by exclusion — refuse
anything that is not a regular file, refuse anything not readable as text, stop
preserving attributes nobody inspects. The ones that kept failing enumerated what
to fear. A fifth round then caught the opposite failure: fixing the fourth had
left two rewrite expressions that disagreed, shipping a file whose own prose
pointed at a name that did not exist. That fix was not another check either — the
expression is defined once now, so divergence cannot happen.

## Also delivered

`rubric-v2.md`'s evidence describes the instrument that exists: S5-S8 scored
against the six artefacts, range 22-35 of 56, spread 13 points against v1's 1.
The arm-comparison table carries the confound warning and is explicitly evidence
about the rubric, never about the framework. The CI guard now looks for
home-directory paths, which is what let three scripts leak past it, and has no
exclusions left.

## Accepted and not fixed

Unicode homoglyphs, zero-width sequences and Markdown-reassembled substrings
evade both blinding gates; POSIX ACLs survive the packet copy. The threat model
here is a coding agent accidentally deblinding its own output, not an adversary.
Worth a line in any publication write-up if packets ever go to judges outside the
maintainer's direct control.
