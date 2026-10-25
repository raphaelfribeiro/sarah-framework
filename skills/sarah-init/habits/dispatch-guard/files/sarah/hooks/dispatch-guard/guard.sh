# R10, R15, R17 dispatch guard: a project hook, installed by /sarah-init at the
# user's choice and owned by this project. PreToolUse on Agent; reads the tool
# call as JSON on stdin. It acts only on an executor dispatch (`sarah:executor`
# or `executor`); every other agent passes untouched. Three checks, each on only
# when listed in `- dispatch checks: model, premise, limit` under Settings in
# sarah/habits.md (no such line: all three):
#   model    the call sets `model`                                    (rule dispatch-model)
#   limit    the in-progress rows of the In flight table in sarah/state.md stay
#            within `- limit: <n>` (default 3), and the call runs in its own
#            worktree (`isolation: "worktree"`)                       (rule dispatch-limit)
#   premise  the task file named in the brief (the first sarah/state/<slug>.md in
#            the prompt) has a Premises section whose every line reads
#            `- YYYY-MM-DD - <premise>` dated today                  (rule dispatch-premise)
# The orchestrator marks the task in progress before it dispatches, so the count
# already includes the task being started: it is refused when the count exceeds
# the limit. Rows are counted as the session-start hook counts them (header,
# separator, `{{` template and "nothing in flight" rows do not count), minus the
# rows whose Phase is `ready`.
# It blocks only on a positive finding. A missing tool, an unreadable file, a
# malformed limit or a call with no prompt means the rule was not checked: it
# says so and allows. A valid, unexpired exception (R16) in sarah/habits.md lets
# a call through for its own rule and is logged.
# Exit 0 allows, exit 2 blocks, and nothing else is ever returned.
rule=dispatch-guard
here=$(cd "$(dirname "$0")" && pwd)
if [ ! -f "$here/../_lib/exceptions.sh" ]; then
    printf 'Rule not checked: %s (the shared library is not installed). I let it through.\n' "$rule" >&2
    exit 0
fi
. "$here/../_lib/exceptions.sh"
project=${CLAUDE_PROJECT_DIR:-$(cd "$here/../../.." && pwd)}
habits="$project/sarah/habits.md"
state="$project/sarah/state.md"

command -v jq >/dev/null 2>&1 || sarah_not_checked "$rule" "jq is not installed"
input=$(cat 2>/dev/null)
printf '%s' "$input" | jq -e . >/dev/null 2>&1 || sarah_not_checked "$rule" "the hook input could not be read"

# field NAME : the string value of tool_input.NAME, empty when absent or not a string.
field() {
    printf '%s' "$input" | jq -r --arg k "$1" 'if (.tool_input | type) == "object" and (.tool_input[$k] | type) == "string" then .tool_input[$k] else "" end' 2>/dev/null
}

case $(field subagent_type) in
    sarah:executor | executor) ;;
    *) exit 0 ;;
esac

# deny RULE WHAT ROUTE : an exception lets the call through; otherwise it is refused.
deny() {
    if sarah_exception_honored "$project" "$1"; then
        return 0
    fi
    sarah_block "$1" "$2" "$3"
}

# setting NAME : the value of `- NAME: value` in the Settings section of habits.md.
setting() {
    awk -v want="$1" '
        /^## / { inside = ($0 ~ /^## Settings[ \t]*$/); next }
        !inside { next }
        {
            sub(/\r$/, "")
            prefix = "- " want ":"
            if (substr($0, 1, length(prefix)) == prefix) {
                v = substr($0, length(prefix) + 1)
                gsub(/^[ \t]+|[ \t]+$/, "", v)
                print v
                exit
            }
        }' "$habits" 2>/dev/null
}

# on NAME : whether a check is listed. No line at all means all three are on.
checks_line_present=0
checks=""
if [ -f "$habits" ] && grep -q '^- dispatch checks:' "$habits" 2>/dev/null; then
    checks_line_present=1
    checks=$(setting "dispatch checks" | tr 'A-Z,' 'a-z ')
fi
on() {
    [ "$checks_line_present" = 0 ] && return 0
    case " $checks " in
        *" $1 "*) return 0 ;;
    esac
    return 1
}

check_model() {
    model=$(field model | tr -d ' \t\r\n')
    if [ -z "$model" ]; then
        deny dispatch-model "this executor dispatch does not set a model" "Set model on the Agent call to the one the task's Executor row declares (sonnet, opus, haiku or fable)."
    fi
}

