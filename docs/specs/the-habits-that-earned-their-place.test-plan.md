# Test plan - the habits that earned their place

**Date:** 2026-10-24 - **Level:** 3 - **Status:** proposed, for Gate 4 - **Inputs:** [spec](the-habits-that-earned-their-place.md) R1-R24, [architecture](the-habits-that-earned-their-place.architecture.md), [UX](the-habits-that-earned-their-place.ux.md), ADR-006 to 010

## 1. Starting point and shape

No test harness exists (no `tests/`; `scripts/` holds `token_budget.py` and `allowed-hosts.txt`). CI runs only static guards (JSON, `sh -n`, no `exit 1+`, frontmatter, size ceilings, host and home-path allowlists). Nothing executes a hook or script.

Most of v0.2.0 is prose a model reads. The testable edge is the plugin hooks, `habits.py`, `tracker.py`, the installed blocking hooks, and the limits the copy must respect. Risk sits at boundaries (user files, settings, Trello, git, gh), so integration weighs as much as unit. Counts are test functions.

| Layer | New tests | In CI |
| --- | --- | --- |
| Static checks | 13 | yes |
| Unit (`unittest`, POSIX sh) | 61 | yes |
| Integration (temp git repos, stub HTTP server, real PreToolUse JSON) | 62 | yes |
| End to end (`claude -p`) | 3 + 1 sampling | no, manual before release |

**Layout:** `tests/{unit,shell,integration,fixtures,e2e}/`. Plain sh with a small assert helper (no bats); Python standard library only. Run `python3 -m unittest discover -s tests` and `sh tests/shell/run.sh`.

**Seams required of the implementation:**
1. `SARAH_TODAY` (ISO date) read by hooks and `tracker.py`. Without it, expiry tests break at midnight.
2. Tracker base-URL override, honored only for a loopback host. A free override lets a repo setting redirect the token.
3. `SARAH_FAIL_AFTER=n` in `habits.py apply`, to simulate a crash.
4. Hooks find `jq` and `gh` through `PATH` only, so tests can shadow or remove them.
5. `Agent` PreToolUse fixtures are **captured by the P2 probe**, not invented. Fixtures carry no home paths or real hosts (CI guards cover `tests/`).

## 2. Depth options

| Depth | Scope | Tests | Residual risk |
| --- | --- | --- | --- |
| A, full (recommended) | all below | about 140 | the not-tested list |
| B, security core | A minus parametrized variants, UX lints, workflow-script logic | about 95 | copy drift, command-parsing variants |
| C, minimum | exit-0 fuzz, size sensor, exception window, containment, tracker 401 and canary, install-remove | about 45 | installer conflicts, Stop hook, dispatch guard |

Recommend A, built in the section 8 order so B exists first. The blocking hooks and installer write into a user's project, where a defect is silent.

## 3. Static checks (S)

| ID | Check | Req |
| --- | --- | --- |
| S1 | `conversation-defaults.txt` at most 200 tokens (chars/4) | R1-R7 |
| S2 | No dead `references/` links in any SKILL.md | R23 |
| S3 | `sarah-bootstrap/references/task-template.md` exists, `templates/` symlink resolves, no stale path in `sarah-init`, template has executor table and Premises | R23, R10, R15 |
| S4 | Panel limits on every JSON block in the catalog and `sarah-init`: label 40, description 200, question 120, at most 4 questions and options, `None of these` last, `(Recommended)` literal | R1, R8 |
| S5 | Banned words absent from labels and descriptions (worktree, WIP, gitflow, CI, hook, manifest, executor, premise, rule IDs...) | R4 |
| S6 | Anchor sentences in `tests/fixtures/ux/` appear verbatim in shipped skills (copy drift) | R4, R21 |
| S7 | Fixture shape: first line `Decision needed: ...` or `No decision needed...`, at most 10 lines of 110 chars, allowed lead words | R4, R21 |
| S8 | `ill-be-back` body at most 30 lines, `hasta-la-vista` 35, `sarah-init` +40 over v0.1.0 | R20, R21 |
| S9 | `agents/executor.md`: allowed frontmatter only, one new agent, four report sections named | R10, R11 [P1] |
| S10 | `executor-brief.md`: three depths; no `tracker.py` or `TRELLO_`; untrusted-block rule present | R11 |
| S12 | `sarah-gitflow.yml`: `pull_request` only, top-level `contents: read`, no secrets, `uses:` SHA-pinned | R13 |
| S13 | Payload scripts: `sh -n`, `dash -n`, `shellcheck -s sh`, exit codes only 0 or 2, stamp header | R13-R17, R24 |
| S14 | Five commands only; plugin `hooks.json` has no `Stop` hook; no plugin script exits 2 | Q3 |

