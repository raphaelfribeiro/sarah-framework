# Scoring rubric v2

Replacement for [`rubric.md`](rubric.md), which saturated: six artefacts scored
43-44 out of 44, so it could not distinguish two very different development
processes.

**The design brief for this rubric is the failure of the last one.** v1 was
built to be objective and became easy — every item was verifiable from a file
and a line, and verifiable items turned out to be items a competent model
satisfies. This version keeps the objectivity and buys back the discrimination
from a source v1 threw away: the **96 defects judges found and recorded in
`unanticipated_findings`** while scoring every rubric item full marks.

Those 96 findings are the evidence that the artefacts differ. The instrument
was blind to them. Every item below is derived from a class of defect that was
actually found in these six artefacts, by a judge, with a reproduction.

## How to score

Each item: **2** fully met, **1** partially met, **0** absent or wrong. Every
score above 0 must cite a file and line, or a command that was run and its
output. A claim with no evidence scores 0.

Three rules that v1 lacked, and whose absence is why it saturated:

1. **A 2 requires demonstration, not presence.** For most items the difference
   between 1 and 2 is whether the artefact *proves* the property — a test, a
   startup check, a documented number — or merely happens to have it. Code that
   is correct by accident scores 1.
2. **A claim the artefact makes and does not keep scores 0, not 1.** A docstring
   asserting exclusivity that the code does not provide is worse than silence,
   because it is load-bearing for a reader. v1 had no way to record this; it was
   the single most common finding class in the 96.
3. **Do not grade on effort.** More code, more commands and more configuration
   are costs. Section P scores them as costs.

**Total: 48 points across 24 items** — H 3, R 3, S 4, X 3, P 4, M 4, O 3, every
item worth 2.

This line read "56 points across 28 items" until 2026-08-15, and no such
instrument was ever written: the sections below have always summed to 48. The
paragraph under it describes a revision that added four scored security
properties, and S1-S4 are those items, so the arithmetic was carried from a
draft rather than counted from the document. Scoring against a total the
instrument does not have would have skewed every percentage in the report.
Counted, not remembered.

Revised 2026-08-07 after calibration against a deliberately mediocre artefact,
which scored 8/48 on the original draft — inside the 8-12 target band, so the
instrument discriminates. The calibration also exposed four faults, all fixed
above: the admission gate would have refused to score the calibration floor at
all; four core security properties were gated rather than scored and therefore
worth zero points; four items awarded full marks for *absence of surface* rather
than quality, which a do-nothing artefact could max; and one false README claim
could fire in three sections at once. On the revised instrument the same
artefact lands at **2-4** out of the instrument's 48. The figures in this
paragraph are the calibration as it was recorded, against a document that
misstated its own total; the floor it established stands, the denominator it
was written with did not exist.

## What changed from v1, and why

| v1 | Outcome | v2 |
| --- | --- | --- |
| A (stated requirements, 12 pts) | 6/6 items full marks, all six artefacts | **Removed.** A requirement every artefact meets measures nothing. Treat A1-A6 as a pass/fail admission gate: if an artefact fails one, it is not scoreable. |
| B (unstated but implied, 10 pts) | Full marks in both arms, 3/3 runs | **Removed as scored, kept as a gate.** The results write-up already establishes this finding: timing-safe comparison, replay window, delivery-id idempotency and raw-body signing were all produced by both arms unprompted. That gap is closed; scoring it again buys nothing. |
| C (failure behaviour, 8 pts) | Near-full marks | **Replaced by H and O**, which ask about failure the artefact did not anticipate rather than failure it obviously would. |
| D (tests, 8 pts) | Full marks | **Folded into the 2-descriptors everywhere.** "Is there a test" saturates. "Is there a test for the hostile case" does not. |
| E (architecture and docs, 6 pts) | Full marks | **Replaced by X and M**, which execute the documentation and reconstruct a decision instead of asking whether documentation exists. |
| — | — | **P (restraint) is new.** v1 could not distinguish a 1,320-line receiver with 2 subcommands from a 3,865-line receiver with 10. It scored both 44. |

---

## Admission gate (not scored)

Verify before scoring. An artefact failing any of these is reported as
**not scoreable** rather than given a low number, because the rest of the
instrument assumes a working receiver.

- [ ] Installs, and the test suite runs to completion on a clean checkout.
- [ ] Accepts an HTTP POST of a signed JSON payload on a per-sender path and
      returns 2xx.
- [ ] Rejects an invalid signature.
- [ ] Persists the event somewhere durable, behind a swappable handler seam.

All six current artefacts pass this gate. That is the finding v1 bought, and it
does not need buying twice.

**The gate applies to artefacts under study, never to a calibration floor.** A
deliberately bad artefact exists to prove the instrument discriminates, and
declaring it "not scoreable" defeats the exercise. Score the floor against every
item and report the number.

### The four core security properties are scored, not gated

Timing-safe comparison, signature over the raw body, an enforced replay window,
and dedup keyed on delivery identity were originally admission criteria. That
was wrong: gated properties are worth zero points, so an artefact could regress
on all four and its score would not move.

Score each, 2 points apiece, **on demonstration rather than presence**:

| | 0 | 1 | 2 |
| --- | --- | --- | --- |
| **S5** Timing-safe comparison | `==` or `!=` on the digest | constant-time function used, nothing prevents the next change reverting it | used, **and** a test or review check would fail if it were replaced |
| **S6** Signature covers the raw body | signature computed over re-serialised or parsed input | raw body signed, undocumented | raw body signed **and** a test proves re-serialisation breaks verification |
| **S7** Replay window enforced | timestamp parsed and never compared, or absent | compared, tolerance hardcoded and unstated | compared, tolerance stated where an operator reads it, **and** a test proves a stale delivery is rejected |
| **S8** Dedup identifies a delivery | keyed on payload content, or absent | keyed on a delivery identifier without sender scoping | keyed on delivery identity **scoped per sender**, with a test proving two senders' identical payloads both run |

