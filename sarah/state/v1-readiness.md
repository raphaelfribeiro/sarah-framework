# v1 readiness — evidence, visibility, and the state model

**Branch:** `develop` · **Level:** 3 · **Phase:** 5-implement · **Updated:** 2026-08-15

## Itinerary

| Step | In | Why |
| --- | --- | --- |
| Brainstorm & architecture | no | The framework's shape was settled in phases A-D |
| Business analysis | no | Scope is the v1 checklist, already agreed |
| System analysis | yes | The state model is changing, and it crosses every skill |
| UI/UX design | yes | The itinerary table and the map are the product's surface |
| Build & QA | yes | always |
| Security | yes | The pre-push guard and the study's blinding both touch it |
| Documentation | yes | gate 5 |
| Deploy, monitor & operate | pending | v1 is not tagged |

## In flight

- **2026-08-15, state became per task.** One `sarah/state.md` index plus
  `sarah/state/<branch-slug>.md` per task, created when work starts and deleted
  when it ships. Closes a merge-conflict defect that existed before any sprint
  question was asked, and is what makes more than one task in flight possible at
  all. The session-start hook would have gone silent on the new format and was
  fixed and tested against both. No sprint ceremony was added and none will be:
  that is the board's job.

- Phases A, B, C and D delivered. 15 skills, 10 agents, 3 hooks, one script, ~3,090 tokens always-on. Phase D added CI validation, CONTRIBUTING, issue and PR templates, `docs/extending.md`, both walkthroughs, and a README rewritten around evidence rather than claims. **Phase E is the only thing left before v0.1.**
- The Level 3 pipeline was exercised end to end on 2026-08-05 and held. See *Carried into Phase E* for what it proved and what it did not.
- **2026-08-06, instrumented from step 1 — both open questions settled.** Gate 3 holds: eight test files written, the suite run five times, red every time with `ModuleNotFoundError`, and `src/` holding nothing but a three-line package `__init__`. The specialists fire unprompted: `product-analyst` (brainstorm), `software-architect` + `security-advisor` (architecture), `ux-ui-designer` (design), `test-engineer` + `developer` (implementation). Phase 6 was cut by a session rate limit and resumed, so this is not a clean uninterrupted run; the resumed half spawned no subagent, the orchestrator finished the code itself. Every prompt carried "do not ask me anything", which proves the automatic gates and cannot prove the human ones. Gate 4 stopped the delivery with four blocking findings, including `edit` writing through a symlink to outside the notes directory; the reviewers noted the 147 passing tests covered none of the four. Fixes produced twelve new tests — 159 passing, verified independently — and re-ran the reviewers unprompted. All eight phases completed: `v0.1.0` tagged, CI generated, $39.64 and ~90 minutes end to end. Logs outside the repository.

- **2026-08-09, gate 4 ran on the v2 branch.** `code-reviewer` and
  `security-advisor` in clean contexts, both probing rather than reading: four
  blocking findings each, two of them the same defect found independently. Every
  one fixed and verified by execution — a rate-limited step that wrote
  `COMPLETE` over work that never happened, a packager that crashed mid-sanitise
  on a filename with a space, unvalidated arguments reaching `rm -rf`, symlinks
  carried into judging packets, absolute paths naming the maintainer's machine,
  a not-tested hand-off with no receiver, and a rubric whose evidence described a
  48-point instrument that no longer existed. **The reviewers also cleared the
  branch's main risk:** the four prose changes are purely additive, and nothing
  doing security work was cut by the subtractive pass.
- **The re-review blocked too, and both findings were mine.** The blinding
  substitution only matched dotted capitals, so an ordinary `/sarah-init` shipped
  to judges in plain text while the script exited 0 — I had written the
  case-insensitive fix and then reverted it as out of scope, which it was not.
  And the path fix reached two scripts while three siblings kept the same
  hardcoded home directory; this file claimed the finding was closed while it was
  open in three tracked files. Both fixed. The second round also found hardlinks
  leaking content past the symlink refusal and an unquoted `--plugin-dir`
  expansion that a demonstrated PoC used to inject a flag. **The CI guard was the
  root cause of the path leak**: it hunted only for internal hosting names and
  never looked for a home directory, so it would not have caught the originals
  or a regression. It does now. A third review round is the open item.

  Writing that sentence with the guard's own search terms in it broke CI, which
  is the guard working exactly as intended and worth remembering before quoting
  it again.
