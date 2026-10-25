# Shared library for the S.A.R.A.H. agreements installed in this project.
# Sourced by the guards next to it; it runs nothing on its own and has no shebang
# (the installer prepends a stamp line). POSIX sh, no bashisms, no GNU date options.
#
# An exception (R16) is a row in the Exceptions table of sarah/habits.md:
#   | rule | reason | expires | granted by | date |
# A guard honors a row only when the reason is non-empty, today is inside
# [date, expires], and expires is at most 14 days after date. Anything else, a
# malformed date included, means the row is not honored and the rule applies.
# Every honored use is appended to sarah/exceptions.log; if that cannot be
# written the use is not honored, because an exception nobody can audit is a
# silent bypass.

# shellcheck disable=SC2034  # SARAH_* are the interface the guards read

# One awk program does all the date work: day numbers from the civil calendar,
# so there is no GNU-only date parsing and no platform difference. mode=check prints
# "expires<TAB>days-left<TAB>reason" for the first honored row of rule `want`;
# mode=list prints the table /sarah-status shows.
SARAH_EXC_AWK='
function trim(s) { gsub(/^[ \t]+/, "", s); gsub(/[ \t]+$/, "", s); return s }
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
BEGIN { t = dn(today); rows = 0 }
{ sub(/\r$/, "") }
FILENAME == logf { if ($1 ~ /^[0-9-]+$/ && $3 == "until") uses[$2 SUBSEP $4]++; next }
/^## / { insec = ($0 ~ /^## Exceptions[ \t]*$/); next }
!insec { next }
{
    line = $0; sub(/^[ \t]+/, "", line)
    if (substr(line, 1, 1) != "|") next
    sub(/^\|/, "", line); sub(/\|[ \t]*$/, "", line)
    n = split(line, c, "|")
    if (n == 5) {
        r = trim(c[1])
        if (r == "rule" || (c[1] ~ /^[ \t:-]+$/ && c[2] ~ /^[ \t:-]+$/)) next
        reason = trim(c[2]); xp = trim(c[3]); gr = trim(c[5])
        gsub(/\t/, " ", reason)
        e = dn(xp); g = dn(gr)
        ok = (reason != "" && e >= 0 && g >= 0 && e >= g && e - g <= 14 && t >= 0)
        if (mode == "check") {
            if (ok && r == want && g <= t && t <= e) { print xp "\t" (e - t) "\t" reason; exit }
            next
        }
        state = "invalid"
        if (ok && g > t) state = "future"
        else if (ok && t <= e) state = "active"
        else if (ok && t - e <= 14) state = "expired"
        else if (ok) state = "old"
        if (state == "old") next
        rows++; rr[rows] = r; re[rows] = xp; rs[rows] = reason; rst[rows] = state
    } else if (mode == "list") {
        rows++; rr[rows] = "?"; re[rows] = ""; rs[rows] = "row does not have 5 cells"; rst[rows] = "invalid"
    }
}
END {
    if (mode != "list") exit
    na = 0
    for (i = 1; i <= rows; i++) if (rst[i] == "active") na++
    if (rows == 0 || (na == 0 && rows == 0)) { print "Exceptions: none active."; exit }
    print "| Rule | Until | Reason | Uses |"
    print "| --- | --- | --- | --- |"
    split("active future invalid expired", order, " ")
    for (k = 1; k <= 4; k++) for (i = 1; i <= rows; i++) if (rst[i] == order[k]) {
        u = re[i]
        if (rst[i] == "expired") u = u " expired"
        else if (rst[i] == "future") u = u " not yet active"
        else if (rst[i] == "invalid") u = u " invalid, not honored"
        print "| " rr[i] " | " u " | " rs[i] " | " (uses[rr[i] SUBSEP re[i]] + 0) " |"
    }
}'

