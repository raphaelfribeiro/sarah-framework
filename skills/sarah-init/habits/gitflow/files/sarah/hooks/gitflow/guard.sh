# R13 gitflow guard: a project hook, installed by /sarah-init at the user's
# choice and owned by this project. PreToolUse on Bash; reads the tool call as
# JSON on stdin. It refuses, with exit 2 and a message that reaches the agent:
#   - a commit on main or develop
#   - a push to main or develop
#   - a pull request whose base breaks the branch model
#   - a merge before `gh pr checks` is green
#   - a Co-Authored-By line, unless the project chose `- attribution: on`
# It blocks only on a positive finding. A missing tool or an unreadable answer
# means the rule was not checked: it says so and allows. A valid, unexpired
# exception (R16) in sarah/habits.md lets a call through and is logged.
# Exit 0 allows, exit 2 blocks, and nothing else is ever returned.
rule=gitflow
here=$(cd "$(dirname "$0")" && pwd)
if [ ! -f "$here/../_lib/exceptions.sh" ] || [ ! -f "$here/model.sh" ]; then
    printf 'Rule not checked: %s (the shared library is not installed). I let it through.\n' "$rule" >&2
    exit 0
fi
. "$here/../_lib/exceptions.sh"
. "$here/model.sh"
project=${CLAUDE_PROJECT_DIR:-$(cd "$here/../../.." && pwd)}

sarah_read_input "$rule"
cwd=${SARAH_CWD:-$PWD}

# deny WHAT ROUTE : an exception lets the call through; otherwise it is refused.
deny() {
    if sarah_exception_honored "$project" "$rule"; then
        return 0
    fi
    sarah_block "$rule" "$1" "$2"
}

protected() {
    case $1 in main | develop) return 0 ;; esac
    return 1
}

attribution_on() {
    grep -q '^- attribution: on[[:space:]]*$' "$project/sarah/habits.md" 2>/dev/null
}

check_commit() {
    dir=$(sarah_command_dir "$cwd")
    branch=$(sarah_branch "$dir")
    if protected "$branch"; then
        deny "saving straight onto $branch breaks your project rules" "Create a branch for the work (git switch -c feature/<name>), commit there, and open a pull request into develop."
    fi
    if ! attribution_on && printf '%s' "$SARAH_CMD" | grep -qi 'co-authored-by:'; then
        deny "this project turned commit attribution off, and the message has a Co-Authored-By line" "Remove that line from the message and commit again."
    fi
}

