---
name: sarah-init
description: Set up S.A.R.A.H. in a project. Detects whether the repository is greenfield or brownfield, classifies its scale level, and generates ARCHI.md, README.md and sarah/state.md through an interview. Use when the user runs /sarah-init, says "set up sarah", "initialize sarah", "start using this framework here", "onboard this repo", or asks to begin structured development in a project that has no sarah/state.md yet. Also use when another S.A.R.A.H. skill finds the project uninitialized.
---

# /sarah-init — establish the mission

Be prepared. Judgment Day is a deploy on Friday.

This runs once per project. It ends with three files on disk and a user who knows what they are for. It is an interview, not a form: ask, offer options, let the user decide, then draft.

## Step 0 — Refuse to clobber

If `sarah/state.md` already exists, this project is initialized. Do not overwrite it. Report the current phase and level, and offer three choices: leave it alone, refresh `ARCHI.md` against the current codebase, or start over from scratch with the old files backed up. Wait for the answer.

## Step 1 — Read the ground

Run these before asking the user anything. Their time is worth more than your questions.

```bash
git log --oneline 2>/dev/null | wc -l          # commits: 0-2 suggests greenfield
ls -A                                           # manifests, config, existing docs
git ls-files 2>/dev/null | wc -l                # tracked files
```

Then look for what the project already declares about itself: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `Gemfile`, `composer.json`, `*.csproj`, and any existing `README.md`, `CONTRIBUTING.md`, or `docs/`.

**Classify the mode:**

- **Greenfield** — no source files, or only scaffolding, or fewer than three commits.
- **Brownfield** — real code exists and has history.

When brownfield, open with exactly this, once:

> I know your codebase. I've been watching it.

Then say what you actually found — the stack, the shape, the entry points — in three or four lines. The line above earns its keep only if the analysis behind it is real.

## Step 2 — Interview

Ask only what you could not read from disk. Every question you can answer yourself is a question you must not ask.

**Both modes:**

1. What is this project, in a couple of sentences? (Skip if an existing README already answers it — read it back and ask for confirmation instead.)
2. Who uses it?

**Greenfield only:**

3. Stack. Do not ask an open question here — propose. Present two or three viable stacks with honest trade-offs for *this* project and a recommendation with reasons. The user picks or overrides.
4. Is anything already decided and non-negotiable? Deployment target, existing infrastructure, team constraints, a language the team already knows.

**Brownfield only:**

3. Confirm the stack you detected, and ask what you got wrong.
4. What hurts today? The answer becomes the first entries in the `Sharp edges` section of `ARCHI.md`, and it is usually the most valuable thing in the file.
5. Which parts must not be touched without discussion? These become `Invariants`.

Follow the protocol on every one of these that involves a choice: **ask → present 2–3 options with trade-offs and a justified recommendation → the user decides → draft → the user approves.** The machines propose. The human decides. No exceptions.

## Step 3 — Set the scale level

Propose a level with your reasoning, and let the user correct it. Do not simply assign one.

| Level | For | What it turns on |
| --- | --- | --- |
| **0** | Trivial changes | Nothing. Straight to code. |
| **1** | Bug fixes, small features | Mini-plan, implement, review. |
| **2** | Medium features | Lean spec, plan, test-first, full review, documentation gate. |
| **3** | New products, large features | The whole pipeline, every gate. |

The level is per task, not per project. What gets recorded now is the project's **default** — the starting point when a new request arrives and nobody has said otherwise. A Level 3 project still fixes typos at Level 0.

Recommend by honest default: a new product is Level 3, an existing codebase receiving ordinary maintenance is Level 1, and a codebase about to receive a significant feature is Level 2.

## Step 4 — Generate

Templates ship alongside this skill. Read them with paths relative to this file, exactly as written here — never as an absolute path, and never through `${CLAUDE_PLUGIN_ROOT}`. An installed plugin cannot read files outside its own directory, so an absolute path fails at exactly the moment it matters:

- [references/ARCHI-template.md](references/ARCHI-template.md)
- [references/README-template.md](references/README-template.md)
- [references/state-template.md](references/state-template.md)

**Read each template with the Read tool before writing the file it produces.** Do not generate from memory or from the descriptions in this skill. A template is a structure to be filled, not a description to be paraphrased — and paraphrasing it is the single most likely way this step goes wrong.

Filling a template means, exactly:

1. **Reproduce every heading verbatim and in its original order.** Do not rename, merge, reorder, or invent headings. The structure is the product; the prose is the filling.
2. **Replace `{{PLACEHOLDER}}` markers with real content**, or delete the row or section entirely when it does not apply. No `{{` may survive.
3. **Delete every HTML comment.** They are authoring guidance for you, not content for the user. No `<!--` may survive — and never write comments of your own to replace them.
4. **Write in the project's language.** If the project's code, documentation, and team work in something other than English, generate in that language: translate the headings, keep the structure. Structure is fixed; language is the user's.

**`ARCHI.md`** from `references/ARCHI-template.md`.

Greenfield: fill what the interview established — purpose, stack, intended shape, decisions already made. Leave sections you genuinely cannot fill yet marked as pending rather than guessed. An honest gap is worth more than a plausible fabrication, and this file is about to become the project's memory.

Brownfield: fill it from the code you actually read. Trace one real request end to end for the `How a request flows` section — this single trace teaches more than any component list. Populate `Sharp edges` and `Invariants` from the interview.

**`README.md`** from `references/README-template.md`. If a README already exists, do not overwrite it: restructure it to the template, preserving every piece of real content, and show the user the diff before writing. Someone wrote those words on purpose.

**`sarah/state.md`** from `references/state-template.md`. Set phase, default level, mode, and the date. Leave the gate and decision sections empty — they fill in as work happens.

**`sarah/changelog/`** — create the directory with a `.gitkeep`.

## Step 5 — Verify your own output

Before reporting success, check the files you just wrote:

```bash
grep -c '<!--' ARCHI.md README.md sarah/state.md   # must be 0 everywhere
grep -n '{{' ARCHI.md README.md sarah/state.md     # must return nothing
```

Then confirm against the templates you read that every heading survived, in order. A non-zero count or a missing section means you paraphrased instead of filling. Fix it before continuing — do not report a file as written when it does not match its template.

## Step 6 — Confirm and hand over

Show the user what was written, as a short list of paths with one line each. Then state the size of `ARCHI.md` against its budget: the hard ceiling is 10% of the context window, and `/sarah-compact` measures and compacts it when it drifts.

Close with what happens next: the phase they are now in and the first real task. Do not send them off to run another command — the phase skills fire on intent, so the honest instruction is simply to describe what they want to build next. Only five commands exist, and `/sarah-init` was one of them.

## Guardrails

- Do not write a single file before the user has approved the plan for it.
- Do not generate an `ARCHI.md` full of confident guesses. Unknown is a valid value.
- Do not produce documentation the project has not earned. A three-file project does not need an ADR directory yet.
- Do not ask a question whose answer is in the repository.
