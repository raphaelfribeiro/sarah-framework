# S.A.R.A.H.

[![License: MIT][license-shield]][license-url]
[![Status: alpha][status-shield]][status-url]

**Be prepared. Judgment Day is a deploy on Friday.**

Structured development workflow for Claude Code — specialist agents per phase, hard gates, human decisions.

*The machines write the code. You command the mission.*

**S**kills, **A**gents, **R**eviews & **A**daptive **H**ierarchy. A Claude Code
plugin that carries a project from the first idea to the release tag without
letting the workflow become a project of its own.

---

> [!WARNING]
> **v0.1 is under construction.** The foundation is in place — the plugin
> installs and `/sarah-init` sets up a project. The phase pipeline and the agent
> roster are not built yet. See [Status](#status) for what works today.

## Why S.A.R.A.H.?

Unsupervised AI ships fast and breaks everything. S.A.R.A.H. exists so the
machines never run the mission — you do.

Five commitments, held together:

1. **Specialist expertise, on demand.** The full team exists — architecture,
   UX, security, DevOps, QA — but only the current phase's specialists enter
   context. Having the roster is not the same as activating it.
2. **Scale that actually adapts.** A typo reaches code in minutes. A new product
   goes through the whole pipeline. The process depth *and* the number of active
   agents follow the size of the work.
3. **Decisions taught, not made for you.** Every real choice arrives as two or
   three options with honest trade-offs and a justified recommendation. You
   decide. You come away understanding why.
4. **A workflow that disappears.** Skills fire on intent. There are five
   commands, and that ceiling is hard.
5. **Brownfield without ceremony.** Existing projects work in delta-specs
   anchored to a curated architecture memory, never a monolithic upfront rewrite
   of documentation nobody asked for.

## Status

| Component | State |
| --- | --- |
| Plugin install and manifests | Working |
| `sarah-bootstrap` orientation and level routing | Working |
| `/sarah-init` project setup | Working |
| `ARCHI.md`, `README.md`, `state.md` templates | Working |
| `session-start` hook | Working |
| Seven phase skills and the agent roster | Phase B |
| TDD gate, adversarial review, remaining commands | Phase C |
| Full documentation, walkthroughs, CI | Phase D |

## Quickstart

```
/plugin marketplace add raphaelfribeiro/sarah-framework
/plugin install sarah@sarah-framework
/sarah-init
```

`/sarah-init` reads your repository, works out whether it is greenfield or
brownfield, and interviews you only for what it could not learn on its own.

## Commands

Five, total. Everything else triggers on intent.

| Command | Does |
| --- | --- |
| `/sarah-init` | Set up S.A.R.A.H. in this project |
| `/sarah-status` | Current phase, level, open gates, pending decisions |
| `/sarah-compact` | Measure and compact `ARCHI.md` against its size budget |
| `/ill-be-back` | Session-start situation report and the day's priorities |
| `/hasta-la-vista` | Session-end debrief, state update, documentation check |

## Contributing

Questions, bug reports, and feature ideas:
[open an issue](https://github.com/raphaelfribeiro/sarah-framework/issues).

The full contribution guide lands with v0.1.

## License

MIT © Raphael Ribeiro. See [LICENSE](LICENSE) for the full text.

---

*No fate but what we ship.*

[license-shield]: https://img.shields.io/badge/license-MIT-blue.svg
[license-url]: LICENSE
[status-shield]: https://img.shields.io/badge/status-alpha-orange.svg
[status-url]: #status
