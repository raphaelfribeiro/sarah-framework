<!--
  TEMPLATE: README.md for the project S.A.R.A.H. is building.

  /sarah-init copies this to the project root and fills it in. Strip every HTML
  comment from the generated file: they are authoring guidance, not content.

  This structure is not invented. It follows the standard-readme specification
  (https://github.com/RichardLitt/standard-readme) for section order and rules,
  and borrows the conventions that make Best-README-Template
  (https://github.com/othneildrew/Best-README-Template) pleasant to navigate:
  a collapsible table of contents, back-to-top links, and reference-style link
  definitions collected at the bottom.

  Where the two disagree, standard-readme wins, because it is a specification
  rather than a style. The one place this matters: LICENSE MUST BE THE LAST
  SECTION. Contact and acknowledgment material goes above it, not below.

  Hard rules inherited from standard-readme:
    - The title must match the repository name.
    - The short description is a standalone line under the badges, with no
      heading and no leading "> ". It must be under 120 characters and must say
      the same thing as the repository description on GitHub.
    - A table of contents is required once the file passes ~100 lines, and it
      must link to every level-two heading.
    - Contributing must say where to ask questions and whether PRs are accepted.
    - License is last, names the license holder, and links to the LICENSE file.
    - No broken links. Ever.

  Sections 4, 6 and 8 below (Architecture, Testing, Project structure) are
  S.A.R.A.H. additions. They exist because the documentation gate treats an
  out-of-date README as a defect: if a delivery changes how the project is run,
  what it is built on, or how it is tested, the README changes in the same
  merge. Keep them.

  Delete any section that does not apply. An empty section is worse than an
  absent one.
-->

# {{PROJECT_NAME}}

<!--
  Badges: no heading, one per line, newline-delimited. Keep them to the ones a
  reader would act on — build status, coverage, version, license. A wall of
  decorative badges is noise.
-->

[![Build Status][build-shield]][build-url]
[![License: {{LICENSE}}][license-shield]][license-url]

{{ONE_LINE_DESCRIPTION_UNDER_120_CHARS}}

<!--
  Optional long description goes here, with no heading: two or three paragraphs
  on motivation and context for a reader deciding whether this project is what
  they need.
-->

<details>
  <summary>Table of Contents</summary>

- [Overview](#overview)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Usage](#usage)
- [Testing](#testing)
- [Project structure](#project-structure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

</details>

## Overview

<!--
  What the project does, who it is for, and what problem it solves. A screenshot
  or a short terminal capture earns its place here if the project has a visible
  surface.
-->

{{OVERVIEW}}

<p align="right"><a href="#{{project-anchor}}">back to top</a></p>

## Tech stack

<!--
  What the project is actually built on, grouped so a reader can find their
  layer quickly. Versions only where a version is load-bearing.
-->

| Layer | Technology |
| --- | --- |
| Backend | {{}} |
| Frontend | {{}} |
| Data | {{}} |
| Tests | {{}} |
| Infrastructure | {{}} |

<p align="right"><a href="#{{project-anchor}}">back to top</a></p>

## Architecture

<!--
  A short orientation and pointers out. Do not restate ARCHI.md here: it is the
  authority on architecture and duplicating it guarantees the two will drift.
  Three to six sentences, then links.
-->

{{ARCHITECTURE_SUMMARY}}

- Full architecture map: [`ARCHI.md`](ARCHI.md)
- Decision records: [`docs/adr/`](docs/adr/)

<p align="right"><a href="#{{project-anchor}}">back to top</a></p>

## Getting started

### Prerequisites

<!-- Everything needed before the first command, with versions. -->

- {{}}

### Installation

<!--
  A code block a reader can paste. Every command must work on a clean machine,
  in the order given. If a step needs a credential or a config file, say so here
  rather than letting it fail three commands later.
-->

```bash
{{INSTALL_COMMANDS}}
```

<p align="right"><a href="#{{project-anchor}}">back to top</a></p>

## Usage

<!--
  How to actually run it, with the most common invocation first. Include a CLI
  subsection if the project ships a command-line interface.
-->

```bash
{{RUN_COMMANDS}}
```

<p align="right"><a href="#{{project-anchor}}">back to top</a></p>

## Testing

<!--
  How to run the suite, and what the suite covers. Name the layers of the test
  pyramid that exist in this project, so a contributor knows where a new test
  belongs. If coverage is enforced anywhere, say what the threshold is.
-->

```bash
{{TEST_COMMANDS}}
```

| Layer | Scope | Location |
| --- | --- | --- |
| Unit | {{}} | `{{}}` |
| Integration | {{}} | `{{}}` |
| End-to-end | {{}} | `{{}}` |

<p align="right"><a href="#{{project-anchor}}">back to top</a></p>

## Project structure

<!--
  Top-level directories and what each is for. Not the full tree — a tree that
  mirrors the filesystem is out of date the day it is written.
-->

```text
{{TREE}}
```

<p align="right"><a href="#{{project-anchor}}">back to top</a></p>

## Roadmap

<!-- Optional. Delete the section if there is nothing real to put in it. -->

- [ ] {{}}

<p align="right"><a href="#{{project-anchor}}">back to top</a></p>

## Contributing

<!--
  standard-readme requires three things here: where to ask questions, whether
  pull requests are accepted, and what a contribution must satisfy.
-->

Questions and bug reports: [open an issue]({{ISSUES_URL}}).

Pull requests are {{accepted|accepted from maintainers only|not accepted}}. To contribute:

1. Fork the repository and branch from `{{main}}`.
2. {{Add tests for the behavior you change.}}
3. {{Run the full suite before opening the pull request.}}
4. Open a pull request describing what changed and why.

<p align="right"><a href="#{{project-anchor}}">back to top</a></p>

## License

<!-- Must be the last section. Name the holder, link the file. -->

{{LICENSE}} © {{COPYRIGHT_HOLDER}}. See [LICENSE](LICENSE) for the full text.

<!-- Reference-style links, collected here so the prose above stays readable. -->

[build-shield]: {{}}
[build-url]: {{}}
[license-shield]: {{}}
[license-url]: {{}}