`api.trello.com` and `trello.com` must be added to `scripts/allowed-hosts.txt` (a reviewed change) or the host guard fails.

## 4. Unit tests

| ID | Behavior | N | Req |
| --- | --- | --- | --- |
| UH1 | `habits.py`: stamp is habit, version, sha256; hash excludes the stamp | 1 | R22 |
| UH2 | `plan` writes nothing; declining all gives an empty plan | 2 | R8 |
| UH3 | Settings merge keeps user keys, order, hooks; applied twice is byte-identical | 3 | R20 |
| UH4 | Settings absent, empty, invalid, BOM: never clobbered | 2 | D3.1 |
| UH5 | Entries identified by command path; remove drops only ours | 2 | R22 |
| UH6 | Never writes `allow`; `ask` rules only tighten | 1 | D9 |
| UH7 | Attribution: default writes the off value; yes writes nothing | 2 | R13 |
| UH8 | Manifest round trip; malformed row ignored with one line | 2 | R8 |
| UH9 | **Containment:** `..`, absolute, symlink, outside-prefix paths refused on remove | 3 | R22 |
| UH11 | Classifier: match, stamped-edited, unstamped, absent; habit name from a fixed set | 1 | D3.1 |
| UH12 | Sockets patched to fail across the suite (no network) | 1 | D3.1 |
| UT1 | `tracker.py`: dispatch by key; unknown key is a clear error | 2 | D4 |
| UT2 | Credential from env; missing; keychain lookup variant | 3 | R9 |
| UT3 | **Canary token in no repr, exception, log or message**, every error class | 1 | inv. 7 |
| UT4 | 401, 403, 404, 429, 5xx, malformed body each map to one outcome | 3 | R9 |
| UT6 | Untrusted framing: card text cannot forge the delimiter; control and ANSI characters; truncation | 3 | 5.6 |
| UT7 | Audit diff: moved by hand, missing card, orphan, empty both sides, duplicate rows | 4 | R12 |
| UT8 | Audit due: same day, next day, never run, injected clock, midnight | 3 | R12 |
| UT10 | Sync keyed by card ID; `Card: pending` created on next sync | 2 | R9 |
| US2 | Not a S.A.R.A.H. project: silent. `habits.md` missing, malformed, huge, unreadable, CRLF: v0.1.0 output plus defaults | 3 | R8 |
| US3 | One-line habit summary (`Habits: none`); each default toggle removes its line | 2 | R8, R1-R7 |
| US4 | **Size sensor:** index 8,191 / 8,192 / 8,193 bytes, task 16,384 / 16,385; odd names; snooze marker today, yesterday, malformed | 3 | R19 |
| US6 | **Worst-case output (every line present) at most 400 tokens** | 1 | inv. 9 |
| US7 | Fields from `habits.md` whitelisted, never echoed raw (newlines, instructions in a reason) | 1 | 5.6 |
| US8 | `source: compact` prints the same as startup | 1 | R1-R7 [F10] |
| US9 | **Exit 0 on every path**, all plugin hooks: empty, invalid, huge stdin; no jq; missing env; bad cwd | 2 | invariant |
| US10 | **Exception window:** valid; expiry day inclusive; yesterday; grant after today; over 14 days; empty reason; `2026-02-30`, `tomorrow`, CRLF; `\|` in reason | 6 | R16 |
| US11 | In-flight counter agrees with session-start on header, separator, template rows | 1 | R17 |


## 5. Integration tests

**Installer, temp git repo (IN)**

| ID | Scenario | N | Req |
| --- | --- | --- | --- |
| IN1 | Fresh install of each habit: files, modes, stamps, settings, manifest; `status` lists exactly the chosen set (6 habits) | 1 | R8, R20 |
| IN2 | Decline all: tree byte-identical | 1 | R8 |
| IN3 | Re-install: tree and mtimes identical | 1 | R20 |
| IN4 | Re-install after user edited a stamped file: asks, content kept | 1 | D3.1 |
| IN5 | Unstamped file at target: adopt, wrap, skip; user file byte-identical | 3 | edge |
| IN6 | Remove, files unchanged: files, settings entries, manifest rows gone | 1 | R22 |
| IN7 | Remove with an edited file: kept, unmanaged | 1 | R22 |
| IN8 | **Install then remove restores the tree**, with pre-existing settings, hook, workflow | 1 | R22 |
| IN9 | No git, no remote, no gh: dependent habits refused in the script, others work | 2 | edge |
| IN11 | Failure and crash mid-apply: no half state; re-run converges | 2 | D3.1 |
| IN12 | Tree change after `apply` equals what `plan` listed | 1 | D3.1 |
| IN13 | Symlinked target escaping the project refused | 1 | security |
| IN14 | `git worktree add` has hooks and `habits.md`; recorded check runs | 1 | R17 |
| IN15 | User's own `worktree.baseRef` or `attribution` is a conflict | 1 | D3.1 |

