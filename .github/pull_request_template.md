<!--
Open pull requests against `develop`, never against `main`.
Read CONTRIBUTING.md if you have not.
-->

## What this delivers

One or two sentences. What changed, and why it needed to.

## Checks

```bash
claude plugin validate . --strict
sh -n hooks/scripts/*.sh
```

- [ ] Both pass locally.

## The documentation gate

If it isn't documented, it isn't done.

- [ ] `sarah/state.md` is current.
- [ ] `ARCHI.md` updated, or the architecture did not move.
- [ ] `README.md` updated, or nothing user-visible changed.
- [ ] An entry exists in `sarah/changelog/`.

## The rules that are easy to break by accident

- [ ] No sixth command was added — or one was removed to make room, and the
      trade is argued below.
- [ ] `sarah-bootstrap` is still inside its ~2,000-token budget.
- [ ] No hook can exit non-zero.
- [ ] Skill descriptions state the phrasings that should fire them, including
      the ones a user would say without knowing the skill exists.
- [ ] Prose is in English.
- [ ] Nothing references infrastructure other than GitHub.

## Anything deliberately not done

Name it. Work that is knowingly incomplete is fine; work that is silently
incomplete is what the next person pays for.
