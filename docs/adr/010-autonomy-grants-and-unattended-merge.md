# ADR-010 — Autonomy grants at init, and unattended merge on green CI for opted-in projects

**Date:** 2026-10-24 · **Status:** accepted. For projects that install R13, it supersedes the bootstrap line "Every merge has a human behind it".

## Context

R2 and R7 of the habits spec ask the agent to keep going within approved work, including long unattended runs. The approval gates still stop: spec, plan, review verdict, release.

Two questions followed. What may the agent do on its own while unattended? And does merging need a human?

The framework already said "Every phase that produces an artefact ends with a commit" (`ARCHI.md` §7) and "Every merge has a human behind it" (`sarah-bootstrap` §4). The architect recommended that merge always wait for the user. The user decided otherwise on 2026-10-24.

The security advisor asked for unattended authority to be explicit, named, and separate from plan approval. The two decisions are recorded together because they answer the same question, what the agent may do without asking, and the merge permission is expressed as a grant.

## Options considered

### Commit only; push when the plan says so; merge always waits for the user

- **Makes easy:** keeps "every merge has a human behind it".
- **Makes hard:** an overnight run ends with branches waiting to be merged by hand.
- **Cost to reverse:** low.

### With R13 installed, merge a feature branch unattended once CI is green

- **Makes easy:** integration actually happens without a human, guarded by the branch model and green CI.
- **Makes hard:** removes the human from integration merges in opted-in projects. CI quality becomes the only gate on the integration branch.
- **Cost to reverse:** low per project, by removing the grant or R13.

### Unattended authority implied by an approved plan

- **Makes easy:** no extra step.
- **Makes hard:** a plan describes what to build, not which risky actions are acceptable. It would authorise anything the plan's author did not think to exclude.
- **Cost to reverse:** high once trust is lost.

### A named grant list, set once per project at init and expandable in conversation

- **Makes easy:** explicit and reviewable unattended authority; anything else is asked.
- **Makes hard:** one more interview step at init.
- **Cost to reverse:** low, by deleting a row.

## Decision

**Autonomy grants.**
- At `/sarah-init` the user grants a named list of actions the agent may take unattended, for example push to `feature/*`, ssh to a named host, run device tests.
- The list lives in the Autonomy section of `sarah/habits.md` (action, scope, grant date). It grows in conversation only on the user's explicit instruction in that turn, without re-running init.
- Anything not on the list is asked.
- **An approved plan does not by itself authorise any listed-risk action.**
- **Always asked, whatever the list says:** destructive actions (recursive delete, force-push, deleting branches, rewriting history), spending money, and touching credentials. This list is fixed in the plugin and installed, where a pattern exists, as `permissions.ask` rules in the project settings.
- The framework never writes `allow` rules on its own. At init it offers matching allow rules for granted actions in `.claude/settings.local.json`, as a diff the user approves.

**Unattended merge.**
- When R13 is installed, its install diff adds two grants: "push feature/*" and "merge feature/* into the integration branch once CI is green" (`merge-on-green`, a recorded row with no allow rule).
- While the `merge-on-green` row is in the Autonomy section of `sarah/habits.md`, the agent merges on its own after `gh pr checks` is green. Without the row it asks, even with R13 installed; `grant revoke merge-on-green` ends it. The R13 hook refuses anything else.
- Deciding to release stays a user gate, and a merge to `main` is part of a release.
- Without R13, merge waits for the user.
- Every phase that produces an artefact still ends with a commit on the task's branch, unattended runs included.

**Superseded, for opted-in projects only:** "Every merge has a human behind it." The reason: in the measured pilot, integration that waited on a human did not happen at all. With the branch model and green CI enforced mechanically, the user judged an unattended integration merge to be safer than no integration. The line stays true for every project without R13, and the bootstrap is edited in implementation to say so rather than deleted.

## Consequences

- In opted-in projects, CI is the last line of defence on the integration branch. Weak CI means weak merges, and the framework cannot detect that.
- `sarah/habits.md` is committed, so grants apply to every collaborator's agent in that repository. That is acceptable for single-maintainer projects and left open for teams.
- The always-ask list rests partly on platform permission patterns, which are textual and leaky. It is a backstop beside the agent's rule, not a sandbox. Whether project `ask` rules still prompt in the user's permissive modes is unverified.
- Unattended executors share the session's credentials. The grant list narrows what they should do; it does not narrow what they can reach.

## Revisit when

A team adopts the framework (grants per person), an unattended merge breaks the integration branch, or the platform offers per-agent permission scopes.

## Note, 2026-10-24: what the always-ask list does and does not stop

Gate 4 review found that the agent could write its own `allow` rules (`grant add`, `grant allow --write`) and edit `sarah/habits.md`, `sarah/exceptions.log` and `sarah/hooks/**`, none of which the platform protects. It also found that the `push-feature` allow rule, `git push origin feature/*`, matches a second refspec such as `feature/x:main`, because `*` matches any text.

The always-ask payload now asks before edits to those files, before the two grant commands, and on the colon, `-d`, `--mirror`, `--all` and second-argument push forms. Ask rules are evaluated before allow rules and are not auto-approved in any mode, so a matching rule prompts even where an allow also matches.

This raises the bar for a mistaken or prompt-injected agent. It is not a boundary against a hostile one. The patterns are text: a shell write such as `sed -i` on `sarah/habits.md`, or `rm -r sarah/hooks/_lib`, is not provably covered, because the platform does not say that ask rules extend to Bash file commands as deny rules do, and no rule reaches a write made by a subprocess such as a Python script. The real controls on a push are the gitflow guard and server-side branch protection; the `feature/*` allow rule is a convenience, not an enforcement. The fixed list still does not remove routine rules such as `git rebase` and `printenv`; whether to keep them is the user's call.