S8's floor matters: content-keyed dedup silently drops a genuine second delivery
with identical content, and lets one sender suppress another's. That is worse
than no dedup, and it must not score above 0.

---

## H. Hostile input on the unauthenticated path (6)

*Derived from: the OverflowError giving an unauthenticated 500 (packet B); the
RecursionError poison-pill loop (packet A); the `nan` timestamp that silently
disabled the replay window (packet C); log forging via PATH_INFO (packet E).*

### H1 — Hostile numeric values in the timestamp header

The timestamp is parsed **before** the MAC is checked, in every one of these
artefacts, because it is an input to the signed payload. That makes it
anonymously reachable. Probe with: a 400-digit integer, `nan`, `NaN`, `inf`,
`-inf`, `1e400`, the empty string, and a value 10^15 seconds in the future.

- **0** — Any value crashes the process or returns 5xx, **or** any value passes
  the freshness check that should not (NaN compares False against everything).
- **1** — All probe values are rejected cleanly, but no test covers them.
- **2** — All probe values are rejected cleanly **and** a test names the hostile
  cases explicitly.

### H2 — No anonymous request can force a 5xx or an unbounded commitment

Before any secret is held: oversized bodies, absent/duplicated/oversized
headers, `Content-Length` mismatches and lies, a declared-but-never-sent body,
percent-encoded control characters in the path.

- **0** — A 5xx, a hang, or an unbounded read is reproducible without a secret.
- **1** — No 5xx and no hang, but a resource commitment is unbounded or
  undocumented (full body buffered before auth with no read timeout; a
  pre-auth status code that acts as an oracle).
- **2** — Every commitment made before authentication is bounded, and the bound
  is stated where an operator will find it.

### H3 — Attacker-controlled strings are neutralised before logs and errors

- **0** — Log forging is reproducible: a crafted path, header or sender id
  injects a line indistinguishable from a genuine one.
- **1** — Most attacker strings are escaped or `repr`'d; at least one path
  interpolates raw.
- **2** — Structured logging by construction, or every interpolation escaped,
  with no raw attacker string reaching a log line.

---

## R. Resource behaviour under the workload the brief describes (6)

*The brief says senders "retry aggressively" and "send the same delivery more
than once". That is a stated load profile, and it is the one under which these
artefacts leak. Derived from: the unbounded `suppressions` table surviving purge
(packet B); no retention of any kind (packets D and F); the ~2-file-descriptor
leak per request (packet E); concurrent double-dispatch on lease expiry (packets
C, E, F).*

### R1 — Every table that grows under retry has a retention path

Enumerate `CREATE TABLE`. Enumerate `DELETE FROM`. Compare the sets.

- **0** — No deletion path anywhere; the store grows without bound, and raw
  payloads are retained indefinitely.
- **1** — The primary table has a retention path; a secondary table that also
  grows per-retry does not, **or** retention exists but nothing exercises it.
- **2** — Every growing table is covered, and a test or a documented number
  shows the bound holding.

### R2 — Per-request resources are released

Connections, file handles, threads, cache entries. Probe by sending a few
hundred requests and watching `/proc/<pid>/fd`.

- **0** — A reproducible unbounded leak.
- **1** — Released on the normal path; an edge path (worker disabled, shutdown,
  error) leaks, or a cache is unbounded.
- **2** — Bounded and released on every path, demonstrated.

### R3 — The handler is never run twice concurrently for one delivery, and the docs say what is actually true

This is the brief's central requirement — "we can't have duplicates causing
duplicate work downstream" — displaced from ingest to processing, where every
artefact is weaker than it claims.

- **0** — Concurrent double-execution is reproducible, **or** a replay/requeue
  command re-invokes the handler on an already-completed delivery with no guard,
  **or** the code states an exclusivity guarantee it does not provide.
- **1** — At-least-once with concurrent overlap possible, disclosed honestly as
  at-least-once, with handlers told to be idempotent.
- **2** — Overlap is impossible (lease renewal, or a claim checked at
  completion), and a test drives a handler past the lease to prove it.

---

## S. Security properties under change and configuration (8)

*The old B section asked whether four security properties were present on day
one. They were, everywhere. This section asks the harder question: do they
survive a configuration choice, an added feature, or an operator's later
decision? Derived from: dedup keyed on an UNSIGNED header allowing replay
amplification (packets A, C, D — all reproduced live, one signed request to N
handler runs); SHA-1 as a selectable digest (packet A); the unauthenticated
stats endpoint (packet C); a `custom` scheme whose timestamp header is outside
the MAC (packet A); a ledger that is both unbounded and load-bearing for replay
defence, so pruning reopens the hole (packet F).*

### S1 — Every input used for a security or idempotency decision is MAC-covered, or its untrusted status is stated with its consequence

The dedup key is a security decision: it decides whether work runs. In five of
six current artefacts it is taken from a header the signature does not cover.

- **0** — An unsigned input drives a security or idempotency decision and
  nothing in the artefact says so.
- **1** — The input is unsigned, but the artefact names the gap **and its
  consequence** where an operator configuring a sender will read it.
- **2** — Every such input is inside the MAC, **or** a startup check refuses the
  configuration that would leave one outside.

### S2 — No weak or deprecated primitive is reachable by configuration

- **0** — A broken or deprecated primitive (MD5, SHA-1) is selectable.
- **1** — The digest is configurable with a safe default and no explicit
  allowlist bounding it; **or** the digest is not configurable at all, so
  nothing is reachable and nothing is demonstrated.
- **2** — Strong primitives only, **enforced by a mechanism you can run**: an
  unknown or weak scheme name is rejected at config load with a named error,
  proven by a test or a startup check.

An artefact with no configuration caps at 1. Having no knob is not the same as
guarding one, and the 2 must be earned by a demonstration, never by absence.

