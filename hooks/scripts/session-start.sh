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
        cut -c1-40 2>/dev/null || true
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
    echo "In flight: ${in_flight_count} task(s), one file each in sarah/state/. Read only the one you need."
fi

echo "Before any work, use the sarah-bootstrap skill: it sizes the request and routes it. Do not plan or edit without it."

if [ "${in_flight_count:-0}" -gt 0 ]; then
    echo "Work is in flight: suggest /ill-be-back before anything new."
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
habits="$project_dir/sarah/habits.md"
habits_ok=""
[ -f "$habits" ] && [ -r "$habits" ] && habits_ok=1
off_list=""
defaults_ok=""

if [ -n "$hook_dir" ] && [ -f "$defaults" ] && [ -r "$defaults" ]; then
    defaults_ok=1
    if [ -n "$habits_ok" ]; then
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
# Habit status lines (spec section 5). Facts only, read from sarah/habits.md and
# the presence of the Trello variables. Nothing here calls the network, nothing
# from the environment is printed, and only names of a known shape are echoed,
# so habits.md cannot steer the model. A project without habits.md gets none.
# ---------------------------------------------------------------------------

today=$(date +%Y-%m-%d 2>/dev/null || true)

# plain NAME : the label the user knows a habit or rule by.
plain() {
    case "$1" in
        gitflow) echo "protect the main line" ;;
        changelog-fragment) echo "release-note line" ;;
        tracker) echo "Trello" ;;
        no-idle) echo "keep working" ;;
        dispatch-guard) echo "task rules" ;;
        *) echo "$1" ;;
    esac
}

tracker_line=""
audit_line=""
exceptions_line=""

if [ -n "$habits_ok" ]; then
    facts=$(
        awk -v today="$today" '
            function dn(s,   y, m, d, ml, leap, era, yoe, doy, doe) {
                if (s !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return -1
                y = substr(s, 1, 4) + 0; m = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0
                if (y < 1 || m < 1 || m > 12 || d < 1) return -1
                split("31 28 31 30 31 30 31 31 30 31 30 31", ml, " ")
                leap = (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0))
                if (leap) ml[2] = 29
                if (d > ml[m]) return -1
                if (m <= 2) y--
                era = int(y / 400); yoe = y - era * 400
                doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
                doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
                return era * 146097 + doe
            }
            function trim(s) { gsub(/^[ \t]+/, "", s); gsub(/[ \t]+$/, "", s); return s }
            BEGIN { t = dn(today) }
            NR > 2000 { exit }
            { sub(/\r$/, "") }
            /^## / { sec = tolower(trim(substr($0, 4))); next }
            sec == "chosen" && /^[-*][ \t]+[a-z0-9][a-z0-9-]*[ \t]*$/ {
                name = $0; sub(/^[-*][ \t]+/, "", name); name = trim(name)
                if (length(name) <= 24 && !(name in seen)) { seen[name] = 1; print "C " name }
                next
            }
            sec == "settings" && /^[-*][ \t]+limit[ \t]*:[ \t]*[0-9]+[ \t]*$/ {
                v = $0; sub(/^[^:]*:/, "", v); v = trim(v) + 0
                if (v >= 1 && v <= 99) print "L " v
                next
            }
            sec == "tracker" {
                if ($0 ~ /^[-*][ \t]+tracker[ \t]*:[ \t]*[a-z][a-z0-9_]*[ \t]*$/) print "T"
                else if ($0 ~ /^[-*][ \t]+board[ \t]*:[ \t]*[^ \t]+[ \t]*$/) print "B"
                else if ($0 ~ /^Last audit:/) { v = $0; sub(/^[^:]*:/, "", v); print "A " trim(v) }
                else if ($0 ~ /^Last status:/) {
                    v = $0; sub(/^[^:]*:/, "", v); v = trim(v)
                    if (v == "connected" || v ~ /^(token rejected|not answering) [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) print "S " v
                }
                next
            }
            sec == "exceptions" {
                line = trim($0)
                if (substr(line, 1, 1) != "|") next
                sub(/^\|/, "", line); sub(/\|[ \t]*$/, "", line)
                if (split(line, c, "|") != 5) next
                r = trim(c[1])
                if (r == "rule" || (c[1] ~ /^[ \t:-]+$/ && c[2] ~ /^[ \t:-]+$/)) next
                xp = trim(c[3]); e = dn(xp); g = dn(trim(c[5]))
                if (trim(c[2]) == "" || e < 0 || g < 0 || e < g || e - g > 14 || t < 0 || g > t || t > e) next
                if (r !~ /^[a-z0-9][a-z0-9-]*$/ || length(r) > 24) r = "other"
                print "X " r " " xp
            }
        ' "$habits" 2>/dev/null || true
    )

    chosen_list=""
    chosen_n=0
    limit=3
    tracker_chosen=""
    tracker_named=""
    board_named=""
    last_audit=""
    status=""
    exc_n=0
    exc_text=""
    while IFS=' ' read -r kind a b; do
        case "$kind" in
            C)
                case "$a" in _* | always-ask) continue ;; esac
                [ "$chosen_n" -lt 6 ] || continue
                chosen_n=$((chosen_n + 1))
                [ "$a" != tracker ] || tracker_chosen=1
                chosen_list="${chosen_list:+$chosen_list, }$(plain "$a")"
                ;;
            L) limit="$a" ;;
            T) tracker_named=1 ;;
            B) board_named=1 ;;
            A) last_audit="$a${b:+ $b}" ;;
            S) status="$a${b:+ $b}" ;;
            X)
                exc_n=$((exc_n + 1))
                if [ "$exc_n" -le 2 ]; then
                    exc_text="${exc_text:+$exc_text; }$(plain "$a"), until $b"
                elif [ "$exc_n" -eq 3 ]; then
                    exc_text="$exc_text; ..."
                fi
                ;;
        esac
    done <<FACTS