- **Round 3 blocked on the same shape a third time.** Rounds 1 and 2 caught the
  blinding check missing content; round 3 caught it missing *names* — a run that
  produced `sarah-notes.md` shipped that filename to a judge untouched, because
  every check read file bodies — and missing *binaries*, which `grep -I` skipped
  in the rewrite and then skipped again in the gate. Names are now rewritten with
  the same token as content, so in-file references still resolve; the final gate
  reads binaries too. Also fixed: a `trap` so an unanticipated failure cannot
  leave an unvalidated packet on disk, and the one real path leak in
  `docs/study/scores/`, scrubbed from a captured pytest `rootdir` line with the
  score, evidence and verdict untouched — which let the CI guard drop its only
  exclusion.
- **Round 4, and the lesson worth keeping from all four.** Three more: UTF-16
  content whose bytes match no ASCII pattern, an extended attribute `cp -a`
  carried across that nothing reads, and a rename that ate the extension
  separator — `sarah.md` became `the frameworkmd` and shipped, because no
  "sarah" remained to trip the gate. **Four rounds, four ways past the same
  gate, every one a check that skipped exactly what it was built to catch.** The
  fixes that never came back are the ones written by exclusion: refuse anything
  that is not a regular file, refuse anything not readable as text, do not
  preserve attributes nobody inspects. The ones that kept failing enumerated
  what to fear. Packets now build under `.building-<label>` and move into place
  in one rename, because a trap cannot catch SIGKILL.
- **Round 5 blocked on a defect the new approach created.** Fixing round 4's
  extension bug left two rewrite expressions where there had been one, and they
  disagreed: `sarah.md` shipped as a file called `the framework.md` whose own
  prose pointed at `the frameworkmd`. No gate caught it, because no "sarah"
  remained to find. **That is the Phase E dangling reference again, through a
  rewrite instead of a deletion** — and the lesson is narrower than the one
  above: the fix was not another check, it was making divergence impossible by
  defining the expression once. Round 5 otherwise came back clean, with the
  security reviewer recommending merge and stating that the script is smaller
  and more defensible than four commits earlier, because the growth is in
  exclusion gates rather than enumerated cases.
- **Residual scope on the packager, accepted and not fixed.** Unicode homoglyph
  and zero-width sequences evade the name gate **and the content gate** — `ѕarah`
  in Cyrillic, a zero-width joiner mid-word, `**s**arah` that renders as the name
  in Markdown. POSIX ACLs survive `cp --preserve=mode`, so a named-user ACL would
  carry a username across; nothing sets one and no agent output does. All of it
  is adversarial evasion, and the risk this instrument actually runs is a coding
  agent accidentally deblinding its own output. Recorded so a future round does
  not rediscover it as new.
- **The two study arms differed by more than the framework.** Found while
  repricing the rubric, not by any instrument. The harness gave the control
  `--setting-sources project` and the framework arm the default, which also loads
  **user** settings — so one arm ran with the maintainer's own `CLAUDE.md` and
  the other did not. Visible symptom: two of three framework-arm artefacts are
  written in Portuguese and none of the control's, which is a confound and a
  blinding leak the sanitiser cannot catch. Fixed for Phase F — both arms load
  the same sources and the framework reaches its arm through `--plugin-dir`
  alone, verified with the harness's own isolation probe. Recorded in
  `docs/study/incidents.md`.
- **2026-08-10, the pre-push guard became versioned.** It lived in `.git/hooks`,
  so it protected one machine and was silent about its own absence in any clone.
  Now in `.githooks/`, enabled per clone with `git config core.hooksPath`, which
  `CONTRIBUTING.md` states as a manual step because git offers no way around it.
  Entry: `sarah/changelog/2026-08-10-versioned-pre-push-guard.md`.
- **2026-08-14, Phase F started and is running unattended.** Six runs in pair
  order against the fixed instruments; the two pre-fix runs from 2026-08-07 were
  archived, not resumed. `sarah-1` passed the isolation probe with the framework
  present. **The framework reaches its arm through a frozen worktree**
  (`--plugin-dir` pointing at a detached checkout of `d95e7e5`), not this working
  tree, so editing the repository during the study cannot contaminate a run.
  Progress in the study base's `logs/orchestrator.log`; finished when
  `logs/STUDY-COMPLETE` exists. Roughly $280 from zero.