### S3 — No unauthenticated surface beyond the sender paths exposes operational data

- **0** — An unauthenticated endpoint returns counts, volumes, timings, backlog
  or configuration **by default**.
- **1** — Extra surface exists and is inert or authenticated, but it was not
  asked for and is mounted by default (framework-supplied `/docs`,
  `/openapi.json`).
- **2** — Only the sender paths and a detail-free liveness endpoint, with a test
  asserting the endpoint leaks nothing.

### S4 — A configuration that silently disables a security property is refused at startup

- **0** — A configuration that disables replay protection, rejects all traffic,
  or makes a sender unreachable loads without error and passes any preflight
  check the artefact provides.
- **1** — Some cross-field validation exists; at least one such configuration
  still loads clean, or fails with a raw traceback rather than an operator
  message.
- **2** — Every configuration that would void a security property is refused at
  load with a message naming the file, the field and the consequence.

---

## X. Documentation that executes (6)

*Derived from: a README quickstart returning 400 instead of 202 (packet B); a
documented `uvicorn --factory` invocation that cannot work (packet F); no
example config shipped, forcing the judge to hand-transcribe TOML (packet D);
`--port` advice that breaks the very next command (packet E, hit independently
by all three judges); a `check` subcommand whose documented contract says it
starts nothing while it creates a database (packet D).*

**Score this by running the commands, in a clean directory, in the order
written, pasting nothing that is not on the page.**

### X1 — The primary quickstart runs verbatim to a 2xx

- **0** — The documented sequence does not reach a successful delivery. A
  documented `curl` that returns 400, or a missing file the reader must author.
- **1** — Reaches a 2xx only after an undocumented step the reader must infer.
- **2** — Runs verbatim, cold, to the documented response.

### X2 — Every alternative invocation the docs offer works

The fallback branch — "if that port is taken", "or run it under a process
manager" — is where readers land when the happy path fails, and it is broken in
four of six current artefacts.

- **0** — A documented alternative fails, or contradicts the tool's own help.
- **1** — Alternatives work, but at least one is undocumented as a prerequisite
  of another.
- **2** — Every documented invocation works as written.

### X3 — A third party could implement a sender from the docs alone

The receiver is useless if the sending team cannot sign correctly. State the
exact bytes that are MAC'd.

- **0** — The canonical signed message is not stated outside the source; a
  sender team would get an opaque 401 and no way forward.
- **1** — Stated, but a detail (prefix, encoding, length check, header casing)
  is only discoverable in code.
- **2** — Canonical message, encoding, prefix, headers and the replay window are
  all documented, with a worked example a reader can reproduce.

---

## P. Restraint: unrequested surface is a defect (8)

*The brief asks for a webhook receiver that is installable, runnable and tested.
It does not ask for a secret generator, a config scaffolder, a delivery browser,
a statistics endpoint or a pluggable digest engine. Three artefacts shipped
between 7 and 12 CLI subcommands and 2,291-3,865 lines of source; three shipped
2 subcommands and 1,320-1,832 lines. v1 scored all six identically.*

**The test for whether work is necessary rather than creep:** can the judge name
the sentence in the brief, or the failure mode in the artefact's own design,
that requires it? Retention exists because the store grows. A recovery sweep
exists because a process can die mid-dispatch. A secret generator exists because
someone enjoyed writing it.

### P1 — Public CLI surface is proportionate

Count top-level subcommands, including nested action groups.

- **0** — 7 or more, **or** any subcommand that neither the brief nor a named
  failure mode requires, **or** no way at all to inspect or recover a delivery.
- **1** — 4 to 6, each with a stated justification.
- **2** — 3 or fewer, each traceable to the brief or to running the service,
  **and** an operator can inspect and recover a delivery.

**Restraint is not the same as not having got there.** An artefact that ships no
operational surface scores 0 here, not 2 — it has not exercised judgement, it
has left the job unfinished, and item O3 will show the consequence.

### P2 — Configuration surface is proportionate

Count distinct settable keys in the shipped example configuration.

- **0** — More than 35, **or** fewer than 3 — an artefact with nothing to
  configure has not been made operable, and secrets are almost certainly
  hardcoded.
- **1** — 21 to 35.
- **2** — 3 to 20.

### P3 — No capability ships that the brief did not ask for and the design does not require

Judge names each capability and the sentence that requires it.

- **0** — Two or more unrequested capabilities, or one that adds attack surface
  (a selectable weak digest, a network-exposed endpoint, a template engine for
  signature schemes).
- **1** — One unrequested capability, contained and justified in prose.
- **2** — Everything present is traceable to the brief or to a failure the
  design must handle.

### P4 — No test-only or dead surface in production code

- **0** — Production code carries a mutable global installed for a test and
  invoked on the request path, **or** a shipped parameter that is accepted and
  never used in a way that misleads (a `now` argument implying a recorded
  timestamp that is never recorded).
- **1** — Minor dead code — an unused import, a discarded return, a comment
  asserting a reason that is wrong.
- **2** — No dead or test-only surface in the installed package.

---

## M. Maintainability over time (8)

*Requirement 5: assessable from the artefact alone. This is the axis v1's
blinding deleted by construction, and it is the axis a process framework most
plausibly affects. Judges for this section must receive the artefact **with its
git history and design documents intact** — see "Judging protocol" below.*

### M1 — History is bisectable

- **0** — No history, or a single commit containing the entire project.
- **1** — A handful of commits, but one contains the majority of the tree, so
  `git bisect` lands inside it and stops being useful.
- **2** — Five or more commits, each a coherent step, none containing more than
  roughly half the source, and each message stating what changed and why.

### M2 — A specific past decision can be reconstructed

The judge picks **one non-obvious decision without telling anyone in advance** —
e.g. why the dedup key is derived the way it is, why storage is synchronous, why
the response is sent before the handler runs — and spends ten minutes trying to
find the reasoning.

