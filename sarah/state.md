# S.A.R.A.H. state

**Updated:** 2026-08-09

| | |
| --- | --- |
| **Phase** | 5-implement |
| **Default level** | 3 |
| **Mode** | greenfield |
| **Current task** | Framework v2 on `feature/framework-v2-lean`: five review rounds, each blocking, all findings fixed; sixth round pending. Phase F study paused at 2 partial runs |
| **Task level** | 3 |

## In flight

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
| Review passed | **open** | 2026-08-09 — five rounds on `feature/framework-v2-lean`, each returning **changes required**: 7 findings, then 2, then 5, then 3, then 1. All fixed; the fixes from round 5 have not been reviewed. Round 5 was clean on the security side, which recommended merge. The gate does not close until a round comes back clean. Phase C remains signed off from 2026-08-06. |
| Documentation done | done | 2026-08-05 |

## Publication

The repository is **public**. It mirrors automatically, so a push is a publish.
Commit freely; push only on an explicit decision. Nothing versioned here may
reveal the maintainer's internal infrastructure — clone URLs, badges, issue
links, and CI all reference GitHub and nothing else.

## Next

1. **Re-review the fix commits on `feature/framework-v2-lean`, then merge.** Gate 4 ran and blocked; the fixes are committed on the same branch and have not themselves been reviewed. No merge until they pass. The documentation gate then needs a changelog entry for the delivery.
2. **Resume the Phase F study** — see `docs/study/phase-f-resume.md`; the harness takes `STUDY_BASE` rather than a hardcoded path. Two runs are partial (build step only) and resume from where they stopped. Roughly $280 to finish.
3. **Decide what an inconclusive Phase E means for v0.1.** The comparison ran, cost $280.76, and could not discriminate: the rubric saturated at 43-44 out of 44 for every artefact in both arms. Options are to ship v0.1 with the study published as the honest inconclusive result it is, or to build a discriminating rubric and re-run before releasing. This is the maintainer's call and nothing should move until it is made.
4. **Make the framework's output to the human short.** Every skill that reports
   back — `ill-be-back`, `sarah-status`, the phase skills, the review gate —
   should summarise rather than narrate: tables where a table fits, the decision
   the human has to make stated as a decision, and what to do next. Long reports
   are how a thirty-second instrument becomes one nobody runs. Raised by the
   maintainer 2026-08-09 against this session's own output, which is the
   evidence: the framework produced exactly the wall of prose it warns against.
5. Then v0.1: decide whether to push. The repository is public and mirrors automatically, so the first push is the publication.

## Carried forward

- **The Level 3 pipeline runs end to end, and the two open questions are closed.** Exercised twice: 2026-08-05 uninstrumented from step 1, and 2026-08-06 instrumented throughout. Gate 3 holds and gate 4 stops deliveries; every phase spawns its own specialists without being asked. What each run could and could not prove is recorded in `sarah/changelog/2026-08-05-level-3-pipeline-verified.md` and `sarah/changelog/2026-08-06-level-3-instrumented.md`. **What no run has proven:** the human gates, because headless prompts must say "do not ask me anything"; and whether the framework's contribution is separable from the model's, which is what Phase E exists to measure. Evidence in the run logs, outside the repository.
- **Framework v2 exists but is unproven.** `feature/framework-v2-lean` rewrites the review gate to probe with hostile input and rehearse a cold start, refuses README-not-run and production test seams, cuts phase-boundary ceremony, and keeps three artefacts an independent analysis found genuinely valuable: invariants stated with the consequence no test would catch, superseded decisions with their reason, and the deliberately-not-tested list. Whether any of it helps is exactly what Phase F was started to measure, and Phase F is paused.
- **Three instrument bugs of my own, all the same shape.** The blinding sanitizer deleted whole lines and truncated prose in one arm only (~15% of the evidence base). The harness treated a rate-limited step as complete, so one artefact was judged having never had a review. And a framework-use check counted tool calls, but slash commands are expanded before becoming tool calls - it voided a valid run. The pattern: **my own spot checks are less trustworthy than the instrumented procedure, and when they disagree the procedure wins unless I can show otherwise.**
- **The evidence study ran and could not discriminate — for two independent reasons.** Six builds of one brief, three per arm, eighteen blind scores, $280.76. Every artefact scored 43-44 out of 44, so the rubric had no room to record a difference. And the arms were confounded: the control ran without the maintainer's user settings and the framework arm ran with them, so the comparison was framework-plus-personal-context against a bare CLI. The second reason is the more serious — a saturated instrument measures nothing, but a confounded one measures the wrong thing while looking like it worked. Inconclusive about the framework in both directions. One finding stands on its own: on the four security requirements the brief never states, plain Claude Code scored full marks in all three runs. Cost and its variance are the reliable measurements - the framework arm spread 2.7x against the control's 1.06x. Full writeup in `docs/study/`.
- **`sarah-bootstrap` sits at ~1,574 tokens against its own 2,000 ceiling**, measured 2026-08-06. Anything added there still costs every session, so additions stay in words rather than lines.
- **Gate 5 now requires a commit, and nothing enforces it at runtime.** Three instrumented runs ended implementation with a passing suite and no commits — the third collapsed eight phases into three commits at release time, one of them 2,849 lines with the review fixes fused into the code under review. The gate was rewritten and all seven phase skills now close their own loop. The framework is prose a model reads: whether phase-closing commits actually happen is measurable only by instrumenting another run, and that measurement is now part of what Phase E has to report.
