#!/bin/sh
# S.A.R.A.H. — SessionStart hook.
#
# Injects a short orientation pointer when the current project is running
# S.A.R.A.H., and stays completely silent when it is not.
#
# Contract: this hook never fails the session. Every path exits 0. If a tool is
# missing, a file is unreadable, or the project has no S.A.R.A.H. state, the
# hook produces no output and gets out of the way. A workflow that breaks a
# user's session to announce itself has already lost.
#
# POSIX sh only: no bashisms, no GNU-only flags. This runs on macOS, Linux and
# Git Bash on Windows.

set -u

# Never let an unexpected failure surface as a hook error.
trap 'exit 0' EXIT

# ---------------------------------------------------------------------------
# Locate the project.
# ---------------------------------------------------------------------------

payload=$(cat 2>/dev/null || true)

project_dir=""

# Preferred source: the cwd reported by Claude Code on stdin.
if [ -n "$payload" ] && command -v jq >/dev/null 2>&1; then
    project_dir=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)
fi

# Fallbacks, in decreasing order of reliability.
[ -n "$project_dir" ] && [ -d "$project_dir" ] || project_dir="${CLAUDE_PROJECT_DIR:-}"
[ -n "$project_dir" ] && [ -d "$project_dir" ] || project_dir="$PWD"

state="$project_dir/sarah/state.md"

# Not a S.A.R.A.H. project. Say nothing at all.
[ -r "$state" ] || exit 0

# ---------------------------------------------------------------------------
# Read the state file. Any field that cannot be parsed is simply omitted.
# ---------------------------------------------------------------------------

# Pulls the value cell out of a two-column markdown row: | **Phase** | value |
field() {
    grep -i "^| \*\*$1\*\*" "$state" 2>/dev/null |
        head -n 1 |
        awk -F'|' '{ print $3 }' |
        sed 's/^[[:space:]]*//; s/[[:space:]]*$//' 2>/dev/null || true
}

level=$(field 'Default level')

# Phase and task moved out of this file: it is an index now, and each task keeps
# its own state in sarah/state/<slug>.md. Both are still read, because a project
# initialized before the split still carries them here and reporting nothing
# would be worse than reporting the old shape.
phase=$(field 'Phase')
task=$(field 'Current task')

# How many tasks are in flight? The index lists one table row per task. Header,
# separator and unfilled template rows do not count.
in_flight_count=$(
    awk -F'|' '
        /^## In flight/ { inside = 1; next }
        /^## / { inside = 0 }
        inside && /^\|/ {
            line = tolower($0)
            if (line ~ /\{\{/) next
            if (line ~ /^\| *-+ *\|/) next
            if (line ~ /\| *task *\|/) next
            if (line ~ /nothing in flight/) next
            n++
        }
        END { print n + 0 }
    ' "$state" 2>/dev/null || echo 0
)

# A pre-split project reports its single task the old way.
if [ "${in_flight_count:-0}" -eq 0 ] && [ -n "$task" ] && [ "$task" != "none" ]; then
    in_flight_count=1
fi

# ---------------------------------------------------------------------------
# Emit the pointer. Stdout on SessionStart is added to context verbatim, so this
# stays deliberately small: it orients, it does not brief. The sarah-bootstrap
# skill carries the actual rules and loads on demand.
# ---------------------------------------------------------------------------

echo "S.A.R.A.H. is active in this project."

# "phase unknown" is noise, not information: after the state split there is no
# single project phase to report, and printing a placeholder for it trains the
# reader to skip the line that also carries the level.
if [ -n "$phase" ] && [ -n "$level" ]; then
    echo "State: phase ${phase}, default level ${level}."
elif [ -n "$phase" ]; then
    echo "State: phase ${phase}."
elif [ -n "$level" ]; then
    echo "State: default level ${level}."
fi

if [ -n "$task" ] && [ "$task" != "none" ]; then
    echo "Current task: $task"
elif [ "${in_flight_count:-0}" -gt 0 ]; then
    echo "In flight: ${in_flight_count} task(s). Their state is in sarah/state/, one file per task - read only the one the request belongs to."
fi

echo "Before any development work, use the sarah-bootstrap skill: it reads sarah/state.md and ARCHI.md, sizes the request into a scale level, and routes to the right phase with only that phase's specialists in context. Do not start planning or editing without it."

if [ "${in_flight_count:-0}" -gt 0 ]; then
    echo "Work is already in flight. Suggest /ill-be-back to the user for a situation report and the day's priorities before starting anything new."
fi

exit 0