# Splits a shell command into simple commands, one per line. Quoted text is
# collapsed into single words (separators and spaces inside quotes become _), so
# a commit message that mentions "git push origin main" is not a push. A backslash
# at the end of a line joins it with the next, as the shell does.
SARAH_SPLIT_AWK='
function flush() { if (out != "") print out; out = "" }
BEGIN { inq = ""; esc = 0; out = "" }
{
    n = length($0)
    for (i = 1; i <= n; i++) {
        ch = substr($0, i, 1)
        if (esc) { out = out ((inq != "" && ch ~ /[ \t;&|()`]/) ? "_" : ch); esc = 0; continue }
        if (inq == "\047") { if (ch == "\047") inq = ""; else out = out (ch ~ /[ \t;&|()`]/ ? "_" : ch); continue }
        if (inq == "\"") {
            if (ch == "\\") { esc = 1; continue }
            if (ch == "\"") { inq = ""; continue }
            out = out (ch ~ /[ \t;&|()`]/ ? "_" : ch); continue
        }
        if (ch == "\\") { esc = 1; continue }
        if (ch == "\047" || ch == "\"") { inq = ch; continue }
        if (ch ~ /[;&|()`]/) { flush(); continue }
        out = out ch
    }
    # A backslash that ends the line, outside single quotes, removes the newline:
    # the command goes on with the next line (inside double quotes too).
    if (esc) { esc = 0; next }
    if (inq != "") out = out "_"; else flush()
}
END { flush() }'

sarah_today() {
    date +%Y-%m-%d 2>/dev/null
}

# sarah_exception_honored PROJECT RULE : 0 when a valid exception covers RULE
# today and the use was logged; 1 otherwise. Announces the use on stderr.
sarah_exception_honored() {
    _sx_file="$1/sarah/habits.md"
    [ -f "$_sx_file" ] || return 1
    _sx_today=$(sarah_today)
    _sx_hit=$(awk -v mode=check -v want="$2" -v today="$_sx_today" -v logf="" "$SARAH_EXC_AWK" "$_sx_file" 2>/dev/null)
    [ -n "$_sx_hit" ] || return 1
    _sx_tab=$(printf '\t')
    _sx_exp=${_sx_hit%%"$_sx_tab"*}
    _sx_rest=${_sx_hit#*"$_sx_tab"}
    _sx_left=${_sx_rest%%"$_sx_tab"*}
    _sx_reason=${_sx_rest#*"$_sx_tab"}
    _sx_log="$1/sarah/exceptions.log"
    { printf '%s %s until %s reason: %s\n' "$_sx_today" "$2" "$_sx_exp" "$_sx_reason"; } 2>/dev/null >>"$_sx_log" || return 1
    _sx_uses=$(grep -c "^[0-9-]* $2 until $_sx_exp " "$_sx_log" 2>/dev/null)
    _sx_plural=s
    [ "$_sx_uses" = 1 ] && _sx_plural=""
    _sx_lapse=""
    if [ "$_sx_left" -le 3 ] 2>/dev/null; then
        case $_sx_left in
            0) _sx_lapse=" It lapses today." ;;
            1) _sx_lapse=" It lapses in 1 day." ;;
            *) _sx_lapse=" It lapses in $_sx_left days." ;;
        esac
    fi
    printf 'Exception in use: %s, until %s (reason: %s). Used %s time%s.%s\n' "$2" "$_sx_exp" "$_sx_reason" "$_sx_uses" "$_sx_plural" "$_sx_lapse" >&2
    return 0
}

# sarah_exceptions_list PROJECT : the table /sarah-status shows.
sarah_exceptions_list() {
    _sl_file="$1/sarah/habits.md"
    if [ ! -f "$_sl_file" ]; then
        echo "Exceptions: none active."
        return 0
    fi
    _sl_log="$1/sarah/exceptions.log"
    [ -f "$_sl_log" ] || _sl_log=/dev/null
    awk -v mode=list -v today="$(sarah_today)" -v logf="$_sl_log" "$SARAH_EXC_AWK" "$_sl_file" "$_sl_log" 2>/dev/null
}

# sarah_say_unchecked RULE REASON : the line for a rule that could not be
# evaluated. The call is allowed; the guard says so. Claude Code never shows the
# stderr of a hook that exits 0, so the line also goes to stdout as hook JSON
# (additionalContext, no permission decision), once, when the guard exits 0.
# The JSON is built by hand: this fires exactly when jq is missing.
SARAH_UNCHECKED=""
sarah_say_unchecked() {
    _su_line="Rule not checked: $1 ($2). I let it through."
    printf '%s\n' "$_su_line" >&2
    SARAH_UNCHECKED="${SARAH_UNCHECKED:+$SARAH_UNCHECKED }$_su_line"
    trap sarah_emit_unchecked EXIT
}

# sarah_emit_unchecked : the EXIT trap. Prints the collected lines as hook JSON
# when the guard allows; a block (exit 2) has its own message and no JSON.
sarah_emit_unchecked() {
    _se_rc=$?
    [ "$_se_rc" = 0 ] && [ -n "$SARAH_UNCHECKED" ] || return 0
    _se_msg=$(printf '%s' "$SARAH_UNCHECKED" | tr -d '\000-\037' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$_se_msg"
}

# sarah_not_checked RULE REASON : say it and end the guard, allowing the call.
sarah_not_checked() {
    sarah_say_unchecked "$1" "$2"
    exit 0
}

# sarah_block RULE WHAT ROUTE : refuse the call (exit 2, message to stderr). The
# message names the rule, the way to comply, and the exception path stated as a
# fact, never as an offer.
sarah_block() {
    printf 'Blocked: %s. Rule: %s. %s\n' "$2" "$1" "$3" >&2
    printf 'Only when no compliant route exists: a named exception of up to 14 days (rule %s, a reason, an end date) is the way past. Only the user can ask for one; never write or propose one yourself.\n' "$1" >&2
    exit 2
}

# sarah_read_input RULE : reads the hook JSON on stdin into SARAH_CMD (the Bash
# command) and SARAH_CWD. Ends the guard, allowing the call, when there is
# nothing to check or no way to check it.
sarah_read_input() {
    command -v jq >/dev/null 2>&1 || sarah_not_checked "$1" "jq is not installed"
    _sr_in=$(cat 2>/dev/null)
    printf '%s' "$_sr_in" | jq -e . >/dev/null 2>&1 || sarah_not_checked "$1" "the hook input could not be read"
    SARAH_CMD=$(printf '%s' "$_sr_in" | jq -r 'if (.tool_input | type) == "object" and (.tool_input.command | type) == "string" then .tool_input.command else "" end' 2>/dev/null)
    SARAH_CWD=$(printf '%s' "$_sr_in" | jq -r 'if (.cwd | type) == "string" then .cwd else "" end' 2>/dev/null)
    [ -n "$SARAH_CMD" ] || exit 0
}

# sarah_segments : the simple commands of SARAH_CMD, one per line.
sarah_segments() {
    printf '%s\n' "$SARAH_CMD" | awk "$SARAH_SPLIT_AWK"
}

# sarah_parse_segment WORDS : sets SARAH_BIN (git, gh or empty), SARAH_SUB,
# SARAH_SUB2 (gh only), SARAH_ARGS and SARAH_GITDIR (git -C).
sarah_parse_segment() {
    SARAH_BIN="" SARAH_SUB="" SARAH_SUB2="" SARAH_ARGS="" SARAH_GITDIR=""
    set -f
    # shellcheck disable=SC2086
    set -- $1
    while [ $# -gt 0 ]; do
        case $1 in
            [A-Za-z_]*=* | command | exec | nohup | time) shift ;;
            env | */env)
                # env and its options that take no command: -i, -u NAME. Any
                # other option is not understood, so the command is not judged.
                shift
                while [ $# -gt 0 ]; do
                    case $1 in
                        -u | --unset) if [ $# -ge 2 ]; then shift 2; else shift; fi ;;
                        -i | -0 | -v | --ignore-environment | --null | --debug | --unset=* | --) shift ;;
                        *) break ;;
                    esac
                done
                ;;
            *) break ;;
        esac
    done
    [ $# -gt 0 ] || return 0
    case $1 in
        git | */git) SARAH_BIN=git ;;
        gh | */gh) SARAH_BIN=gh ;;
        *) return 0 ;;
    esac
    shift
    if [ "$SARAH_BIN" = git ]; then
        while [ $# -gt 0 ]; do
            case $1 in
                -C)
                    if [ $# -ge 2 ]; then SARAH_GITDIR=$2; shift 2; else shift; fi
                    ;;
                -c | --exec-path | --namespace | --super-prefix | --config-env)
                    if [ $# -ge 2 ]; then shift 2; else shift; fi
                    ;;
                -*) shift ;;
                *) break ;;
            esac
        done
        SARAH_SUB=${1:-}
        [ $# -eq 0 ] || shift
        SARAH_ARGS="$*"
    else
        while [ $# -gt 0 ]; do
            case $1 in
                -R | --repo)
                    if [ $# -ge 2 ]; then shift 2; else shift; fi
                    ;;
                -*) shift ;;
                *) break ;;
            esac
        done
        SARAH_SUB=${1:-}
        [ $# -eq 0 ] || shift
        SARAH_SUB2=${1:-}
        [ $# -eq 0 ] || shift
        SARAH_ARGS="$*"
    fi
}

# sarah_flag LONG SHORT : the value of --long VALUE, --long=VALUE or -S VALUE in
# SARAH_ARGS; status 1 when absent.
sarah_flag() {
    _sf_long=$1
    _sf_short=$2
    set -f
    # shellcheck disable=SC2086
    set -- $SARAH_ARGS
    while [ $# -gt 0 ]; do
        case $1 in
            "$_sf_long"=*)
                printf '%s\n' "${1#*=}"
                return 0
                ;;
            "$_sf_long" | "$_sf_short")
                [ $# -ge 2 ] || return 1
                printf '%s\n' "$2"
                return 0
                ;;
        esac
        shift
    done
    return 1
}

# sarah_branch DIR : the current branch of the repository at DIR, empty when
# detached or not a repository.
sarah_branch() {
    git -C "$1" symbolic-ref --short -q HEAD 2>/dev/null
}

# sarah_command_dir CWD : where a git command in the current segment runs.
sarah_command_dir() {
    case ${SARAH_GITDIR:-} in
        "") printf '%s\n' "$1" ;;
        /*) printf '%s\n' "$SARAH_GITDIR" ;;
        *) printf '%s/%s\n' "$1" "$SARAH_GITDIR" ;;
    esac
}

# sarah_run_timeout SECONDS OUT ERR COMMAND... : runs COMMAND with output in the
# two files and stops it after SECONDS. Status 124 on timeout.
sarah_run_timeout() {
    _st_secs=$1
    _st_out=$2
    _st_err=$3
    shift 3
    "$@" >"$_st_out" 2>"$_st_err" </dev/null &
    _st_pid=$!
    { sleep "$_st_secs"; kill "$_st_pid"; } >/dev/null 2>&1 &
    _st_dog=$!
    wait "$_st_pid" 2>/dev/null
    _st_rc=$?
    kill "$_st_dog" >/dev/null 2>&1
    [ "$_st_rc" -ge 128 ] && return 124
    return "$_st_rc"
}
