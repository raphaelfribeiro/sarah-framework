# Helpers for the installed-habit tests (exceptions, gitflow, changelog).
# Source it after lib.sh; it is not a test and run.sh does not pick it up.
#
# Payloads are installed with the real engine, so the files under test are the
# stamped copies a user's project would hold. Tools are mocked by shadowing them
# on PATH (see stub_date in lib.sh); nothing here reaches the network.

# mk_repo NAME [BRANCH] : a git repo on develop with one commit and a remote
# that points nowhere, so `requires: remote` is met without a network.
mk_repo() {
    r=$(new_dir "repo-$1")
    (
        cd "$r" || exit 0
        git init -q -b develop . >/dev/null 2>&1 || git init -q . >/dev/null 2>&1
        git checkout -q -b develop 2>/dev/null
        git config user.email "dev@example.invalid"
        git config user.name "Dev Example"
        git config commit.gpgsign false
        git remote add origin "$r/.git-remote-nowhere"
        printf 'seed\n' >README.md
        git add README.md
        git commit -q -m "seed"
    )
    echo "$r"
}

# stub_gh NAME : a stub `gh` directory. Its answer is read from files beside it:
# checks.out (stdout), checks.err (stderr), checks.rc (exit code), or hang.
stub_gh() {
    d=$(new_dir "gh-$1")
    cat >"$d/gh" <<'GH'
#!/bin/sh
here=$(dirname "$0")
if [ -f "$here/hang" ]; then exec sleep 60; fi
[ -f "$here/checks.out" ] && cat "$here/checks.out"
[ -f "$here/checks.err" ] && cat "$here/checks.err" >&2
rc=0
[ -f "$here/checks.rc" ] && rc=$(cat "$here/checks.rc")
exit "$rc"
GH
    chmod +x "$d/gh"
    echo "$d"
}

# install_habits PROJECT HABIT... : apply through scripts/habits.py with a stub
# gh on PATH (the engine checks for it) and no output unless it fails.
install_habits() {
    p=$1
    shift
    gd=$(stub_gh "install-$(basename "$p")")
    out=$(PATH="$gd:$PATH" python3 "$ROOT/scripts/habits.py" --project "$p" --plugin-root "$ROOT" apply "$@" 2>&1) ||
        fail "install $*" "$out"
}

# add_exception PROJECT RULE REASON EXPIRES GRANTED_DATE : one row, as a user would.
add_exception() {
    printf '| %s | %s | %s | the user | %s |\n' "$2" "$3" "$4" "$5" >>"$1/sarah/habits.md"
}

# hook_json CWD COMMAND : the PreToolUse input Claude Code sends for a Bash call.
hook_json() {
    jq -nc --arg c "$2" --arg d "$1" '{hook_event_name:"PreToolUse",tool_name:"Bash",cwd:$d,tool_input:{command:$c}}'
}

# run_hook_script PROJECT HABIT FILE CWD COMMAND [PATH_PREFIX ...]
# Runs sarah/hooks/HABIT/FILE the way Claude Code does: absolute path through
# CLAUDE_PROJECT_DIR, cwd as given, JSON on stdin. Sets G_OUT (stdout+stderr)
# and G_RC.
run_hook_script() {
    p=$1 habit=$2 file=$3 cwd=$4 cmd=$5
    shift 5
    prefix=""
    for x in "$@"; do prefix="$x:$prefix"; done
    G_OUT=$(
        cd "$cwd" || exit 0
        PATH="$prefix$PATH"
        export PATH
        CLAUDE_PROJECT_DIR=$p
        export CLAUDE_PROJECT_DIR
        hook_json "$cwd" "$cmd" | sh "$p/sarah/hooks/$habit/$file" 2>&1
        echo "rc=$?"
    )
    G_RC=${G_OUT##*rc=}
    G_OUT=${G_OUT%rc=*}
}

assert_rc() {
    assert_eq "$1" "$2" "$G_RC"
}
