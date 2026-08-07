<!--
  TEMPLATE: ARCHI.md — long-term architecture memory.

  /sarah-init copies this to the project root and fills it in. Strip every HTML
  comment from the generated file: they are authoring guidance, not content.

  Three rules govern this file. They are not style preferences.

  1. CURATED, NOT GENERATED. This is not a dump of the codebase. It is the
     map a new senior engineer would want on day one: what this system is,
     how its pieces relate, what was decided and why, what must stay true.
     If a fact is cheaply rediscoverable by reading one file, leave it out.

  2. SIZE IS A CONTRACT. Hard ceiling: 10% of the context window. Practical
     target: under ~400 lines. Run /sarah-compact to measure and compact.
     A bloated ARCHI.md defeats its own purpose — it gets skimmed instead of
     read, and then it stops being trusted.

  3. UPDATED IN THE CYCLE, NOT AFTER IT. Any architectural change updates this
     file before the merge gate closes. Documentation is part of done.

  Delete sections that do not apply to this project. An empty section is worse
  than an absent one: it costs tokens and teaches nothing.
-->

# Architecture — {{PROJECT_NAME}}

> Long-term architecture memory. Read at the start of every task, updated at the
> end of every architectural change. Curated by hand, never auto-generated.

**Last updated:** {{DATE}} · **Scale level:** {{LEVEL}} · **Mode:** {{greenfield|brownfield}}

---

## 1. What this system is

<!--
  Two to four sentences. What it does, who uses it, what problem it solves.
  Someone who has never seen the repository should understand the purpose
  before reading any code. No marketing language.
-->

{{ONE_PARAGRAPH}}

## 2. Stack

<!--
  Only what is actually in use. Include versions where a version is load-bearing
  (a major runtime, a framework with breaking changes between majors). Omit
  transitive dependencies.
-->

| Layer | Technology | Notes |
| --- | --- | --- |
| Language / runtime | {{}} | |
| Backend / core | {{}} | |
| Frontend | {{}} | |
| Data store | {{}} | |
| Tests | {{}} | |
| Build / infra | {{}} | |

## 3. System shape

<!--
  The component map: the handful of parts that matter and how they relate.
  Prefer a short list with one line of responsibility each over a diagram that
  goes stale. If a diagram earns its place, keep it in Mermaid so it lives in
  version control and diffs like text.

  Rule of thumb: if this section lists more than ~10 components, the system has
  a layer you have not named yet. Name the layer, nest the detail under it.
-->

- **{{Component}}** — {{single-sentence responsibility}}. Lives in `{{path}}`.
- **{{Component}}** — {{single-sentence responsibility}}. Lives in `{{path}}`.

### How a request flows

<!--
  Trace one representative operation end to end. This single trace teaches more
  about the architecture than any component list. Pick the most common path.
-->

{{TRACE}}

## 4. Data and state

<!--
  Where state lives and who owns it. The main entities and their relationships,
  not the full schema — the schema lives in migrations and is authoritative
  there. Note anything surprising: denormalization, caches, eventual
  consistency, data that must never be logged.
-->

{{DATA_MODEL}}

## 5. Boundaries

<!--
  Everything this system talks to that it does not control: third-party APIs,
  other internal services, message brokers, payment providers, auth providers.
  For each: what it is used for, and what happens when it is unavailable.
  Failure behavior at a boundary is architecture, not an implementation detail.
-->

| Boundary | Used for | Failure behavior |
| --- | --- | --- |
| {{}} | {{}} | {{}} |

## 6. Decisions

<!--
  One line per decision, newest first. Full reasoning lives in the ADR — this is
  an index, not a copy. A decision belongs here when reversing it would be
  expensive, or when a newcomer would otherwise be tempted to undo it.
-->

| # | Decision | Why, in one line | ADR |
| --- | --- | --- | --- |
| {{001}} | {{}} | {{}} | [ADR-001](docs/adr/001-{{slug}}.md) |

## 7. Invariants

<!--
  Things that must stay true. These are the guardrails that survive refactors,
  and the most valuable lines in this file: they are exactly what an agent or a
  new contributor would otherwise violate without knowing it.

  State each one as a rule, and say what breaks if it is violated.

  The consequence is the part that earns its keep, and the most valuable one to
  write down is the failure no test would catch. "Violating this breaks the
  build" needs no invariant - the build already says so. "Violating this
  silently drops one sender's deliveries as duplicates of another's, and with a
  single sender configured no test notices" is the line that saves someone a
  week.
-->

- {{Rule.}} Violating this {{consequence, ideally one no test would catch}}.
- {{Rule.}} Violating this {{consequence}}.

## 8. Sharp edges

<!--
  Known debt, traps, and counterintuitive code. Be specific and honest: a vague
  "some parts need refactoring" helps nobody. If there is a workaround in place,
  say what it works around, so the next person can tell when it is safe to
  remove.

  Delete an entry when it is fixed. This section is a live list, not a graveyard.
-->

- **{{Area}}** — {{what is wrong, and what it would take to fix}}.

## 9. Map

<!--
  Path to purpose, for the directories a newcomer needs. Top-level only unless a
  nested path is genuinely load-bearing. Do not mirror the whole tree: `ls` is
  free and always current.
-->

| Path | Purpose |
| --- | --- |
| `{{}}` | {{}} |
