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
        sed 's/^[[:space:]]*//; s/[[:space:]]*$//' 2>/dev/null |
        cut -c1-60 2>/dev/null || true
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
    echo "In flight: ${in_flight_count} task(s). State is in sarah/state/, one file per task - read only the one you need."
fi

echo "Before any development work, use the sarah-bootstrap skill: it reads sarah/state.md and ARCHI.md, sizes the request, and routes to the right phase. Do not plan or edit without it."

if [ "${in_flight_count:-0}" -gt 0 ]; then
    echo "Work is in flight: suggest /ill-be-back (situation report, day's priorities) before anything new."
fi

# ---------------------------------------------------------------------------
# Conversation defaults (R1-R7, ADR-007).
#
# The text lives in hooks/conversation-defaults.txt, one rule per line, each
# tagged "@name". A rule is dropped when sarah/habits.md has "- name: off"
# under "## Conversation defaults". Only known-shaped names are read and
# nothing from habits.md is ever printed, so that file cannot steer the model.
# A missing, unreadable or malformed habits.md leaves every default on.
# ---------------------------------------------------------------------------

hook_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || hook_dir=""
defaults="$hook_dir/../conversation-defaults.txt"

if [ -n "$hook_dir" ] && [ -f "$defaults" ] && [ -r "$defaults" ]; then
    off_list=""
    habits="$project_dir/sarah/habits.md"
    if [ -f "$habits" ] && [ -r "$habits" ]; then
        off_list=$(
            awk '
                NR > 400 { exit }
                { sub(/\r$/, ""); line = tolower($0) }
                line ~ /^## / { inside = (line ~ /^## conversation defaults[ \t]*$/); next }
                inside && line ~ /^[-*][ \t]+[a-z][a-z-]*[ \t]*:[ \t]*off[ \t]*$/ {
                    sub(/^[-*][ \t]+/, "", line)
                    sub(/[ \t]*:.*$/, "", line)
                    print line
                }
            ' "$habits" 2>/dev/null | tr '\n' ' ' 2>/dev/null || true
        )
    fi
    awk -v off=" ${off_list} " '
        /^@[a-z][a-z-]* / {
            name = substr($1, 2)
            if (index(off, " " name " ")) next
            sub(/^@[a-z-]+ /, "")
        }
        { print }
    ' "$defaults" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# State size (R19, D6). The index may reach 8,192 bytes and a task file 16,384.
# One line per file over its limit, at most two, then a count. A marker
# sarah/.local/compact-snoozed holding today's date silences the lines for the
# day; /sarah-compact writes it when the user says "not today".
# ---------------------------------------------------------------------------

today=$(date +%Y-%m-%d 2>/dev/null || true)
snoozed=""
marker="$project_dir/sarah/.local/compact-snoozed"
if [ -f "$marker" ] && [ -r "$marker" ]; then
    snoozed=$(head -n 1 "$marker" 2>/dev/null | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' 2>/dev/null || true)
fi

if [ -z "$today" ] || [ "$snoozed" != "$today" ]; then
    shown=0
    hidden=0

    # check_size FILE LIMIT : report FILE if it is over LIMIT bytes.
    check_size() {
        [ -f "$1" ] && [ -r "$1" ] || return 0
        bytes=$(wc -c < "$1" 2>/dev/null | tr -d ' \t' || true)
        case "$bytes" in '' | *[!0-9]*) return 0 ;; esac
        [ "$bytes" -gt "$2" ] || return 0
        if [ "$shown" -ge 2 ]; then
            hidden=$((hidden + 1))
            return 0
        fi
        shown=$((shown + 1))
        label=$(printf '%s' "${1#"$project_dir"/}" | tr -c 'A-Za-z0-9._/ -' '?' 2>/dev/null || true)
        kb=$(awk -v n="$bytes" 'BEGIN { printf "%.1f", n / 1024 }' 2>/dev/null || true)
        echo "Size: ${label} is ${kb} KB, over its $(($2 / 1024)) KB limit. Offer to compact once, at the first pause."
    }

    check_size "$state" 8192
    for task_file in "$project_dir"/sarah/state/*.md; do
        check_size "$task_file" 16384
    done
    if [ "$hidden" -gt 0 ]; then
        echo "Size: ${hidden} more file(s) are over their limit."
    fi
fi

exit 0
