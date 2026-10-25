# Habit: work does not idle (R24)

Installs one Stop hook, `sarah/hooks/no-idle/stop.sh`. This file is for the agent
installing or operating the habit; it is not copied into the project.

**Failure prevented:** a session ends with nothing in progress while ready work
waits, and the user has to say "keep going" every time.

## What it does

When the agent is about to stop, the hook reads `sarah/state.md` (the "In flight"
table, local state only, no network and no tracker) and blocks **once** with a
short reason naming the next task, only when all of these hold:

- nothing is in progress,
- at least one task is ready,
- no task is waiting on the user,
- no stop marker is set for today.

In every other case it allows. It always allows when `stop_hook_active` is true,
so it nudges once and cannot loop. A missing or unreadable state, malformed
input or no `jq` also allows, silently.

## How rows are read

| Class | Rule |
| --- | --- |
| Waiting on the user | "Waiting on" names `you` or `user` |
| In progress | "Waiting on" is `nothing`, `nobody`, `none`, `-` or empty, and Phase is not `ready` |
| Ready | same, and Phase is `ready` |

A row waiting on anything else (CI, a person, an external event) is none of the
three. To make a task eligible for pick-up, set its Phase to `ready`.

## Telling it to stop

When the user says to stop, write today's date (`YYYY-MM-DD`) to
`sarah/.local/stop-requested`. The hook honours the file only on that date, so it
expires by itself. `sarah/.local/` is gitignored.

## Requirements

`jq` on the project's `PATH`. Without it the hook allows and does nothing.
