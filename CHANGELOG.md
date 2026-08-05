# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Plugin foundation.** `plugin.json` and `marketplace.json` manifests, MIT
  license, and this changelog.
- **`sarah-bootstrap` skill.** The orientation layer: reads `ARCHI.md` and
  `sarah/state.md` at the start of a task, classifies the work into a scale
  level, and routes to the right phase with only that phase's agents in
  context.
- **`/sarah-init` skill.** Interactive project setup. Detects greenfield versus
  brownfield, classifies the scale level, and generates `ARCHI.md`,
  `README.md`, and `sarah/state.md` from the shipped templates.
- **Templates.** `ARCHI-template.md` (long-term architecture memory, held to
  the 10% context budget) and `README-template.md` (built on the
  `standard-readme` specification and the Best-README-Template conventions).
- **`session-start` hook.** Opt-in and fail-graceful. Detects an initialized
  project, injects a short bootstrap pointer, and suggests `/ill-be-back` when
  work is already in flight.

[Unreleased]: https://github.com/raphaelfribeiro/sarah-framework/commits/main