- **0** — Not reconstructible. The what is visible; the why is nowhere.
- **1** — Reconstructible by inference from code and commit messages, without
  the alternatives or the trade-off being recorded.
- **2** — A named record states the decision, the alternatives considered, and
  what would have to change to revisit it.

### M3 — Invariants are stated with their consequences

An invariant without a consequence is a comment. "Must exceed the slowest
handler run" is an invariant; "must exceed the slowest handler run, or two
workers run the same delivery concurrently" is one a maintainer can act on.

- **0** — No invariants stated, **or** an invariant is asserted that the code
  violates.
- **1** — Invariants stated, consequences mostly absent.
- **2** — The load-bearing invariants are stated at the point of use with what
  breaks if they are violated, and cross-field ones are enforced at startup.

### M4 — Claims the artefact makes about itself are verifiable and true

Check every checkable number and guarantee: test counts, durability claims,
exclusivity guarantees, ordering guarantees, "nothing is interpreted before the
signature verifies".

**Score each false claim once, in one section only.** A README written from
intent rather than from code can otherwise fire on M3, M4 and a behavioural item
at the same time, costing six points for one mistake and letting a rewrite move
the total without changing behaviour. Assign each false claim to the section
that best describes it — behavioural items when the behaviour is wrong, M3 when
an invariant is contradicted, M4 when the claim is merely unverifiable — and
note the reassignment in the evidence.

- **0** — A load-bearing claim is false — a durability promise the storage
  configuration does not provide, an exclusivity guarantee reproducibly
  violated, a contract the command's own behaviour contradicts.
- **1** — Claims are true but drift — a stale test count, a guarantee stated
  slightly stronger than the code delivers.
- **2** — Every claim checked was exact.

---

## O. Operator-facing failure (6)

*Derived from: a sender silently shadowed by a health path (packet A); a
trailing-slash path unreachable at its own address (packet A); a secret encoding
that rejects 100% of traffic while `check` exits 0 (packet C); a path without a
leading slash logged as "sender.mounted" and 404ing (packet F); `replay --status
failled` exiting green (packet B); a dead-lettered delivery permanently
unrecoverable while the sender is told 200 duplicate (packet D).*

### O1 — A misconfiguration cannot look healthy

- **0** — A configuration that drops 100% of a sender's traffic passes
  validation and is reported as mounted and working.
- **1** — Caught at runtime with a diagnosable log line, but not at preflight.
- **2** — Refused at preflight, naming the field and the consequence; and
  preflight has no side effects on the filesystem or database.

### O2 — Re-entrant and destructive operations are guarded

- **0** — A replay or requeue command re-invokes the handler on an already
  completed delivery with no status guard, no confirmation and exit code 0;
  **or no such operation exists**, so a stuck delivery cannot be recovered at
  all and the guarantee is untestable.
- **1** — Guarded by a status check, but a typo in an argument produces a
  green no-op indistinguishable from success.
- **2** — Guarded, with unknown arguments refused and a dry-run that differs
  meaningfully from execution.

The absent case scores 0, never 2. "Nothing unguarded" is trivially true of an
artefact that does nothing, and reading it as full marks would reward the gap.

### O3 — A failure in the storage or handler path cannot silently lose a delivery

- **0** — A delivery can be dropped with no durable record and no signal — a
  parse failure before persistence, an unguarded storage error after the
  response, or a dead-lettered delivery that answers 200 duplicate forever.
- **1** — Every delivery is durably recorded; recovery requires an operator to
  notice a count nothing alerts on.
- **2** — Every terminal state is durable, reachable by a documented command,
  and surfaced without the operator having to know to look.

---

## Predicted scores for the six current artefacts

Predictions made by reading the artefacts and the 18 judge score files, with
file and line for each. Packet labels are v1's blind labels; run identities are
shown because this table is calibration, not scoring.

**Who scored this, and the bias that carries.** Sections H through O were
predicted 2026-08-07; S5-S8 were scored 2026-08-09, when moving those four items
from gate to score left the totals here describing a 48-point instrument that no
longer existed. Both passes were done by the author, with the arm visible. That
is acceptable for calibration — the question is whether the *instrument* spreads
artefacts out, and a biased scorer who produces a spread has still shown the
scale has room — and it is not acceptable for scoring. Phase F's artefacts go to
blind judges who never see an arm label, exactly as Phase E's did.

### Section totals

| Run | Packet | H (6) | R (6) | S (16) | X (6) | P (8) | M (8) | O (6) | **Total (56)** | **%** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| plain-1 | E | 2 | 2 | 12 | 3 | 2 | 2 | 3 | **26** | 46% |
| plain-2 | A | 4 | 4 | 8 | 5 | 2 | 3 | 1 | **27** | 48% |
| plain-3 | C | 2 | 3 | 7 | 4 | 1 | 3 | 2 | **22** | 39% |
| sarah-1 | B | 2 | 2 | 12 | 2 | 5 | 6 | 2 | **31** | 55% |
| sarah-2 | F | 4 | 1 | 13 | 2 | 5 | 8 | 2 | **35** | 63% |
| sarah-3 | D | 4 | 2 | 11 | 1 | 6 | 5 | 1 | **30** | 54% |

Section S is 16 points: S1-S4 (security under change, 8) plus S5-S8 (the four
core properties, 8), which were moved from gate to score after the calibration
run. The S column above is the sum; S5-S8 break down as:

| Run | S5 timing-safe | S6 raw body | S7 replay window | S8 dedup identity | **S5-S8** |
| --- | --- | --- | --- | --- | --- |
| plain-1 | 1 | 2 | 2 | 2 | **7** |
| plain-2 | 1 | 1 | 2 | 2 | **6** |
| plain-3 | 1 | 1 | 2 | 2 | **6** |
| sarah-1 | 2 | 2 | 2 | 1 | **7** |
| sarah-2 | 2 | 1 | 2 | 2 | **7** |
| sarah-3 | 2 | 2 | 1 | 1 | **6** |

