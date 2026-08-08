# The three changes

Each is delivered in a **fresh session**, days apart in principle and with no
conversation carried over. That is the whole design: the model that receives
change 2 did not write change 1 and cannot remember why anything is the way it
is. It can only read what is in the repository.

Each change is phrased the way a stakeholder would phrase it, and each one walks
straight into a decision the first build had to make. None of them mentions
tests, architecture, or any part of either arm's process.

---

## Change 1 — a sender that signs differently

> We're onboarding a new partner, Globex. Their platform signs the payload on
> its own — no timestamp in the signed string, and they send the digest
> base64 rather than hex. Everyone else stays as they are. Get them working.

**The trap:** the first build almost certainly signs `timestamp.body` for
everyone. The lazy fix is to relax the canonical string globally, which quietly
removes replay protection from every existing sender. A per-sender scheme is the
correct answer, and whether it was already a boundary is exactly the kind of
thing an architecture record would say.

## Change 2 — duplicates are getting through

> Support is seeing the same delivery processed twice for one customer, maybe
> once a week. It's costing us money downstream. Make it stop.

**The trap:** this is the dedup decision, revisited by someone who has no memory
of it. The tempting fix is a stricter global uniqueness key. In one of the
earlier artefacts, exactly that choice was made, found wrong, and reversed —
global uniqueness makes one sender's delivery a duplicate of another's, and with
a single sender configured no test notices. An artefact that recorded the
reversal should not repeat it. One that did not, might.

## Change 3 — the database keeps growing

> Disk on the box is filling up. We need old stuff cleared out, but we can't
> break the duplicate protection while doing it.

**The trap:** the dedup ledger is load-bearing for replay defence. Pruning the
payloads is safe; pruning the keys makes an old redelivery new again. The
distinction is subtle, invisible to any test written before the change, and it
was explicitly recorded as a consequence in one earlier artefact's decision log.

---

## What gets measured

After each change, and again at the end:

1. **Regression.** Does the test suite that existed *before* the change still
   pass? A break here is the clearest possible signal, and it is objective.
2. **Relitigation.** Was a decision recorded in the repository reversed without
   the change mentioning it? Detected by diffing decision records and searching
   the transcript for the reasoning.
3. **Trap avoidance.** Each change above has a named wrong answer. Did the arm
   take it?
4. **Cost and wall clock** per change, from the stream-json.
5. **The final artefact** scored against `rubric-v2.md`, blind, as before.

The first three are the point. They are the things a single from-scratch build
cannot measure, and they are where memory of a decision either pays for itself
or does not.
