# Phase A — Foundation

**Date:** 2026-08-05 · **Level:** 3 · **Phase:** 5-implement

Laid the plugin foundation and the memory layer. S.A.R.A.H. can now be installed
and can initialize a project, though it cannot yet run a development phase.

- Plugin and marketplace manifests; the repository root is the plugin root and
  passes `claude plugin validate . --strict`.
- `sarah-bootstrap` — the orientation skill that reads state, sizes a request
  into a scale level, and routes to a single phase with only that phase's
  specialists in context.
- `/sarah-init` — interactive setup that detects greenfield versus brownfield,
  interviews only for what it could not read from disk, and generates the
  project's memory files.
- Templates for `ARCHI.md`, `README.md` (on the `standard-readme` specification)
  and `sarah/state.md`.
- `session-start` hook: POSIX `sh`, silent in non-S.A.R.A.H. projects, verified
  across eight scenarios including a missing `jq`, an unreadable state file, and
  malformed input. Every path exits 0.
- MIT license, changelog, and this repository's own `ARCHI.md` and state files —
  the framework now runs on itself.

**Fixed under acceptance testing.** The first build put templates in a root
`templates/` directory and pointed the skill at them by absolute path. An
installed plugin cannot read outside its own directory, so the reads were
blocked — and rather than stopping, the skill paraphrased the templates from
their descriptions, producing files with renamed sections, invented HTML
comments, and a README that had dropped its badges, table of contents and
License section. Templates now live in `skills/sarah-init/references/` as real
files, the generation step orders a verbatim structural fill, and a new
self-verification step greps its own output for leaked comments and unfilled
placeholders before reporting success.

**Verified end to end:** greenfield `/sarah-init` generates all nine `ARCHI.md`
headings verbatim and in order, a `README.md` carrying every `standard-readme`
section with License last, and zero leaked comments or placeholders across all
three files. Re-running `/sarah-init` refuses to overwrite and offers three
choices. A typo request is classified Level 0 and reaches the code with no plan,
no spec, and no gate.

**Not yet real:** the seven phase skills and the agent roster they load. Until
Phase B lands, `sarah-bootstrap` routes to skills that do not exist.
