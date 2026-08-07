# Scoring rubric

Derived from the brief before any run was executed, so that no criterion is
reverse-engineered from what an arm happened to produce.

Judges receive one artefact at a time, without being told which arm produced it
or that two arms exist. Judges score by reading and executing the code, never
by reading the run logs.

## How to score

Each item: **2** fully met, **1** partially met, **0** absent or wrong. Every
score above 0 must cite a file and line, or a command that was run and its
output. A claim with no evidence scores 0 — this rubric measures artefacts, not
intentions.

## A. Stated requirements (max 12)

The brief asks for these in so many words. Failing here is failing the ask.

| # | Item |
| --- | --- |
| A1 | Accepts HTTP POST of a JSON payload |
| A2 | Verifies the signature header against a per-sender shared secret |
| A3 | Supports multiple senders, each with its own secret and endpoint path |
| A4 | Hands verified deliveries to a handler behind a seam that could be swapped for real processing |
| A5 | Persists the event durably |
| A6 | Installable, with a test suite that runs |

## B. Unstated but implied (max 10)

The brief describes the situation that makes each of these necessary without
naming any of them. **This section is where a process should earn its cost.**

| # | Item | What the brief said that implies it |
| --- | --- | --- |
| B1 | Signature comparison is timing-safe (`hmac.compare_digest` or equivalent, never `==`) | "so we can tell the delivery really came from the sender" — a signature check that leaks timing is not a signature check |
| B2 | The timestamp header is actually used to reject stale deliveries (replay window) | The timestamp is mentioned; a timestamp that is parsed and ignored is decoration |
| B3 | Duplicate deliveries are made idempotent by delivery identity, not by payload equality | "some of them send the same delivery more than once" and "can't have duplicates causing duplicate work" |
| B4 | Signature is computed over the raw request body, not over re-serialised JSON | Implicit in signature verification; re-serialising changes bytes and breaks real senders |
| B5 | Fast 2xx: slow handler work does not block the response | "retry aggressively when they don't get a fast 2xx" |

## C. Failure behaviour (max 8)

| # | Item |
| --- | --- |
| C1 | Invalid signature is rejected with an appropriate status, and the reason is not leaked to the caller |
| C2 | Malformed or non-JSON body is handled without a 500 or a stack trace |
| C3 | Missing or unparseable headers are handled explicitly |
| C4 | A handler that raises does not corrupt state or lose the delivery silently |

## D. Tests (max 8)

| # | Item |
| --- | --- |
| D1 | Suite passes on a clean checkout, verified by running it |
| D2 | Covers the happy path end to end |
| D3 | Covers signature rejection, replay rejection, and duplicate delivery |
| D4 | Tests assert behaviour rather than restating the implementation |

## E. Architecture and documentation (max 6)

| # | Item |
| --- | --- |
| E1 | The sync-vs-async decision is made deliberately and is visible in the code's structure |
| E2 | Secrets are not hardcoded in source |
| E3 | A reader can run it from the documentation alone |

**Total: 44.**

## Reported separately, never scored

These are recorded per run and reported as measurements, not as rubric points,
because they are inputs and costs rather than qualities of the artefact:

- Wall-clock and model cost, from the run's `stream-json`.
- Lines of source and lines of test.
- Number of commits, and whether the history is bisectable.
- Any defect a judge finds that this rubric does not anticipate — recorded
  verbatim, because an unanticipated finding is more informative than a
  checklist item and belongs in the writeup either way.
