# S.A.R.A.H. habit: work does not idle. A Stop hook; run as `sh <file>`.
#
# Blocks the stop once, with a short reason, only when ALL of these hold:
#   - nothing in sarah/state.md "In flight" is in progress,
#   - at least one row there is ready,
#   - no row waits on the user,
#   - sarah/.local/stop-requested does not hold today's date.
# Anything else allows: a missing or unreadable state, malformed input, no jq,
# or an error of any kind. It blocks only on a positive finding.
#
# Reads local state only. It never calls the network or the tracker.
#
# Row classes, from the Phase and "Waiting on" cells of the In flight table:
#   waiting on the user  "Waiting on" names you or the user
#   in progress          not waiting on anything, and Phase is not "ready"
#   ready                not waiting on anything, and Phase is "ready"
#   (anything else, such as waiting on CI, is none of the three)
#
# stop_hook_active is true when Claude is already continuing because a Stop hook
# blocked. Allowing then is the whole safety against a loop: one nudge, never two.

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
active=$(printf '%s' "$input" | jq -r 'if type == "object" then .stop_hook_active // false else "bad" end' 2>/dev/null) || exit 0
[ "$active" = "false" ] || exit 0

root=${CLAUDE_PROJECT_DIR:-.}
state="$root/sarah/state.md"
[ -f "$state" ] && [ -r "$state" ] || exit 0

marker="$root/sarah/.local/stop-requested"
if [ -e "$marker" ]; then
    stop_day=$(head -n 1 "$marker" 2>/dev/null | tr -d ' \r\t')
    case $stop_day in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
        *) exit 0 ;;
    esac
    today=$(date +%Y-%m-%d 2>/dev/null) || exit 0
    [ "$stop_day" != "$today" ] || exit 0
fi

# One line out: "<in progress> <waiting on user> <ready count> <first ready task>".
found=$(awk -F'|' '
    function trim(s) { gsub(/^[ \t\r]+|[ \t\r]+$/, "", s); return s }
    /^## / { inflight = ($0 ~ /^## In flight/); next }
    !inflight || $0 !~ /^[ \t]*\|/ { next }
    {
        task = trim($2); phase = tolower(trim($4)); wait = tolower(trim($6))
        if (task == "Task" || task ~ /^-+$/ || task == "" || index($0, "{{") > 0) next
        gsub(/[`*_]/, "", phase)
        if (wait ~ /(^|[^a-z])(you|user)([^a-z]|$)/) { user++; next }
        if (wait != "" && wait != "-" && wait !~ /^(nothing|nobody|none)([^a-z]|$)/) next
        if (phase == "ready") { ready++; if (first == "") first = task }
        else busy++
    }
    END { printf "%d %d %d %s\n", busy, user, ready, first }
' "$state" 2>/dev/null) || exit 0

set -f
# shellcheck disable=SC2086 # splitting is the point: four fields, then a task name
set -- $found
[ "$#" -ge 3 ] || exit 0
busy=$1
user=$2
ready=$3
shift 3
[ "$busy" = 0 ] && [ "$user" = 0 ] && [ "$ready" -gt 0 ] 2>/dev/null || exit 0

echo "Next up: $*. Nothing is in progress and ready work is waiting, so take it instead of stopping. If the user told you to stop, write today's date to sarah/.local/stop-requested and stop." >&2
exit 2