**S5 is the item that best justifies scoring these rather than gating them.**
Every artefact uses `hmac.compare_digest`, so presence would have given all six
full marks. Demonstration separates them: no test suite in any of the six would
fail if the call were replaced by `==` — timing is not unit-testable — so the
score turns on whether a *review check* exists. Three artefacts have one and
three do not. `sarah-1`'s plan names `T-U-06 a comparação é hmac.compare_digest`
with "comparison by `==`" listed as the risk it guards; `sarah-2` and `sarah-3`
state it as an architectural invariant. The other three mention the function in
a README, which records the choice without protecting it.

S8 costs `sarah-1` and `sarah-3` a point each: both scope the key per sender in
the schema, and neither has a test proving two senders' identical payloads both
run, which is the property that breaks silently.

### Predicted spread

| | v1 (actual) | v2 (predicted) |
| --- | --- | --- |
| Scale | 44 | 56 |
| Range | 43-44 | 22-35 |
| Spread | 1 point (**2.3%** of scale) | 13 points (**23%** of scale) |
| Mean | 43.5 (**99%**) | 28.5 (**51%**) |
| Highest scorer | 100% of scale | **63%** of scale |
| Items at ceiling for all six | 20 of 22 | **0 of 28** |

**No artefact reaches two thirds of the scale.** The requirement was that a
competent-but-unremarkable artefact lands mid-scale; these six are
competent-but-unremarkable, and they land at 39-63%, centred on 51%. The
instrument has room above them for an artefact that is actually good and room
below for one that is bad.

Adding S5-S8 raised every artefact — they are properties all six largely have —
but it did not flatten the instrument: the spread held at 13 points against 12,
and the four new items are themselves split 7/6/6 against 7/7/6 rather than
sitting at the ceiling. That was the risk in scoring properties every competent
artefact satisfies, and it did not materialise.

### The sections disagree, which is the point

> **These six artefacts cannot support a claim about the framework.** The Phase E
> harness gave the control `--setting-sources project` and the framework arm the
> default, which also loads user settings — so one arm ran with the maintainer's
> own `CLAUDE.md` and the other ran without it. Every difference below is a
> difference between *framework plus that context* and a bare CLI, and there is
> no way to separate the two after the fact. See `incidents.md`, 2026-08-09.
>
> The table stays because it is what this instrument does to real artefacts, and
> that is what calibration needs to show: seven axes moving in different
> directions rather than one number at the ceiling. Read it as evidence about
> **the rubric**, never as evidence about the framework.

| Section | plain | S.A.R.A.H. | Direction |
| --- | --- | --- | --- |
| H hostile input | 2, 4, 2 | 2, 4, 4 | wash |
| R resources | 2, 4, 3 | 2, 1, 2 | plain higher |
| S security under change | 12, 8, 7 | 12, 13, 11 | S.A.R.A.H. higher |
| X docs that execute | 3, 5, 4 | 2, 2, 1 | plain higher |
| P restraint | 2, 2, 1 | 5, 5, 6 | S.A.R.A.H. higher |
| M maintainability | 2, 3, 3 | 6, 8, 5 | S.A.R.A.H. higher |
| O operator failure | 3, 1, 2 | 2, 2, 1 | wash |

A single saturated number said nothing. Seven axes that point in different
directions say something specific and falsifiable — which is the property the
instrument needed and v1 lacked. Whether any particular direction is *caused* by
the framework is a question these runs cannot answer, and Phase F is the run
built to answer it, with both arms loading the same setting sources.

### Item-level justification

Abbreviated to the load-bearing evidence. Every cell traces to a file and line
in the artefact or a reproduction in `scores/`.

**H1 (timestamp hostile values)** — plain-1 **2**: `signatures.py:279-283`
rejects non-finite with a comment explaining NaN, tested at
`tests/test_signatures.py:375` over `nan/NaN/inf/-inf/infinity`. plain-2 **2**:
`signatures.py:431` `MAX_TIMESTAMP = 10**12` plus `isfinite`, docstring names
the OverflowError hazard; tested at `tests/test_signatures.py:173` over
`inf/-inf/nan/1e400/"1"*400`. plain-3 **0**: `signatures.py:211` catches only
`ValueError`; judge C-3 reproduced live `202` with `nan` persisted to
`event_timestamp`, silently disabling the only replay bound. sarah-1 **0**:
`signature.py:39,43` — `int(timestamp)` then `abs(now - signed_at)` raises
`OverflowError` on a 400-digit header; judge B-3 reproduced an **unauthenticated
500**. sarah-2 **1**: `signature.py:78-84` catches `ValueError/OverflowError/
OSError` then falls through to `fromisoformat`; no crash, no test. sarah-3 **1**:
`signature.py:92-93` `raw.isascii() and raw.isdigit()` allowlists before any
arithmetic — the cleanest guard of the six — but no test names the hostile case.

**H2 (anonymous 5xx or unbounded commitment)** — plain-1 **0**: judge E-3
reproduced a thread pinned indefinitely by a declared-but-unsent body, "NO
RESPONSE after 20.1s"; `server.py:39` claims the opposite. sarah-1 **0**: the
same OverflowError, reachable with no secret. The other four **1**: bodies
capped (`app.py:25/30/145/167/170`) but pre-auth status codes act as oracles
(sarah-2 `413`, F-3; plain-2 `Content-Length` shapes, A-3).

**H3 (log neutralisation)** — plain-1 **0**: judge E-1 reproduced log forging
via percent-encoded newline in `PATH_INFO`, `app.py:105,136`. plain-2 and
plain-3 **1**: mix `json.dumps` with printf-style `log.warning("rejected %s %s
...")`. All three S.A.R.A.H. runs **2**: logging is exclusively `json.dumps`
(`logging.py` in sarah-1/sarah-2, 3 sites in sarah-3), so escaping is structural.

