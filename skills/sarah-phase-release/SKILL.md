---
name: sarah-phase-release
description: Cut a release and put it under watch - propose a CI/CD pipeline if the project has none, determine the semantic version, write release notes from the changelog, tag, and define how the release is observed and rolled back. Use when the user says "release it", "ship it", "cut a version", "tag it", "deploy", "set up CI", "how do we deploy this", "how do we monitor this", "is it healthy", "add logging or metrics", "set up alerts", or when reviewed work is ready to go out. Delivers the pipeline, the notes, the version, and the observability without being asked for each.
---

# Phase 7 — Release and operate

This phase delivers four things by default. The user should never have to remember to ask for any of them.

1. **A CI/CD pipeline**, proposed as options, when the project does not already have one.
2. **Release notes**, generated from `sarah/changelog/`.
3. **A version and a tag**, following semantic versioning.
4. **A way to know whether it is working**, and a way back if it is not.

## Observability — the fourth deliverable

Shipping is not the end of the lifecycle. A release nobody can observe is a release nobody can operate, and "it deployed successfully" is not the same claim as "it works".

Spawn the `devops-engineer` for this, proportional to the level. It is a proposal with options and a recommendation, like every other real decision here.

| Level | What ships with the release |
| --- | --- |
| **0-1** | Nothing new. The existing logs are the answer. |
| **2** | Health check, structured logs for the paths that can fail, and the one number that says the system is doing its job. |
| **3** | The above, plus alerts with an owner and a threshold, and a dashboard for the golden signals: traffic, errors, latency, saturation. |

Two rules that hold at every level:

- **An alert nobody acts on is noise, and noise trains people to ignore alerts.** Every alert names what a human should do when it fires. If there is no action, it is a metric, not an alert.
- **Define the rollback before the deploy, not during the incident.** State the command, who can run it, and what data does not come back.

`sarah-hotfix` handles the emergency. This is what makes the emergency visible in the first place.

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
- The release can be observed and rolled back, at the level the project is at.
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
- Call a deploy done because it succeeded. Done is when somebody can tell it is working.

## Gate 5 — documented, committed, released

Released, tagged, and the task's file in `sarah/state/` updated to reflect the new version and an empty runway — all of it committed, and the release branch merged the way the project's branching model prescribes.

If a tracker MCP is connected, offer to move the related cards or close the issues — as an option. If none is connected, the subject never comes up.