**Tracker against a loopback stub, never real Trello (IT)**

| ID | Scenario | N | Req |
| --- | --- | --- | --- |
| IT1 | `check`: private board connects; public board refused; override loopback only | 2 | R9, 5.6 |
| IT2 | **401: one request, one status, distinct exit code, no retry** | 1 | edge |
| IT3 | Credentials absent: zero requests | 1 | edge |
| IT4 | Refused connection; server that never answers: returns within timeout | 2 | edge |
| IT5 | **Redirect to another host not followed** | 1 | 5 |
| IT6 | 5xx, 429, HTML on 200, truncated JSON: no loop | 1 | edge |
| IT7 | Hostile cards: framed as untrusted data, delimiter neutralized | 1 | 5.6 |
| IT8 | Sync twice, one card; card deleted on board reported, not silently recreated | 2 | R9 |
| IT9 | Server creates card then drops connection: no duplicate next sync | 1 | edge |
| IT10 | Audit: day 1 creates, day 2 updates (one card), clear archives, relapse one card | 1 | R12 |
| IT12 | **Canary over the whole run:** not in stdout, stderr, files, error URLs; only toward the stub | 1 | inv. 7 |

**Installed blocking hooks, real PreToolUse JSON (IH).** Each runs the exact command string from the generated `settings.json`, in a temp repo, with a stub `gh` on `PATH`.

| ID | Scenario | N | Req |
| --- | --- | --- | --- |
| IH1 | Works from a subdirectory cwd (a relative path would fail open, exit 127) | 1 | D3.2 |
| IH2 | `echo "git commit"` allowed (bypasses like `sh -c` untested). Commit or push to `main` or `develop`: 2; `feature/x`: 0; variants `-C`, `-am`, chained, env prefix, `HEAD:main`, `--force`, bare push | 3 | R13 |
| IH4 | `gh pr merge`: green 0; red, pending, none 2; gh missing, failing, garbage: allow plus not-checked line; hanging gh returns | 3 | R13 |
| IH6 | R14: fragment missing, placeholder, present, deleted, base unknown offline | 3 | R14 |
| IH7 | Dispatch guard: other agents untouched; no model; limit-1 and limit; bad limit; template rows uncounted | 4 | R10, R17, R18 [P1, P2] |
| IH8 | Premise check fresh, stale, absent | 2 | R15 [P2] |
| IH9 | Stop hook blocks once with ready work; allows on `stop_hook_active`, waiting task, marker, nothing ready, no index | 4 | R24 |
| IH10 | Exception honored and logged; refused if expired, no reason, malformed, over 14 days, other rule; log unwritable | 4 | R16 |
| IH11 | Fuzz (empty, invalid JSON, 1 MB command, no jq): only 0 or 2, never 1 | 2 | invariant |
| IH12 | Block message names rule and exception path; not-checked line matches UX text | 1 | R13, R16 |
| IH13 | PR base breaks the branch model; workflow check script against base and head refs | 3 | R13 |

Totals: IN 18, IT 14, IH 31 = 63.

## 6. End to end (manual, recorded)

`claude -p` detached, `--output-format stream-json --verbose`, run from a persistent directory outside the repo and outside `/tmp`, instrumented from the first run. Only a scrubbed summary is committed; raw logs hold local paths the CI guard forbids. Three runs each; gate on structure only.

| ID | Scenario | Asserts |
| --- | --- | --- |
| E1 | `/sarah-init` on a fresh git project; answers as text in a `--resume` turn | Panel shape; question count within the UX budget; no continuation question; first-line rule; `plan` before `apply`; base files written |
| E2 | Re-run `/sarah-init` | Clean `git status`; no answered question re-asked |
| E3 | Decline everything | Tree equals v0.1.0 output plus `sarah/habits.md` |
| E4 (info) | Trigger sampling: "remove the release-note habit", "add the Trello board", "make an exception", 5 more | `Skill` call to `sarah-init` seen; a rate, never a gate |