- **The isolation probe killed `sarah-2`, and it was the instrument's fault.**
  A session limit answered the probe, the check read "no `sarah-bootstrap` in
  the answer" as "this arm cannot see the framework", and exit 3 is the one code
  the orchestrator will not retry — $12 and 28 minutes of finished work, void.
  The same defect passed silently on the control arm, where an empty answer
  looks exactly like proof of absence. **Fourth instrument bug of this family,
  and the sharpest statement of it yet: an instrument must be able to report
  that it did not measure.** Fixed by exclusion — each verdict needs its own
  affirmative evidence and anything else retries — installed mid-study by atomic
  rename, so the third pair runs with it. Full account in
  `docs/study/incidents.md`.
- **The documented recovery step would have deleted the study.**
  `run-phase-f.sh` archived everything in `runs/` and deleted the per-run logs
  on every start — right for the one-off migration it was written for, and
  `phase-f-resume.md` told the operator to rerun exactly that command whenever
  the orchestrator stopped early. Three finished runs and ~$100 sat behind it
  for a day. **Same shape as the probe, twice in one day: a single-purpose step
  that outlived its purpose while keeping its authority.** Resuming is now the
  default and moves nothing; discarding is `STUDY_ARCHIVE=1` and still moves
  rather than deletes. Verified in a sandbox, both paths. Nothing was lost -
  the orchestrator never died, so the fix landed by inspection rather than after
  a post-mortem.
- **2026-08-15, the three-instrument day closed.** The framework-use counter
  crashed on the one event whose `message` is a string, and `${used:-0}` turned
  the crash into "sarah-3 step 1 invoked the framework zero times - recorded as
  a finding". **Recounted from logs that were never at risk: it is 1, not zero.**
  Every framework-arm step outside step 0 invoked the framework (2/2/2, 2/2/2,
  1/1/1), step 0 counts zero by design because a slash command is expanded
  before it can become a tool call, and every previously recorded number
  reproduced exactly. The finding is withdrawn. The expression now lives once in
  `docs/study/count-framework-use.py`, shared by the harness and any recount; a
  failed count is `COUNT FAILED`, never a number. Original logs kept beside the
  recount as evidence.
- **2026-08-15, the study finished and the framework answered for it.** Six runs
  judged blind, 18 scores: framework 20.7/48 against 19.7 for plain Claude Code,
  at 21% more cost. The rubric discriminated (35-50%, against 43-44 out of 44 in
  Phase E), and the blinding did not hold - a separate reader named all three
  framework artefacts at 87-94% confidence from the scars left by stripping
  their process documents. **Three attempts, three times without a verdict, and
  this time for a design reason rather than an instrument one.** Total US$ 308.63.
- **The README now says all of that**, including that S.A.R.A.H. does not make
  Claude write better code on a well-specified brief. Added: who it is for, who
  it is not for, and the eight-step map with owners.
- **The audit the maintainer asked for found four real gaps, all closed.**
  `test-engineer` was invoked by no skill; observability and rollback existed
  nowhere; no welcome or map was ever shown; gates were numbered in the README
  and unnamed in the phases that enforce them. A fifth suspected gap was a false
  positive - the decision protocol lives in `sarah-bootstrap` and reaches every
  phase from there.
- **Phase F finished: six of six runs, US$ 187.31.** `sarah-2` was rerun from
  zero after the probe defect and matches `sarah-1` step for step. Packaging and
  judging are the remaining work.
- **The `sarah-2` rerun is armed and unattended.** `phase-f/rerun-sarah-2.sh`
  waits for `plain-3`, waits for the orchestrator to exit so it does not compete
  for the session quota, archives the void run rather than deleting it, and
  reruns `sarah-2` from zero with the same rate-limit handling. It calls the arm
  script directly and never the orchestrator, for the reason above. Log in
  `logs/rerun-sarah-2.log`.

## Blocked

- Nothing blocked.

## Pending decisions

Nothing pending. Resolved on 2026-08-05:

| Decision | Outcome |
| --- | --- |
| Second-model CLI for gate 4 | **Claude only.** No second-model CLI will be installed. The fresh-subagent fallback becomes the primary, exercised review path. Runtime detection stays in the framework for users who do run one, but ships unexercised — recorded as a sharp edge, not a tested feature. |
| Repository name | **`sarah-framework`**, matching the plugin's published identity. Renamed and made public on 2026-08-05. No versioned file changed: every URL already used that name. |
| Branching model | **gitflow.** `main` holds released versions, `develop` holds the next one, work happens on `feature/*`, `release/*` and `hotfix/*`. Chosen over GitHub Flow by the maintainer. Recorded in `docs/branching.md`; the push hook already treated `develop` as protected, and the generated README template already parameterised its base branch, so neither needed changing. |

