# R14 changelog fragment: a project hook, installed by /sarah-init at the user's
# choice and owned by this project. PreToolUse on Bash. It refuses `gh pr create`
# unless the branch adds a sarah/changelog/*.md entry (relative to the pull
# request's base, default develop) that carries one marked line:
#
#   User-facing: <one sentence a user of the project would understand>
#
# The line starts the line, with that exact spelling. The hook checks that the
# line exists and is not a placeholder (empty, <...>, TODO, TBD and similar). It
# does not judge the sentence. The release notes read this line.
# It blocks only on a positive finding. An unknown base or a missing tool means
# the rule was not checked: it says so and allows. A valid, unexpired exception
# (R16) lets a call through and is logged. Exit 0 allows, exit 2 blocks.
rule=changelog-fragment
here=$(cd "$(dirname "$0")" && pwd)
if [ ! -f "$here/../_lib/exceptions.sh" ]; then
    printf 'Rule not checked: %s (the shared library is not installed). I let it through.\n' "$rule" >&2
    exit 0
fi
. "$here/../_lib/exceptions.sh"
project=${CLAUDE_PROJECT_DIR:-$(cd "$here/../../.." && pwd)}

sarah_read_input "$rule"
cwd=${SARAH_CWD:-$PWD}

# has_line FILE-CONTENT : 0 when a real User-facing line is present.
has_line() {
    printf '%s\n' "$1" | tr -d '\r' | sed -n 's/^User-facing:[[:space:]]*//p' | while IFS= read -r sentence; do
        sentence=$(printf '%s' "$sentence" | sed 's/[[:space:]]*$//')
        lower=$(printf '%s' "$sentence" | tr 'A-Z' 'a-z')
        case $lower in
            "" | todo | tbd | fixme | n/a | none | - | ... | "<"*">") ;;
            *)
                echo found
                break
                ;;
        esac
    done | grep -q found
}

check_pr_create() {
    base=$(sarah_flag --base -B) || base=develop
    dir=$(sarah_command_dir "$cwd")
    top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$top" ]; then
        sarah_say_unchecked "$rule" "this is not a git repository"
        return 0
    fi
    ref=""
    for candidate in "refs/remotes/origin/$base" "refs/heads/$base"; do
        if git -C "$top" rev-parse --verify -q "$candidate" >/dev/null 2>&1; then
            ref=$candidate
            break
        fi
    done
    if [ -z "$ref" ]; then
        sarah_say_unchecked "$rule" "the base branch $base is not known here"
        return 0
    fi
    added=$(git -C "$top" -c core.quotepath=off diff --name-only --diff-filter=A "$ref...HEAD" -- sarah/changelog 2>/dev/null)
    while IFS= read -r file; do
        case $file in
            sarah/changelog/*.md) ;;
            *) continue ;;
        esac
        if has_line "$(git -C "$top" show "HEAD:$file" 2>/dev/null)"; then
            return 0
        fi
    done <<ADDED
$added
ADDED
    if sarah_exception_honored "$project" "$rule"; then
        return 0
    fi
    sarah_block "$rule" "sending this for review needs a release-note line, and no entry added on this branch has one" "Add a sarah/changelog/ entry on this branch with a line that starts exactly \"User-facing: \" followed by one sentence a user would understand, commit it (an entry that is not committed is not on the branch), and run this again."
}

segments=$(sarah_segments)
while IFS= read -r seg; do
    sarah_parse_segment "$seg"
    case $SARAH_BIN:$SARAH_SUB:$SARAH_SUB2 in
        gh:pr:create) check_pr_create ;;
    esac
done <<SEGMENTS
$segments
SEGMENTS
exit 0
