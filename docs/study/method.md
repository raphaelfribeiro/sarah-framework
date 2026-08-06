# The evidence study — method

**Pre-registered on 2026-08-06, before any run was executed.**

This document, [the brief](brief.md), [the rubric](rubric.md) and
[the harness](run-arm.sh) were written and committed *before* the first run
started. That ordering is the point. A study whose metrics are chosen after the
data is seen measures the author's preferences, and everything in this
repository would be worth less if this one were.

If the results contradict what S.A.R.A.H. claims, they get published as they
came out. That commitment is made here, in advance, where it costs something.

## The question

Does using S.A.R.A.H. produce a materially better result than using Claude Code
well without it, on the same task?

Not *"is the framework nice to use"*, and not *"does the pipeline complete"* —
that was already established by the instrumented runs described in
[the Level 3 walkthrough](../walkthrough-level-3.md). Those runs had no control
arm, so they cannot separate what the framework contributed from what the model
would have done anyway. This study exists to do exactly that.

## Design

**Two arms, three runs each.** Three with the framework, three without, same
brief, same harness, same model, same tools.

`n=3` is the smallest number that shows variation rather than a single point.
The model is not deterministic; one run per arm would measure luck. It is also
small enough to be honest about: three runs cannot support a confident effect
size, and no confident effect size will be claimed from them.

**The control arm is Claude Code used well, not a straw man.** It receives the
identical brief and the identical toolset. It gets four open-ended turns against
the framework arm's eight phase-scoped ones — deliberately generous per turn,
because each control turn says *keep going until it is done* rather than being
cut off at a phase boundary. One single turn would measure context exhaustion
instead of process. Eight phase-shaped turns would hand the control the
framework's structure without the framework, which is the same fraud in the
opposite direction.

**Arm isolation is verified, not assumed.** The plugin is installed at user
scope, so it would otherwise load in every directory. The control runs with
`--setting-sources project`, which drops user-scope settings. Before either arm
does any work, the harness asks the model to list the skills available to it and
**refuses to proceed** if the answer is wrong — no framework skills visible in
the control, framework skills visible in the treatment. A control arm silently
running with the framework loaded would invalidate the study while looking
exactly like a successful run.

## The brief

[`brief.md`](brief.md), given verbatim and identically to both arms.

It is deliberately underspecified, because real requests are, and how a process
handles ambiguity is part of what is being measured. It names no part of either
arm's process: no mention of tests, security, architecture, or review. Naming
any of those would tell both arms what they are being scored on, and the study
would measure instruction-following instead of process.

It carries four requirements it never states — timing-safe signature comparison,
a replay window derived from the timestamp header, idempotency across duplicate
deliveries, and a deliberate synchronous-versus-queued decision. Each is implied
by a situation the brief describes. Section B of the rubric scores exactly
these, and it is where a process should earn its cost, if it earns it anywhere.

## Scoring

[`rubric.md`](rubric.md), also fixed in advance. 44 points across stated
requirements, unstated-but-implied requirements, failure behaviour, tests, and
architecture and documentation.

**Judging is blind.** Judges receive one artefact at a time. They are not told
which arm produced it, and not told that two arms exist. They score by reading
and running the code, never by reading run logs — logs reveal the arm
immediately.

**Blinding requires stripping the process artefacts, and that has a cost worth
stating.** A framework-arm project contains `sarah/state.md`, `ARCHI.md` and a
changelog directory; a control-arm project does not. Any judge seeing those
knows the arm at a glance, and the blinding becomes theatre. So each artefact is
packaged for judging as the software only — source, tests, README, packaging and
configuration — with framework state files and process documents removed, and
git history removed along with them.

This deliberately discards something real. If the framework arm produces better
process documentation, that advantage does not appear in the rubric score. The
trade is accepted because a score from an unblinded judge is worth less than a
narrower score from a blind one, and because documentation volume is already
recorded as a separate measurement. It is recorded here, in advance, rather than
discovered in the results.

**Evidence or zero.** Every score above 0 must cite a file and line, or a
command and its output. An item a judge believes is probably fine but did not
check scores 0, not 1. The rubric measures artefacts, not intentions.

**Three judges per packet, reconciled by median.** One judge is a single draw
from a non-deterministic scorer. Three make a lone outlier visible instead of
decisive, and the spread between them is itself worth reporting: judges who
disagree wildly about the same artefact are evidence that the rubric is loose,
and that belongs in the writeup rather than hidden behind an average.

**Judges run without the framework**, for the same reason the control arm does.
A judge with the plugin loaded could invoke the framework's own reviewer and put
S.A.R.A.H. inside its own evaluation. It also keeps every judge identical
regardless of which arm produced the packet it is scoring.

Cost, wall-clock, source and test volume, and commit structure are recorded and
reported as measurements, never as rubric points. They are inputs and prices,
not qualities of the result. Any defect a judge finds that the rubric did not
anticipate is recorded verbatim, because an unanticipated finding says more than
a checklist item.

## What this study cannot establish

Stated in advance so that it cannot be quietly dropped later:

- **The human gates are not exercised.** Driving the CLI headlessly requires
  telling it not to ask questions, which is precisely what gates 1 and 2 are
  made of. Both arms are equally affected, so the comparison stays fair, but no
  conclusion about the approval protocol can come from this study.
- **One brief.** Any effect found is an effect on a webhook receiver in Python.
  Whether it generalises to other kinds of work is not addressed.
- **Three runs per arm** cannot support a confident effect size, only a
  direction and a spread.
- **The author is not neutral.** The study is designed and run by the
  framework's author. Blind scoring and a pre-registered rubric are mitigations,
  not cures. The raw artefacts and logs are what make the finding checkable, and
  anyone who wants to redo the scoring should be able to.

## Reproducing it

```
sh docs/study/run-arm.sh sarah 1
sh docs/study/run-arm.sh plain 1
```

One run per invocation, by design. Six runs in one script would be cut by the
session rate limit and lose everything after the cut; each run here records its
own completion and resumes from the last finished step.
