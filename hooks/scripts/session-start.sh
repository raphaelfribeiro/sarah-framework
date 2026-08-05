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

phase=$(field 'Phase')
level=$(field 'Default level')
task=$(field 'Current task')

# Is there real work in flight? A section holding only the template placeholder,
# the word "none", or nothing at all does not count.
in_flight=$(
    awk '
        /^## In flight/ { inside = 1; next }
        /^## / { inside = 0 }
        inside && /^- / {
            line = tolower($0)
            if (line !~ /\{\{/ && line !~ /^- *none/ && line !~ /nothing in flight/) {
                found = 1
            }
        }
        END { if (found) print "yes" }
    ' "$state" 2>/dev/null || true
)

# ---------------------------------------------------------------------------
# Emit the pointer. Stdout on SessionStart is added to context verbatim, so this
# stays deliberately small: it orients, it does not brief. The sarah-bootstrap
# skill carries the actual rules and loads on demand.
# ---------------------------------------------------------------------------

echo "S.A.R.A.H. is active in this project."

if [ -n "$phase" ] || [ -n "$level" ]; then
    echo "State: phase ${phase:-unknown}, default level ${level:-unknown}."
fi

if [ -n "$task" ] && [ "$task" != "none" ]; then
    echo "Current task: $task"
fi

echo "Before any development work, use the sarah-bootstrap skill: it reads sarah/state.md and ARCHI.md, sizes the request into a scale level, and routes to the right phase with only that phase's specialists in context. Do not start planning or editing without it."

if [ "$in_flight" = "yes" ]; then
    echo "Work is already in flight. Suggest /ill-be-back to the user for a situation report and the day's priorities before starting anything new."
fi

exit 0