**R1 (retention coverage)** — plain-1/2/3 **2**: one growing table, one `DELETE
FROM deliveries` (`store.py:313`, `:532`, `:621`), reachable from a
`prune`/`purge` subcommand. sarah-1 **1**: three growing tables (`deliveries`,
`suppressions`, `handler_events`), purge covers only `deliveries`
(`store.py:204,207`); judges B-1 and B-3 both reproduced 49 `suppressions` rows
surviving a full purge. sarah-2 **0** and sarah-3 **0**: no `DELETE` anywhere in
`src/` — an unbounded payload archive and an unbounded dedup index. For sarah-2
this compounds: `senders.example.toml:32-34` makes the ledger load-bearing for
replay defence, so the obvious remedy reopens a security hole (F-2).

**R3 (concurrent double-execution)** — plain-1 **0**: judge E-2 reproduced "max
simultaneous handler runs for ONE delivery: 4" against `README.md:118-121`'s
explicit exclusivity claim, with `max_attempts` bypassed. plain-3 **0**: judge
C-1 reproduced 2 concurrent runs against `handlers.py:22-23`'s "Never for the
same event". sarah-1 **0**: `service.py:177-219` has no status guard, so
`replay` re-invokes handlers on `processed` deliveries — reproduced by B-1 and
B-2 independently. sarah-2 **0**: F-2 reproduced concurrent dispatch when
`dispatch_timeout_seconds > stale_after_seconds`, with no cross-field check.
plain-2 and sarah-3 **1**: at-least-once, disclosed.

**S1 (unsigned input driving a security decision)** — **The strongest item in
the rubric, and the one v1 most inverted.** v1's B3 gave all six 2/2 for
"idempotency keyed on delivery identity". That delivery identity is an unsigned
header in five of six, and judges reproduced one signed request becoming three
handler runs in packets A, C and D. plain-2 **0**: A-1, "the README's threat
discussion never mentions it". plain-3 **0**: C-3, "the README does not flag the
trade-off". sarah-3 **0**: D-1, "the README never mentions the fallback or its
consequence". sarah-1 **0**: `idempotency.py:52-62` caps the key length but the
header is outside the MAC (`signature.py:17-22` signs `timestamp.body` only) —
**a defect no judge found, in the artefact whose section-B score was full
marks**. plain-1 **1**: `require_delivery_id` validated at `config.py:151`.
sarah-2 **1**: `senders.example.toml:45-50` states the hazard and its
consequence (F-1: "called out honestly").

**S2 (weak primitives)** — plain-2 **0**: `signatures.py:41` `"sha1":
hashlib.sha1` in the selectable allowlist. plain-1 and plain-3 **1**:
`algorithm` configurable with a `sha256` default and no visible allowlist bound
(`signatures.py:56`, `config.py:48`). All three S.A.R.A.H. runs **2**: SHA-256
hardcoded; sarah-2 additionally rejects `hmac-sha1` by name at config load
(`tests/unit/test_config.py:68-73`).

**S3 (unauthenticated surface)** — plain-3 **0**: `config.py:123-124`
`expose_stats = True`, `stats_token = ""`; judge C-3 reproduced `curl /stats`
returning per-sender volumes and timings with no credential. sarah-1 **1**:
FastAPI mounts `/docs`, `/redoc`, `/openapi.json` unauthenticated (B-1), inert
but unrequested. The other four **2**.

**S4 (config that voids a security property)** — plain-2 **0**: A-2 reproduced a
`custom` scheme enforcing the replay window against an unsigned, attacker-
rewritable header, with nothing rejecting it. plain-3 **0**: C-2, `check` exits
0 on a secret encoding that rejects 100% of traffic. sarah-1 **2**:
`config.py:59` refuses a sender with no declared dedup mode. sarah-2 **1**: has
the dedup cross-check (`config.py:187-191`, with a remediation message) but F-3
reproduced a path without a leading slash validating clean, and config type
errors escaping as raw tracebacks. plain-1 **1**, sarah-3 **1**.

**X1 (quickstart runs verbatim)** — sarah-1 **0**: B-1 followed `README.md:114-
169` exactly and got `400 malformed_request` instead of the promised
`202`, because `config/senders.example.toml:19` requires a header the documented
`curl` never sends. sarah-2 **1**: `README.md:127`'s `uvicorn --factory` cannot
work — `create_app` requires a positional `config` (F-1) — but the CLI path
runs. sarah-3 **1**: no example config ships; D-3's judge had to hand-transcribe
the TOML out of the README. plain-1/2/3 **2**: default paths run cold (E-1
explicitly: "The primary path works exactly as documented").

**X2 (alternatives work)** — plain-1 **0**: `--port` advice at `README.md:31`
breaks `send` at `cli.py:112`; **all three judges hit this independently**.
plain-3 **0**: same shape, C-1. sarah-2 **0**: the documented factory
invocation fails. sarah-3 **0**: `check` creates a database while `cli.py:53`
says it starts nothing (D-1, D-2). plain-2 **1**, sarah-1 **1**.

**X3 (sender implementable from docs)** — sarah-3 **0**: D-2, "A sender team
handed this README cannot implement signing"; the canonical message
(`signature.py:45`) is nowhere in prose. plain-2 **2** and plain-3 **2**:
scheme, template, encoding and prefix documented.

**P1 (CLI surface)** — Counted from `add_parser` calls. plain-1 **0**: 7
(`serve, check, send, events, show, replay, prune`). plain-2 **0**: 8 top-level
plus 4 nested — `init-config`, `gen-secret`, `sign`, `send`, `drain`, and a
`deliveries` group with `list/show/retry/stats`. plain-3 **0**: 10 (`init,
check, serve, worker, sign, stats, list, show, retry, purge`). All three
S.A.R.A.H. runs **2**: exactly 2 each.

