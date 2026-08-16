# Measurement pilot — Jukebox Disc

**Branch:** none yet · **Level:** 2 · **Phase:** running, outside this repository · **Updated:** 2026-08-16

The framework is published and unproven. This is the instrument: use S.A.R.A.H.
on a real greenfield project and collect what it actually does, so fixes come
from evidence instead of from reading the prose again.

## The subject

**Jukebox Disc**, at `dev/jukebox-disc` — an offline music player (FLAC, OGG,
MP3), track metadata including a 0.00-10.00 quality score, radio by URL, paid
download, light and dark themes, equaliser. iOS first, Android after. Empty git
repository, `main`, no commits. Deliberately not a toy: nobody guards a gate they
do not care about.

## Setup, done 2026-08-16

- `~/.claude/settings.json` pins the marketplace to
  `{source: github, repo: raphaelfribeiro/sarah-framework, ref: v0.1.0}`. **The
  pilot therefore runs against the tag, not the working tree** — this repository
  can be edited freely without contaminating a run. It was pinned to the local
  directory before, which would have silently undone the swap.
- `cleanupPeriodDays: 365`. The default 30 would have deleted the init, the
  brainstorm and the first spec before anyone read them.

## What the instrument records by itself

Verified on a real transcript: `tool_use`, **`AskUserQuestion` with the answers**,
`Skill`/`Agent`/`Task`, tokens and cost, under
`~/.claude/projects/<slug>/`. `docs/study/count-framework-use.py` already parses
this format, and already carries the caveat that matters — a slash command is
expanded before it becomes a tool call, so naive counting under-reports.

The `AskUserQuestion` records are the point: **the human gates have never been
measured**, because every instrumented run so far carried "do not ask me
anything". This is the first time that question is answerable.

## What it cannot record

- **A skill that never fires leaves no trace.** Under-triggering is the framework's
  default failure and it produces zero bytes.
- **The transcript shows the gate asked, not that anyone thought.** It cannot
  separate a decision from a rubber stamp.
- **Friction.** Where the ceremony felt oversized, where routing had to be asked for.

These need three handwritten lines per session, outside the project repository.
Without them the pilot measures only what is easy to measure, which is how both
previous studies failed.

## Rules for the run

- **Never write "do not ask me anything".** That instruction is what blinded
  every previous run.
- **Do not write the analyser yet.** Two or three real sessions first. Building
  the ruler before seeing the data is exactly the Phase E error, where everything
  scored 43-44 out of 44.
- **Watch the cut line.** Jukebox Disc is a Level 3 product. The spec phase should
  cut a shippable v0.1.0 — local playback, metadata, themes — and defer radio,
  download and the score. If it does that unprompted, that is evidence for the
  framework. If it swallows the whole scope without arguing, that is the first
  defect the pilot found.
- **Watch the legislation question.** Downloading from a radio stream is legally
  different from playing a file you own. It has to surface in brainstorm, before
  anyone designs a screen for a feature that may not be allowed to exist.

## Blocked

Nothing.

## Pending decisions

Nothing. Everything needed to start is in place.

## Next

**Nothing in this repository.** It is closed for the duration: the pilot runs
against the published tag, so nobody needs to come back here until Jukebox Disc
is finished and the transcripts are ready to read.

1. **Start the pilot.** New session with cwd `dev/jukebox-disc`, run `/sarah-init`.
   Not from this repository — a session loaded with the framework's own context
   measures nothing.
2. **Done 2026-08-16 — the marketplace is on GitHub, pinned to `v0.1.0`**, and the
   plugin is installed from it. Verified by listing, not assumed. **Note for
   whoever repeats this:** `claude plugin marketplace remove` + `add` silently
   uninstalls the plugin *and* drops the `ref` pin from `extraKnownMarketplaces`,
   leaving the marketplace tracking the default branch. Both had to be put back
   by hand. A swap that looks successful can still leave you following `main`.
3. **Around 2026-09-20, verify the retention held** — a transcript older than 30
   days must still exist. Configured is not the same as working, which this
   repository learned six times on 2026-08-16. This is the one dated item, and
   it is the only thing between the pilot and losing its own beginning.
4. **After two or three real sessions**, read the transcripts and write down what
   the framework did. Only then decide whether an analyser is worth building.
5. **Copy the pilot's transcripts somewhere backed up.** They exist on one disk.
   Retention protects against cleanup, not against losing the machine.

## What the return visit is for

When Jukebox Disc is done, this repository reopens to answer, from the
transcripts and the handwritten notes: did the human gates hold; which skills
never fired; did phase-closing commits actually happen; which itinerary rows were
always dropped; was the sizing right; and what it cost in tokens per level. Those
answers become the fixes, and each one is a delivery here with its own changelog
entry. Everything before that is collection, not analysis.
