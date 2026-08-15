# Building the itinerary

Loaded when you present the itinerary. Not in the session budget.

The scale level proposes; the user disposes. Your job is to mark each step as
in or out **for this specific request**, give the one reason that decided it,
and let the user overrule any row without argument.

## The table

Eight rows, always all eight — a step the user never sees is a step they cannot
ask for. Keep every cell short enough to read at a glance.

```
Level <N> · itinerary for: <the request, in six words>

  step             | why here                        | cost
  -----------------|---------------------------------|------
  [ ] Brainstorm   | problem already stated          | ~10min
  [x] Business an. | no acceptance criteria yet      | ~10min
  [x] System an.   | crosses a data boundary         | ~15min
  [ ] UI/UX        | no user-facing surface          | ~20min
  [x] Build & QA   | always                          | —
  [x] Security     | untrusted input from outside    | ~10min
  [x] Docs         | gate 5                          | ~5min
  [x] Deploy       | goes to production              | ~10min

→ enter to proceed · "add ux" · "drop system analysis" · "why?" for the trade-offs
```

Then stop. This is a decision point, not an announcement.

## What decides each row

The reason must come from **this request**, never from the level alone. "Level 2
includes it" tells the user nothing they can disagree with.

| Step | Include when | Drop when |
| --- | --- | --- |
| Brainstorm | The problem is stated as a wish, or more than one solution is plausible | The request already names what to build |
| Business analysis | Acceptance criteria are missing, or scope has no edge | The change is mechanical, or criteria already exist |
| System analysis | It crosses a boundary, owns data, or the failure mode is unclear | It stays inside one module with an obvious shape |
| UI/UX | Anything a human sees or types, including a CLI's command shape | No user-facing surface at all |
| Build & QA | Always | Never — this is the work |
| Security | External input, credentials, permissions, personal data | Nothing crosses a trust boundary |
| Documentation | Always, proportional to level (gate 5) | Never dropped; at Level 0-1 it is one line in `sarah/state.md` |
| Deploy, monitor & operate | It reaches an environment someone depends on | Nothing ships yet |

## Costs

Estimates, in the user's time, not the model's. They exist so the user can
weigh a step, so a wrong-but-honest number beats no number. Say they are
estimates once, in the first itinerary of a session, and never again.

## When the user drops something

**Record it, do not argue.** One line in `sarah/state.md` naming the step and
that the user dropped it. If it later turns out to have mattered, that line is
how anyone finds out why it was missing — and the user asked for a framework
that obeys, not one that lectures.

Two exceptions, and they are refusals of the gate, not of the step:

- **Documentation** cannot be dropped. Gate 5 is what makes the next session
  possible. It can shrink to one line; it cannot vanish.
- **A dropped Security step on a request touching auth, secrets or personal
  data** gets one sentence of consequence before you comply: what specifically
  goes unchecked. Then comply, and record it.

## "Why?"

When the user asks, give the trade-off for the rows they are most likely to
doubt — the ones you marked in that cost real time, and the ones you marked out
that a careful reader might want. Two or three sentences per row, in the
project's own terms. Not a lecture on software process.