check_limit() {
    isolation=$(field isolation)
    if [ "$isolation" != worktree ]; then
        deny dispatch-limit "this executor would share the working folder; each task gets its own copy" 'Dispatch with isolation: "worktree".'
    fi
    limit=3
    if [ -f "$habits" ] && grep -q '^- limit:' "$habits" 2>/dev/null; then
        limit=$(setting limit)
    fi
    case $limit in
        '' | *[!0-9]* | 0 | ???*)
            sarah_say_unchecked dispatch-limit "the limit line in sarah/habits.md is not a whole number from 1 to 99"
            return 0
            ;;
    esac
    if [ ! -f "$state" ] || [ ! -r "$state" ]; then
        sarah_say_unchecked dispatch-limit "sarah/state.md could not be read"
        return 0
    fi
    # One line out: "<count><TAB><task names joined by '; '>".
    found=$(awk -F'|' '
        function trim(s) { gsub(/^[ \t\r]+|[ \t\r]+$/, "", s); return s }
        /^## / { inside = ($0 ~ /^## In flight/); next }
        inside && /^\|/ {
            line = tolower($0)
            if (line ~ /\{\{/) next
            if (line ~ /^\| *-+ *\|/) next
            if (line ~ /\| *task *\|/) next
            if (line ~ /nothing in flight/) next
            phase = tolower(trim($4)); gsub(/[`*_]/, "", phase)
            if (phase == "ready") next
            n++
            names = names (names == "" ? "" : "; ") trim($2)
        }
        END { printf "%d\t%s\n", n + 0, names }
    ' "$state" 2>/dev/null) || {
        sarah_say_unchecked dispatch-limit "sarah/state.md could not be read"
        return 0
    }
    count=${found%%"$(printf '\t')"*}
    names=${found#*"$(printf '\t')"}
    if [ "$count" -gt "$limit" ] 2>/dev/null; then
        deny dispatch-limit "$count tasks are in progress and the limit is $limit (running: $names)" "Finish or park one of them before starting another; the user sets the limit in sarah/habits.md."
    fi
}

check_premise() {
    prompt=$(field prompt)
    if ! printf '%s' "$input" | jq -e '(.tool_input | type) == "object" and (.tool_input.prompt | type) == "string"' >/dev/null 2>&1; then
        sarah_say_unchecked dispatch-premise "the call carries no prompt to read the task file from"
        return 0
    fi
    today=$(sarah_today)
    case $today in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
        *)
            sarah_say_unchecked dispatch-premise "today's date could not be read"
            return 0
            ;;
    esac
    taskrel=$(printf '%s' "$prompt" | grep -o 'sarah/state/[A-Za-z0-9._-]*\.md' | head -n 1)
    route="Re-check each premise against the current code and sarah/decisions.md, put today's date on it as '- $today - <premise>' (or '- $today - none' when the task assumes nothing), and dispatch again. If a premise is false, do not start: ask the user one question with the evidence."
    if [ -z "$taskrel" ]; then
        deny dispatch-premise "the brief does not name the task file (sarah/state/<slug>.md), so its premises cannot be checked" "Name the task file in the brief. $route"
        return 0
    fi
    task="$project/$taskrel"
    if [ ! -f "$task" ]; then
        deny dispatch-premise "$taskrel does not exist, so the task has no re-checked premises" "Write the task file first. $route"
        return 0
    fi
    # "<premise lines> <lines dated today>" of the Premises section; comments are skipped.
    counted=$(awk -v today="$today" '
        { sub(/\r$/, "") }
        /^## / { inside = ($0 ~ /^## Premises[ \t]*$/); incomment = 0; next }
        !inside { next }
        incomment { if (index($0, "-->") > 0) incomment = 0; next }
        /^[ \t]*<!--/ { if (index($0, "-->") == 0) incomment = 1; next }
        /^- / {
            total++
            if ($0 ~ /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] - [^ ]/ && substr($0, 3, 10) == today) fresh++
        }
        END { printf "%d %d\n", total + 0, fresh + 0 }
    ' "$task" 2>/dev/null) || {
        sarah_say_unchecked dispatch-premise "$taskrel could not be read"
        return 0
    }
    total=${counted%% *}
    fresh=${counted##* }
    if [ "$total" = 0 ]; then
        deny dispatch-premise "$taskrel has no premises, so nothing was re-checked" "$route"
    elif [ "$fresh" != "$total" ]; then
        deny dispatch-premise "$taskrel has premises not checked today ($fresh of $total are dated $today)" "$route"
    fi
}

if on model; then check_model; fi
if on limit; then check_limit; fi
if on premise; then check_premise; fi
exit 0
