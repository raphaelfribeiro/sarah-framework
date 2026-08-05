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

**Not yet real:** the seven phase skills and the agent roster they load. Until
Phase B lands, `sarah-bootstrap` routes to skills that do not exist.
