# The habits that earned their place

**Date:** 2026-10-24 · **Level:** 3 · **Phase:** 6-review

User-facing: `/sarah-init` now offers an opt-in catalog of working habits, each tied to the failure it prevents, and installs only the ones you pick.

v0.1.0 gave a project phases, state and gates, and no operating habits. The
maintainer runs a second product with Claude Code without the framework, and its
habits grew from incidents and held only once they became mechanisms; the
measurement pilot showed the other side, what the framework over-produces. The
rule of entry that answers it: a habit born from an incident, installed where the
incident never happened, is weight. So every habit names its failure, and none
installs unless chosen.

## What shipped

| Part | Where |
| --- | --- |
| Install engine, grants, always-ask rules | `scripts/habits.py`, `skills/sarah-init/habits/` |
| The interview, in plain words | `skills/sarah-init/references/habits-catalog.md` |
| Conversation defaults and habit status lines | `hooks/scripts/session-start.sh`, `hooks/conversation-defaults.txt` |
| Executor and its brief | `agents/executor.md`, `skills/sarah-phase-implement/references/executor-brief.md` |
| Tracker seam and Trello adapter | `scripts/tracker.py`, `scripts/tracker_trello.py` |
| Guards: gitflow, changelog fragment, dispatch, no-idle | payloads under `skills/sarah-init/habits/` |
| Short rituals, durable decisions, state-size sensor | `ill-be-back`, `hasta-la-vista`, `sarah-compact` |
| Decisions | ADR-006 to ADR-010 |

## The decisions that matter

**The plugin's own hooks stay sensors.** Blocking behaviour is a file in the
user's project, installed after they approve the exact diff, owned by them, and
removed by the entry point that added it (ADR-008). **One narrow exception to
"every merge has a human behind it":** with the `merge-on-green` grant, a feature
branch merges on green CI; cutting the release stays the user's (ADR-010). Local state
is the source of truth for the tracker, and the credential is an environment
variable only (ADR-009).

## Verification

Unit, integration, static and shell suites pass locally, including under dash.
The session-start worst case is 389 of 400 tokens, `sarah-bootstrap` stays under
its 2,000-token ceiling, and four platform probes held on CLI 2.1.308.

## Gate 4

Two reviewers in clean contexts found no credential leak and no code execution
through crafted input, and nine blocking defects, all fixed test-first before
merge. The tracker was never actually wired (the hook looked in the wrong
section, no ritual ran it, ready work read as blocked); a continued line, `env -i`
or `/usr/bin/env` slipped past the gitflow guard; an agent could grant itself
allow rules or edit the agreements unprompted; the push grant could be widened by
a second refspec; a forged record made `remove` delete the user's own settings or
workflow; and "rule not checked" never reached anyone, since exit-0 stderr is not
shown. The always-ask rules now also cover the agreement files themselves, which
raises the bar for a mistaken agent and is no boundary against a hostile one.

## Deliberately not done

- **The tracker has not been smoke-tested against live Trello.** Endpoints and
  fields were written from memory and tested against a stub. That test, with the
  maintainer's own credentials set outside the session, comes before the release.
- **A forced model fallback is not reported**, and `CLAUDE_CODE_EFFORT_LEVEL`
  removes per-call effort. Both are written down in `docs/operating.md`.
- **No study measures whether the habits help.** The pilot is the first reading
  and is partial.