**Proves:** skills drive the installer in order; panel structure; idempotent re-run; no continuation question in a sampled run. **Cannot prove:** triggering in general; cross-session memory; unattended runs; how a human answers. Open point O1: `AskUserQuestion` may not work under `-p`; then E1 sees the attempted call and the next turn carries answers. Verify first.

## 7. Platform probes: dependent tests

| Probe | Fact | Waiting tests | If it fails |
| --- | --- | --- | --- |
| P1 per-call effort | F3-F5 | S9, S10, IH7 effort check | D1 falls to one file per effort; rewrite S9, S10 |
| P2 `Agent` hook input | F16 | IH7, IH8, dispatch fixtures | No hook for R10, R15, R17; they leave this plan, R17 advisory |
| P3 model self-report | F17 | "Ran on <model>" fixture in S6 | The line cannot be truthful; drop it |
| P4 ask rules, permissive modes | F18 | none (UH6, IN1 check entries only) | "Always asked" becomes advisory |

## 8. Order and "red first"

1. US9, US4, US6, S1, S13, S14. 2. UH9, IN8, US10, IH10. 3. UT3, IT2, IT5, IT12. 4. The rest. 5. S4-S8. 6. E2E.

Every test first runs against an empty stub and must fail for its stated reason. For UH9, US10, IT2, IT5, IH10, flip one operator (`<=` to `<`, drop containment, add a retry, follow redirects) and confirm red.

## 9. Not tested, and what covers it

| Item | Why | Covered by |
| --- | --- | --- |
| A skill triggers | Model-dependent | CLAUDE.md description rule; E4, informational |
| Model obeys "no continuation questions" (R2), "zero non-gate questions" (R7) | Behavior | S1, E1 transcript scan, remeasure the pilot's 104-of-855 ratio after release |
| Rituals fit 10 lines (R21); R3, R5, R6, R1 outside the catalog | Model output and behavior | S7 on contract fixtures; one seeded E2E sample; R6 across sessions has no test |
| Live Trello | Real account, API drift | Stubs; one manual smoke on a throwaway private board in the release checklist |
| Agent writes exceptions or grants only on user instruction | Prose; a hook cannot see the author | Cap, log, fail-closed parsing limit damage. **A forged row is not preventable by test**; consider an `ask` rule on `sarah/habits.md` |
| Injected text steering an executor | No oracle | S10; manual hostile-card red-team; residual risk in 5.5 |
| Platform facts F6, F8, F9, F12 | Claude Code's | Docs; we test exit 2 and stderr only |
| Windows (CRLF alters stamped hashes); concurrent sessions | No runner; left open in section 7 | `.gitattributes` `eol=lf` for `sarah/hooks/*.sh`; macOS via CI matrix |
| `claude plugin validate --strict`, hook latency, plain-language quality | CLI, machine, judgment | PR checklist, Gate 4 review |

## 10. Findings about the spec as written

1. **R10 is not enforceable as specified.** The guard checks `model` only, and nothing binds a dispatch to its task row. "Cannot move to in progress" is model behavior.
2. **R15 does not define "current".** No staleness window, no Premises format. IH8 needs both.
3. **R24 says "tracker or index".** A Stop hook cannot call Trello: index only. The stop marker needs a session-scoped lifetime.
4. **Merge authority is unenforced.** D8 allows `feature/*` into the integration branch only, but IH4 checks CI alone. Block bases of `main`, or call it advice.
5. **R13 "red CI" omits pending and none**; tests assume both block. `git merge` and the web UI bypass a `gh pr merge` match; CI is the backstop.
6. **R12 says issue, design says archived card.** Tests follow the design.
7. **Tracker gaps:** 429, timeout, redirect, lost-response duplicates unspecified; query-string credentials leak into error URLs (check for header auth).
8. **The manifest is a committed file** and remove deletes what it names; the architecture should require containment (UH9).
9. **Exception log unwritable:** honor or fail closed? Decide.
10. **Stale fact:** architecture D6 gives `sarah/state.md` as 8,768 bytes; it measures 3,545 now. "8 KB" is taken as 8,192 bytes.

## 11. CI changes

Add a `tests` job to `validate.yml` (also reached by `workflow_call`): unittest, shell tests under `dash`, `shellcheck -s sh`, the S checks. Run shell tests on `ubuntu-latest` and `macos-latest`; the hooks promise macOS. Declare a minimum Python and test on it. E2E stays out: it needs a model credential, costs money, is nondeterministic.
