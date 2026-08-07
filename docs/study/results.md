# The evidence study — what it measured, and what it could not

**Run 2026-08-06 to 2026-08-07 against the method fixed in
[`method.md`](method.md) before any run started.**

Six builds of the same brief — three with S.A.R.A.H., three with plain Claude
Code — scored blind by three judges each against a rubric written in advance.
Eighteen scores. $280.76.

**The comparison did not work, and the reason is worth more than the comparison
would have been.**

## The instrument saturated

| Packet | Arm | Three judges | Median |
| --- | --- | --- | --- |
| A | control | 43, 44, 44 | 44 |
| C | control | 44, 44, 44 | 44 |
| E | control | 44, 44, 44 | 44 |
| B | S.A.R.A.H. | 43, 44, 43 | 43 |
| D | S.A.R.A.H. | 43, 43, 44 | 43 |
| F | S.A.R.A.H. | 44, 43, 44 | 44 |

Every artefact scored 43 or 44 out of 44. Judges agreed closely — no packet
spread wider than a point — so this is not noise hiding a signal. The rubric
simply had no room left to record a difference.

**A measurement where everything scores full marks measures nothing.** Whatever
separates these two ways of working, if anything does, lives below this
instrument's resolution. That makes the study inconclusive about S.A.R.A.H., in
both directions: it is not evidence that the framework helps, and it is not
evidence that it does not.

Reporting the 1-point median gap as a result would be the same error as claiming
a win. It is one point, on a saturated scale, at n=3.

## The one thing this study does establish

The rubric's section B scored four requirements the brief deliberately never
states, each implied by a situation it describes:

- signature comparison in constant time
- a replay window derived from the timestamp header
- idempotency keyed on delivery identity, not payload equality
- signing over the raw request body rather than re-serialised JSON

These were pre-registered as *"where a process should earn its cost, if it earns
it anywhere"* — the security-shaped requirements a careful process is supposed
to surface and a hurried one is supposed to miss.

**Every run in both arms scored full marks on all four.** Plain Claude Code,
given only the brief, produced timing-safe comparison, a replay window,
delivery-id idempotency and raw-body signing — three times out of three, with no
prompting toward any of them.

This is a solid finding, independent of the saturation problem, because it does
not depend on comparing the arms. It says something specific about building with
a current model: **the implicit-security-requirement gap that process is often
sold to close was already closed here.** Anyone designing a workflow framework —
this one included — should assume the baseline is stronger than it used to be
and find out where the real gaps are before claiming to fill them.

## Measurements that are reliable

These do not depend on the rubric.

| Run | Cost | Minutes |
| --- | --- | --- |
| control 1 | $27.90 | 41.2 |
| control 2 | $29.19 | 47.8 |
| control 3 | $29.48 | 50.1 |
| S.A.R.A.H. 1 | $46.28 | 82.5 |
| S.A.R.A.H. 2 | $72.07 | 57.3 |
| S.A.R.A.H. 3 | $26.57 | 52.6 |

**The framework costs more, and its cost is far less predictable.** The control
arm spanned $27.90 to $29.48 — a 1.06× spread across three runs. The framework
arm spanned $26.57 to $72.07, a **2.7× spread**, with its cheapest run below
every control run and its dearest at two and a half times the control median.

The extra spend is expected: eight phases with specialist subagents and an
adversarial review cost more than four open-ended turns. The *variance* was not
anticipated by anyone and is the most actionable thing in this table. At n=3 it
is an observation to chase, not a result.

## Why the instrument failed

Recorded so the next attempt does not repeat it.

**The rubric was built to be objective and became easy.** Every item was written
to be verifiable from a file and a line — which is right — but verifiable items
turned out to be items a competent model satisfies. Objectivity was optimised
for at the expense of discrimination.

**The task was well-trodden.** A webhook receiver with HMAC verification is
abundant in training data. The brief was chosen for its implicit requirements,
not for unfamiliarity, and a model with strong priors cleared it either way.

**The parts of S.A.R.A.H. that most plausibly matter were switched off.** Gates
1 and 2 close when a human approves; headless runs must forbid the questions
those gates ask. Both arms were equally affected, so the comparison stayed fair
— but the arm with human gates ran without them.

**Blinding removed the framework's most distinctive output.** Packets were
stripped to source, tests, README and packaging so judges could not identify the
arm. That deleted the ADRs, specs and plans — precisely the artefacts a process
framework produces. Whatever value they carry could not be scored, by
construction.

## What the next study needs

1. **A rubric that can be failed.** Items hard enough that a good artefact loses
   points. Calibrate against a deliberately mediocre artefact first: if that
   scores near the top, the rubric is not ready.
2. **A brief the model has not memorised** — an unusual domain, a genuine
   architectural fork, requirements that conflict and must be traded off.
3. **A separate axis for the process itself**, scored by someone allowed to see
   the ADRs and history: can a decision be reconstructed months later, is the
   history bisectable, can a stranger find why. Blinding cost this study that
   axis entirely.
4. **A path that exercises the human gates**, even at the cost of not being
   fully automated.
5. **Longer horizons.** One feature from scratch may be the wrong unit. Process
   frameworks claim to pay off across changes over time, and a single build
   cannot test that claim.

## Standing by the pre-registration

The method committed in advance to publishing whatever came out. What came out
is an inconclusive comparison and one clear finding about the baseline, and
that is what is published here — including the incident log, which records two
of the author's own errors: a blinding leak caught after judging had begun, and
a defect wrongly attributed to an artefact that was really a bad test
environment on the author's side.

The brief, rubric, harness, packaging and judging scripts in this directory were
committed before the first run. The [raw scores](scores/) are here with the
judges' evidence for every item. Anyone who thinks the conclusion is wrong has
everything needed to show it.