**P2 (config surface)** — distinct keys in the shipped example: plain-1 46
(**0**), plain-3 43 (**0**), plain-2 34 (**1**), sarah-2 30 (**1**), sarah-1 23
(**1**), sarah-3 12 (**2**).

**P3 (unrequested capability)** — plain-2 **0**: `gen-secret`, `init-config`,
`drain`, plus a SHA-1/SHA-512 digest engine and a template scheme language.
plain-3 **0**: a `worker` subcommand, a network `/stats` endpoint, `init`, and
three timestamp formats. sarah-1 **2** and sarah-3 **2**: `replay` and `purge`
trace to retention and recovery; `serve` and `check` trace to running it.
plain-1 **1**, sarah-2 **1**.

**P4 (test-only surface)** — sarah-1 **0**: `service.py:42-51` defines
`_before_reserve` and `set_reserve_barrier()`, a process-global mutable callable
invoked on **every accepted delivery** at `service.py:99-100`, existing solely
for `tests/integration/test_http.py:194-231`, shipped in the wheel. **All three
judges flagged it independently** — the clearest signal in the 96 that v1 had no
item for. sarah-3 **0**: `store.mark_handled(row_id, now)` accepts a `now` it
never binds (`store.py:229-238`), implying a completion timestamp that is never
recorded, plus a dead `TimestampProblem` import. Others **1**.

**M1 (bisectable)** — plain-2 **0**: 2 commits, one containing the entire
3,266-line project. plain-1 **1** (5 commits, `06f7122` is the whole receiver),
plain-3 **1** (4 commits, `c412a9c` is the whole project). sarah-1 **2** (12
commits, phase by phase), sarah-2 **2** (10), sarah-3 **2** (9).

**M2/M3 (decision reconstruction, invariants)** — ADR references and stated
invariants in `src/`: sarah-1 12, sarah-3 5, sarah-2 3, plain-2 2, plain-3 1,
plain-1 0. The S.A.R.A.H. runs carry `docs/adr/` with alternatives recorded;
the control runs carry none. plain-1 scores **0** on M3 rather than 1, because
`server.py:39` asserts an invariant — "A slow or hung sender must not be able to
occupy a connection forever" — that E-3 reproducibly violated.

**M4 (claims true)** — plain-3 **0**, sarah-1 **0**, sarah-3 **0**: each makes a
load-bearing claim its own behaviour contradicts (handler-contract exclusivity;
a durability promise `PRAGMA synchronous = NORMAL` under WAL does not provide;
`check` starting nothing while creating a database). sarah-2 **2**: F-3 verified
`README.md:39`'s "138 tests pass" as exact. plain-1 **1**: 241 claimed, 243
actual.

---

## Judging protocol

**Two judges per artefact, different scopes.** This is the change v1's post-
mortem asked for, and it is not optional — M is unscoreable without it.

| Judge | Receives | Scores |
| --- | --- | --- |
| **Judge S** (software) | The packet as v1 built it: source, tests, README, packaging. No history, no design documents. | H, R, S, X, P, O — **40 points** |
| **Judge P** (process) | The full working tree including `.git` and `docs/`. | M — **8 points** |

Judge S must be blind to the arm. Judge P **cannot be** — the presence of
`docs/adr/` identifies the arm immediately — so Judge P's 8 points are reported
separately and never folded into a blind comparison. Recording an unblinded
number honestly beats deleting the axis, which is what v1 did.

### Effort budget

**Per artefact, Judge S: 90-120 minutes.** Judge P: 20-30 minutes.

| Phase | Budget |
| --- | --- |
| Admission gate: install, run the suite, one signed delivery | 15 min |
| X: run the documentation verbatim in a clean directory | 15 min |
| H: run the hostile-input probes below | 20 min |
| R: enumerate tables vs deletes; fd watch; lease-expiry probe | 25 min |
| S: trace the dedup key to the signed payload; grep digests; read config validation | 20 min |
| P: count subcommands, config keys, capabilities; grep for test hooks | 10 min |
| O: misconfigure it three ways; replay a completed delivery | 15 min |

This is roughly double v1's budget, and buys roughly ten times the spread. Any
item a judge cannot reach inside the budget scores 0 and is reported as
unreached rather than silently skipped.

### Probe appendix

Ship these with the rubric so judges are not inventing them, and so two judges
probe the same things.

```sh
# H1 — hostile timestamps. Expect 4xx for every one, never 5xx, never 2xx.
for TS in "$(printf '9%.0s' $(seq 400))" nan NaN inf -inf 1e400 "" 999999999999999999; do
  curl -s -o /dev/null -w "%{http_code} <- $TS\n" -X POST "$URL" \
    -H "X-Webhook-Timestamp: $TS" -H "X-Webhook-Signature: sha256=deadbeef" -d '{"a":1}'
done

# H2 — declared-but-unsent body. Expect a timeout, not an indefinite hang.
printf 'POST %s HTTP/1.1\r\nHost: x\r\nContent-Length: 5000\r\n\r\nAB' "$PATH_" \
  | timeout 25 nc 127.0.0.1 "$PORT"; echo "exit=$?"

# H2 — deeply nested but well-formed signed JSON. Expect 4xx, never 5xx.
python3 -c "import sys;sys.stdout.buffer.write(b'['*100000 + b']'*100000)" > /tmp/deep.json

# H3 — log forging. Grep the log for a fabricated line afterwards.
curl -s -X POST "$BASE/hooks/%0a2026-01-01%2000:00:00%20INFO%20accepted%20FORGED"

# R1 — every growing table must have a delete path.
grep -rhoiE "CREATE TABLE (IF NOT EXISTS )?[a-z_]+" src/ | sort -u
grep -rhoiE "DELETE FROM [a-z_]+" src/ | sort -u

# R2 — descriptor growth across a few hundred requests.
ls /proc/$PID/fd | wc -l   # before, then after 200 deliveries

# R3 — drive a handler past the lease with concurrency > 1 and count overlaps.

# S1 — the decisive trace: does the dedup key come from a MAC-covered input?
grep -rn "delivery_id\|idempotency_key\|dedup" src/ | grep -i "header\|sha256"
# then replay one captured signed request N times, mutating ONLY the delivery-id
# header. More than one handler run is a 0.

# S2 / P1 / P2 — surface counts.
grep -rnE "hashlib\.(sha1|md5)|\"sha1\"|'sha1'" src/
grep -cE "add_parser\(" src/*/cli.py
grep -rhoE '^\s*[a-z_]+ *=' *.toml config/*.toml 2>/dev/null | tr -d ' =' | sort -u | wc -l

# P4 — test-only surface shipped in production code.
grep -rnE "^_[a-z_]+ *(=|:).*(None|\[\]|\{\})|def set_[a-z_]*(hook|barrier|override)" src/
```

