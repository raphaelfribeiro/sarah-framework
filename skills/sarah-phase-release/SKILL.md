---
name: sarah-phase-release
description: Cut a release - propose a CI/CD pipeline if the project has none, determine the semantic version, write release notes from the changelog, and tag. Use when the user says "release it", "ship it", "cut a version", "tag it", "deploy", "set up CI", "how do we deploy this", or when reviewed work is ready to go out. Delivers the pipeline, the notes, and the version without being asked for each.
---

# Phase 7 — Release

This phase delivers three things by default. The user should never have to remember to ask for any of them.

1. **A CI/CD pipeline**, proposed as options, when the project does not already have one.
2. **Release notes**, generated from `sarah/changelog/`.
3. **A version and a tag**, following semantic versioning.

## When this phase applies

| Level | Applies |
| --- | --- |
| **0–1** | Only when the user is actually releasing. Ordinary fixes accumulate; they do not each cut a version. |
| **2–3** | Yes, when the work is ready to go out. |

## Who works this phase

**DevOps Engineer** for the pipeline, configuration, secrets, and rollback. **Release Manager** for the version, the notes, and the checklist — running on a fast model, because this is assembly and verification rather than judgment.

## Pipeline: propose, never assume

If the project has no pipeline, spawn the `devops-engineer` and bring back **two or three options for this project**: the one the project's host already provides, a portable alternative, and honest manual deployment where the project does not warrant automation. For each: setup cost, running cost, and lock-in. Then a recommendation with reasons.

Never pick a CI provider silently. This choice sticks for years, and it is the phase where silent decisions are most tempting.

Keep it proportional. A pipeline more elaborate than the thing it deploys is a second project nobody asked for. Build, test, deploy, roll back — add stages when a specific failure justifies one.

Secrets never enter the repository, the image layers, the build logs, or a client bundle. A committed secret is compromised; rotation is the fix, not deletion.

## Version and notes

Spawn the `release-manager` with the entries in `sarah/changelog/`.

**Semantic versioning, strictly.** One breaking change makes it a major release regardless of what else is in it. The rule is not a vote.

**Release notes are written for the reader**, not the author: what changed for a user, not which function moved. Breaking changes go at the top with the migration step. A breaking change discovered after upgrading is the worst release note failure there is.

## The checklist

Nothing is tagged with an open item:

- Every delivery in this release has an entry in `sarah/changelog/`.
- The version follows from the changes.
- `README.md` reflects anything user-visible.
- `ARCHI.md` reflects any architectural change.
- Tests pass — run them, do not assume.

## What you never do

- Tag with the checklist open. Report the open item and stop.
- Invent a changelog entry for work you cannot trace. Report the gap.
- Deploy from a developer's machine as the normal path.
- Skip tests to get a release out. If that is the call, it is the human's, made explicitly.
- Push or publish anything without being asked. Publication is a decision, not a step.

## Exit gate

Released, tagged, and `sarah/state.md` updated to reflect the new version and an empty runway — all of it committed, and the release branch merged the way the project's branching model prescribes.

If a tracker MCP is connected, offer to move the related cards or close the issues — as an option. If none is connected, the subject never comes up.
