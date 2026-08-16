# Phase F — the comparison that finally measured something, and still has no verdict

**Run 2026-08-14 to 2026-08-15, against the method in [`method.md`](method.md)
and the instrument in [`rubric-v2.md`](rubric-v2.md), both fixed before the
first build.**

Six builds of one brief — three with S.A.R.A.H., three with plain Claude Code —
then three changes each in **cold sessions**, no `--continue` anywhere, so the
session receiving change 2 never wrote change 1 and can only read what the
repository carries. Eighteen blind scores, three judges per artefact. **US$
308.63.**

[Phase E](results.md) failed twice: a rubric that saturated at 43-44 out of 44,
and two arms that loaded different setting sources. Both were fixed here. What
follows is what the fixed instruments returned.

## The scores

| Packet | Arm | Three judges | Median | of 48 |
| --- | --- | --- | --- | --- |
| D | S.A.R.A.H. | 21, 22, 17 | 21 | 44% |
| E | S.A.R.A.H. | 24, 23, 24 | 24 | 50% |
| A | S.A.R.A.H. | 18, 17, 16 | 17 | 35% |
| B | control | 20, 19, 20 | 20 | 42% |
| C | control | 22, 17, 16 | 17 | 35% |
| F | control | 22, 23, 20 | 22 | 46% |

**S.A.R.A.H. 20.7 · control 19.7.** One point out of 48.

**The instrument works now.** Scores spread from 35% to 50%, against 43-44 out
of 44 for every artefact in Phase E. The rubric can be failed, which is the
whole reason it was rewritten.

**And the difference between the arms is smaller than the difference within
them.** S.A.R.A.H. spans 17-24, the control 17-22, and the two worst artefacts
in the study are tied at 17 — one from each arm. With three pairs, one point
supports no claim in either direction.

## Cost

| | Median build | Spread across runs |
| --- | --- | --- |
| S.A.R.A.H. | **$34.13** | 1.48× |
| control | $28.30 | 1.55× |

**21% more expensive.** Unlike Phase E, the variance is now comparable between
arms — the 2.7× instability the framework showed there does not reappear.

## Where the points actually went

| Section | S.A.R.A.H. | control |
| --- | --- | --- |
| Security under change and configuration | **2.6** | 1.0 |
| Restraint — no unrequested surface | **3.2** | 2.0 |
| Hostile input | **2.8** | 2.6 |
| Operator-facing failure | **1.7** | 1.4 |
| Resource behaviour | 2.6 | **3.6** |
| Documentation that executes | 3.9 | **4.9** |
| Maintainability over time | 3.6 | **4.4** |

The framework gains where the brief says nothing — security and scope — and
loses where the work is direct. That is what a checklist is supposed to do, and
it is a pattern in three pairs, not a finding. It would survive being called a
hypothesis and nothing stronger.

## The blinding did not hold

Asked **after** scoring, in a fresh context, whether each project looked like it
was built under a structured process:

| Packet | Arm | Guess | Confidence |
| --- | --- | --- | --- |
| D | S.A.R.A.H. | yes | 94% |
| E | S.A.R.A.H. | yes | 92% |
| A | S.A.R.A.H. | yes | 87% |
| B | control | no | 72% |
| F | control | no | 65% |
| C | control | yes (wrong) | 68% |

Five of six correct, and all three framework artefacts identified with high
confidence. The evidence they cited was the **scar left by blinding them**: the
packager strips `sarah/`, `docs/` and `ARCHI.md`, and rewrites the references
those documents left behind into a neutral phrase. Eighteen such lines survive
across the three framework packets and zero across the controls.

**This is a design problem, not a bug.** A framework whose value is producing
process documents that the code then cites cannot be hidden by rewriting text.
Sanitising harder would not fix it; it would only make the scar stranger, and a
reader already reported the neutral phrasing as though it were poor writing —
which means the instrument was also **penalising** the treatment arm for having
been blinded.

So the one-point difference above is not a blind measurement, and should not be
reported as one.

## What this study establishes

- **The rubric discriminates.** 35-50%, and a calibration floor at 2-4/48.
- **The framework fires on its own in cold sessions.** Framework invocations per
  run, steps 1-3: 2/2/2, 2/2/2, 1/1/1. Step 0 counts zero by design — it carries
  an explicit `/sarah-init`, and a slash command is expanded before it can
  become a tool call. Retention across sessions is not a claim here; it is a
  count.
- **The framework costs about 21% more.**
- **It does not produce measurably better software on a well-specified brief.**

## What it does not establish

Whether the framework helps at all. Three attempts, three times without a
verdict — a saturated instrument, then confounded arms, now a blinding that
cannot survive the thing being tested.

The honest reading is that this design has reached its limit. A fourth attempt
would need either both arms producing process documents, or a rubric scored only
on material that cannot reference them.

## Instrument failures found during this phase

Five, all of one family, all recorded in [`incidents.md`](incidents.md): a probe
that read a session limit as a verdict and killed a $12 run; an orchestrator
whose documented recovery step would have deleted three finished runs; a counter
that crashed and whose silence was published as "the framework was invoked zero
times"; a judging loop that wrote `JUDGING COMPLETE` over five missing scores;
and a rubric that declared a 56-point total it never had.

**Every one of them could report success or a number, and none could report that
it had not measured.** Four produced, or nearly produced, a plausible and false
result. The counter's would have been the study's headline.

That is the most transferable thing here, and it is not about S.A.R.A.H. at all:
**an instrument with two outcomes will eventually assign one of them to its own
failure.**