## Gates

| Gate | Status | When |
| --- | --- | --- |
| Spec approved | approved | 2026-08-05 |
| Plan approved | approved | 2026-08-05 |
| Tests written first | n/a | Phase A ships no executable code beyond one hook, exercised across eight scenarios |
| Review passed | approved | 2026-08-09 — six rounds on `feature/framework-v2-lean`, returning 7 findings, then 2, then 5, then 3, then 1, then **clean**. Both `code-reviewer` and `security-advisor` signed off on round six, each verifying by execution. Phase C remains signed off from 2026-08-06. |
| Documentation done | done | 2026-08-09 — `README.md` corrected to state both reasons Phase E was inconclusive, changelog entry written, `ARCHI.md` unchanged because the architecture did not move: v2 changed what the gates do, not what the components are. |

## Publication

The repository is **public**. It mirrors automatically, so a push is a publish.
Commit freely; push only on an explicit decision. Nothing versioned here may
reveal the maintainer's internal infrastructure — clone URLs, badges, issue
links, and CI all reference GitHub and nothing else.

## Next

**Working plan agreed 2026-08-15. Items 1-6 are one pass of documentation
alignment; item 7 is a product decision and deliberately separate.**

1. **Done 2026-08-15 — `docs/study/results-phase-f.md`.** Six runs, 18 blind scores,
   20.7/48 against 19.7, +21% cost, the section-level pattern, and the blinding
   check that named all three framework artefacts at 87-94%. Three attempts,
   three times without a verdict, and this time by design rather than by
   instrument.
2. **Done 2026-08-15 — `docs/quality-gates.md` gained observability.** Gate 5 now includes the
   release being observable and reversible, scaled by level.
3. **Not applicable, checked 2026-08-15.** `ARCHI.md` describes the plugin's
   structure, not the individual phases; adding a deliverable to an existing
   phase moved nothing in it. Recorded rather than edited, because a documentation
   gate satisfied by a cosmetic edit is worse than one honestly marked n/a.
4. **Done 2026-08-15 — "How it compares" stopped saying the comparative evidence does
   not exist.** It exists, it is ours, and it does not favour us.
5. **Done 2026-08-15 — the Level 3 walkthrough says what a user sees today**
   that the recorded run did not show, rather than being rewritten to claim a
   run that never happened. The Level 1 walkthrough needs no change: it predates
   nothing that moved.
6. **Done 2026-08-15 — `sarah-status` prints the eight-step map with the
   current position marked**, collapsing to one line at Levels 0-1.
7. **Superseded 2026-08-15 — the phase fusion is off.** The maintainer chose the
   better answer: instead of the framework merging four phases for everyone
   forever, **the user picks the itinerary per request**. Same cost saving for
   whoever wants it, no capability removed from anyone, and it follows the
   principle the framework already sells. At Level 2+ work opens with all eight
   steps as a table - in or out, the reason drawn from *this request*, the cost
   in the user's time - and any row can be overruled. Dropping is recorded, not
   argued with; documentation is the one row that cannot be dropped. Criteria in
   `skills/sarah-bootstrap/references/itinerary.md`, loaded only when the table is
   built, so the session budget carries the instruction and not the reasoning.
   `sarah-bootstrap` now sits at ~1,822 tokens against 2,000.
8. **Done 2026-08-15 — state is per task now.** Was: S.A.R.A.H. had no answer for a sprint. The state
   model is single-track by construction - one `sarah/state.md`, one **Current
   task**, one phase - and that file is versioned and rewritten continuously (31
   commits so far). Two features in parallel means two divergent state files and
   a merge conflict on every branch, which is a defect today and not only under
   a sprint. Nothing in the framework describes more than one task in flight.
   Decide before v1.

**The eight steps are documented in three places and must stay in agreement:**
`README.md` (§The workflow), `skills/sarah-init/SKILL.md` (step 0 welcome), and
`skills/sarah-bootstrap/SKILL.md` (the routing ladder). A change to one is a
change to all three.