---

## An instrument defect in v1 that v2 must not inherit

**This was found while calibrating, and it contaminates the existing data.**

`sanitize-packets.sh` deletes any **whole line** matching `sarah/`,
`docs/specs`, `docs/adr`, `docs/plans`, `docs/design`, `ARCHI.md` or
`CLAUDE.md`. Only the S.A.R.A.H. artefacts reference those paths, so the script
fired on three packets and not on the other three:

| Run | README lines, original | README lines, as judged | Deleted |
| --- | --- | --- | --- |
| sarah-1 | 301 | 294 | **7** |
| sarah-2 | 241 | 232 | **9** |
| sarah-3 | 269 | 259 | **10** |
| plain-1 | 229 | 229 | 0 |
| plain-2 | 364 | 364 | 0 |
| plain-3 | 414 | 414 | 0 |

The damage was not confined to READMEs. In `sarah-2`, `recovery.py:12` lost
`limitation is recorded in ADR-007 and in ARCHI.md's sharp edges.`, leaving the
docstring ending on `...recovers nothing; that`. `senders.example.toml:35` lost
`never pruned. See docs/adr/002.`, leaving `which is why the deliveries table
is`. In `sarah-3`, `cli.py:4` lost its subject, leaving the file opening on
`governam tudo aqui:`.

**Nine of the 96 unanticipated findings — every "truncated sentence", every
"dangling cross-reference to a document that does not exist" in packets B, D and
F — are damage the study inflicted, not defects the artefacts contain.** They
appear in all three S.A.R.A.H. packets and in none of the control packets, so
they are perfectly arm-correlated noise. A further five findings ("not a git
repository", "the tag and history claims are unverifiable") are artefacts of the
packaging script stripping `.git` from every packet.

Roughly **15% of the evidence base is instrument damage, and it is
systematically biased against one arm.** v1's scores were saturated and
therefore unaffected. Any future analysis that mines the 96 findings — including
this rubric's own derivation — must exclude these.

**v2's fix:** replace line-deletion with token-substitution. Rewrite `ARCHI.md`
to `ARCHITECTURE.md`, `docs/adr/` to `docs/decisions/`, and the framework's name
to a neutral token, leaving sentence structure intact. Then verify symmetrically:
every packet's line count must be unchanged from its source. If a packet's line
count moved, the blinding damaged it and the packet is rebuilt, not judged.

---

## What this rubric still cannot measure

Stated in advance, as v1's method required, so it cannot be quietly dropped.

**Whether restraint was a choice or a limit.** P scores the S.A.R.A.H. arm well
because it shipped 2 subcommands against the control's 7-12. The rubric cannot
distinguish deliberate scope discipline from a pipeline that ran out of budget
before it got to `gen-secret`. The cost table in `results.md` — where the
framework arm spanned 2.7× in cost — suggests both stories are live.

**Whether the maintainability signal survives contact with a maintainer.** M2
asks whether a decision can be reconstructed, and ADRs make that easy to score
well. It does not establish that anyone reconstructing a decision six months
later would reach a better outcome. That needs the longitudinal study
`results.md` asked for, where a second change is made to an artefact months
later by someone who did not write it. One build cannot test a claim about time.

**Anything about the human gates.** Unchanged from v1: driving the CLI headlessly
requires suppressing the questions gates 1 and 2 consist of. This rubric scores
artefacts, and the artefacts were produced with those gates switched off.

**Whether the brief is discriminating.** A webhook receiver with HMAC
verification is abundant in training data, and v1's post-mortem named this as a
cause of saturation. v2 gets its spread from resource behaviour, restraint,
executable documentation and maintainability — axes where priors help less — but
it is still one memorised task. A brief with a genuine architectural fork and
requirements that must be traded off against each other would test more.

**Inter-judge agreement on the softer items.** H, R, S, P and X are mechanical:
counts, probes, reproductions. M2 ("can a decision be reconstructed") and P3
("was this capability necessary") require judgement, and their reliability is
unknown until measured. Report per-item judge spread for these two specifically;
if judges disagree by more than a point, the items need tightening or dropping.

**The floor.** These six artefacts cluster at 39-63%. The calibration
`results.md` asked for has since been run: a deliberately mediocre receiver — no
retention, no tests for hostile input, one commit, a README that does not run —
scored 8/48 on the draft and **2-4/56** on the revised instrument, well below the
six real artefacts and inside the target band. That is what makes the spread
above meaningful rather than merely wide.

**Re-run that floor whenever an item is added or reworded.** S5-S8 were added
after the calibration and scored against the six real artefacts but never against
the floor; the floor's 2-4 is therefore a lower bound that four untested items
could only raise. If a revised instrument ever puts the floor above 20 of 56, it
has stopped discriminating and is not ready.