check_push() {
    dir=$(sarah_command_dir "$cwd")
    branch=$(sarah_branch "$dir")
    set -f
    # shellcheck disable=SC2086
    set -- $SARAH_ARGS
    positional=""
    tags=0
    skip=0
    while [ $# -gt 0 ]; do
        if [ "$skip" = 1 ]; then
            skip=0
            shift
            continue
        fi
        case $1 in
            --all | --mirror)
                deny "pushing with $1 sends main and develop too" "Push the branch by name: git push origin feature/<name>."
                ;;
            --tags) tags=1 ;;
            --repo | -o | --push-option | --receive-pack | --exec) skip=1 ;;
            -*) ;;
            *) positional="$positional $1" ;;
        esac
        shift
    done
    # shellcheck disable=SC2086
    set -- $positional
    if [ $# -le 1 ]; then
        # --tags with no refspec pushes refs/tags/* and nothing else: it does not
        # touch a branch, and a release has to push its tag from develop or main.
        # Only that exact shape is let through; --follow-tags (which also pushes
        # the branch) and any named refspec still take the checks below.
        [ "$tags" = 1 ] && return 0
        if protected "$branch"; then
            deny "pushing $branch straight to the origin breaks your project rules" "Push a feature/* branch and open a pull request into develop."
        fi
        return 0
    fi
    shift
    for spec in "$@"; do
        spec=${spec#+}
        dst=${spec##*:}
        dst=${dst#refs/heads/}
        [ "$dst" = HEAD ] && dst=$branch
        if protected "$dst"; then
            deny "pushing to $dst breaks your project rules" "Push a feature/* branch and open a pull request into develop."
        fi
    done
}

check_pr_create() {
    base=$(sarah_flag --base -B)
    head=$(sarah_flag --head -H)
    head=${head#*:}
    if [ -z "$head" ]; then
        head=$(sarah_branch "$(sarah_command_dir "$cwd")")
    fi
    if [ -z "$base" ]; then
        sarah_say_unchecked "$rule" "the pull request names no --base"
        return 0
    fi
    if [ -z "$head" ]; then
        sarah_say_unchecked "$rule" "the branch of the pull request is unknown"
        return 0
    fi
    if why=$(sarah_gitflow_violation "$base" "$head"); then
        deny "this pull request breaks the branch model: $why" "Open it against the right base (feature/* into develop; release/* and hotfix/* into main), see docs/branching.md."
    fi
}

check_pr_merge() {
    if ! command -v gh >/dev/null 2>&1; then
        sarah_say_unchecked "$rule" "gh is not installed"
        return 0
    fi
    set -f
    # shellcheck disable=SC2086
    set -- $SARAH_ARGS
    selector=""
    repo=""
    auto=0
    while [ $# -gt 0 ]; do
        case $1 in
            -R | --repo)
                if [ $# -ge 2 ]; then repo=$2; shift; fi
                ;;
            --repo=*) repo=${1#--repo=} ;;
            -R=*) repo=${1#-R=} ;;
            --auto) auto=1 ;;
            -b | --body | -F | --body-file | -t | --subject | -A | --author-email | --match-head-commit)
                [ $# -ge 2 ] && shift
                ;;
            -*) ;;
            *) [ -n "$selector" ] || selector=$1 ;;
        esac
        shift
    done
    out=$(mktemp 2>/dev/null) || {
        sarah_say_unchecked "$rule" "no temporary file"
        return 0
    }
    err=$(mktemp 2>/dev/null) || {
        rm -f "$out"
        sarah_say_unchecked "$rule" "no temporary file"
        return 0
    }
    # The checks are read in the repository the merge names (-R/--repo), not the
    # one the shell happens to be in.
    if [ -n "$repo" ]; then
        # shellcheck disable=SC2086
        sarah_run_timeout 10 "$out" "$err" gh pr checks $selector -R "$repo" --json name,bucket
    else
        # shellcheck disable=SC2086
        sarah_run_timeout 10 "$out" "$err" gh pr checks $selector --json name,bucket
    fi
    rc=$?
    verdict=$(jq -r '
        if type != "array" then "garbage"
        elif length == 0 then "none"
        else ([.[] | select(.bucket == "fail" or .bucket == "cancel") | .name] | join(", ")) as $f
           | ([.[] | select(.bucket == "pending") | .name] | join(", ")) as $p
           | if $f != "" then "fail:" + $f elif $p != "" then "pending:" + $p else "pass" end
        end' "$out" 2>/dev/null)
    if [ -z "$verdict" ] && grep -qi 'no checks reported' "$err" 2>/dev/null; then
        verdict=none
    fi
    rm -f "$out" "$err"
    route="Wait for the checks and merge once they are green; fix any that fail."
    case $verdict in
        pass) ;;
        fail:*) deny "merging waits for green CI, and these checks are failing: ${verdict#fail:}" "$route" ;;
        pending:*)
            # --auto merges only once the checks pass: it is the safe way to wait.
            [ "$auto" = 1 ] && return 0
            deny "merging waits for green CI, and these checks are still running: ${verdict#pending:}" "$route"
            ;;
        none) deny "merging waits for green CI, and this pull request has no checks" "Wait for the checks to be reported, then merge." ;;
        *)
            if [ "$rc" = 124 ]; then
                sarah_say_unchecked "$rule" "gh did not answer in time"
            else
                sarah_say_unchecked "$rule" "gh pr checks gave no usable answer"
            fi
            ;;
    esac
}

segments=$(sarah_segments)
while IFS= read -r seg; do
    sarah_parse_segment "$seg"
    case $SARAH_BIN:$SARAH_SUB:$SARAH_SUB2 in
        git:commit:*) check_commit ;;
        git:push:*) check_push ;;
        gh:pr:create) check_pr_create ;;
        gh:pr:merge) check_pr_merge ;;
    esac
done <<SEGMENTS
$segments
SEGMENTS
exit 0
