# The user picks the route

**Date:** 2026-08-15 · **Level:** 2 · **Phase:** 5-implement

The cut proposal had the framework merging four phases into one, for everyone,
permanently — on the strength of a cost measurement taken from a single brief.
The maintainer replaced it with a better answer: let the user choose the
itinerary per request.

Same saving available to anyone who wants it, no capability removed from anyone,
and it follows the principle the framework already sells: the machines propose,
the human decides.

## What changed

At Level 2 and above, work opens with all eight steps as a table — in or out,
the reason drawn from **this request** rather than from the level, and the cost
in the user's own time. Any row can be overruled in a phrase.

```
Level 2 · itinerary for: webhook retry limit

  step             | why here                        | cost
  -----------------|---------------------------------|------
  [ ] Brainstorm   | problem already stated          | ~10min
  [x] Business an. | no acceptance criteria yet      | ~10min
  ...
→ enter to proceed · "add ux" · "drop system analysis" · "why?" for the trade-offs
```

Levels 0 and 1 get no table. Eight rows to justify a rename is the ceremony this
framework exists to prevent.

## The rules that make it honest

- **A dropped step is recorded in `sarah/state.md`, not argued with.** The user
  asked for a framework that obeys. If the omission later matters, that line is
  how anyone finds out why.
- **Documentation cannot be dropped.** Gate 5 is what makes the next session
  possible. It shrinks to one line at Level 0-1; it does not vanish.
- **Dropping security on a request touching auth, secrets or personal data**
  costs one sentence naming what goes unchecked. Then it complies.
- **The reason must come from the request.** "Level 2 includes it" tells the
  user nothing they can disagree with.

## Context budget

The criteria and costs live in `skills/sarah-bootstrap/references/itinerary.md`,
loaded only when the table is built. The always-on instruction is three
sentences. `sarah-bootstrap`: ~1,822 tokens against its 2,000 ceiling.

## Found while doing this, not fixed

The state model is single-track: one `sarah/state.md`, one **Current task**, one
phase, versioned and rewritten continuously. Two features in parallel produce two
divergent state files and a conflict at every merge. That is a defect today and
it is what a sprint would hit on day one. Named in `sarah/state.md` as open
before v1.