$facts
FACTS

    # Credentials: only whether the variables are set, never what they hold.
    creds=""
    if [ -n "${TRELLO_API_KEY:-}" ] && [ -n "${TRELLO_TOKEN:-}" ]; then creds=1; fi

    if [ -n "$tracker_chosen" ] && [ -z "$creds" ]; then
        chosen_list=$(printf '%s' "$chosen_list" | sed 's/Trello/Trello (waiting for credentials)/' 2>/dev/null || printf '%s' "$chosen_list")
    fi

    defaults_part=""
    if [ -n "$defaults_ok" ]; then
        off_n=0
        for n in $(sed -n 's/^@\([a-z][a-z-]*\) .*/\1/p' "$defaults" 2>/dev/null); do
            case " $off_list " in *" $n "*) off_n=$((off_n + 1)) ;; esac
        done
        total_n=$(grep -c '^@[a-z][a-z-]* ' "$defaults" 2>/dev/null || true)
        if [ "$off_n" -eq 0 ]; then defaults_part=" Defaults: on."
        elif [ "$off_n" -ge "${total_n:-0}" ]; then defaults_part=" Defaults: off."
        else defaults_part=" Defaults: on, ${off_n} off."
        fi
    fi

    if [ -z "$chosen_list" ]; then
        echo "Habits: none.${defaults_part}"
    else
        tasks="tasks"; [ "$limit" -ne 1 ] || tasks="task"
        echo "Habits: ${chosen_list}. Limit: ${limit} ${tasks}.${defaults_part}"
    fi

    # Waiting for credentials is already on the Habits line; only the other
    # states get a line of their own, and "connected" is not news.
    if [ -n "$tracker_chosen" ] && [ -n "$creds" ]; then
        case "$status" in
            "token rejected "*) tracker_line="Tracker: ${status}." ;;
            "not answering "*) tracker_line="Tracker: not answering." ;;
        esac
        if [ -n "$tracker_named" ] && [ -n "$board_named" ] && [ -n "$today" ] && [ "$last_audit" != "$today" ]; then
            audit_line="Audit: due today."
        fi
    fi
    if [ "$exc_n" -gt 0 ]; then
        exceptions_line="Exceptions: ${exc_n} active (${exc_text})."
    fi
fi

# ---------------------------------------------------------------------------
# State size (R19, D6). The index may reach 8,192 bytes and a task file 16,384.
# One line per file over its limit, at most two, then a count. A marker
# sarah/.local/compact-snoozed holding today's date silences the lines for the
# day; /sarah-compact writes it when the user says "not today".
# ---------------------------------------------------------------------------

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

[ -z "$tracker_line" ] || echo "$tracker_line"
[ -z "$audit_line" ] || echo "$audit_line"
[ -z "$exceptions_line" ] || echo "$exceptions_line"

exit 0
