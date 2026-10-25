# IH7, IH8, IH11 and US11 (R10, R15, R17, R18): the dispatch guard. Each case
# runs the installed, stamped script as Claude Code does for an Agent call:
# absolute path through CLAUDE_PROJECT_DIR, JSON on stdin, a shadowed `date`.
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/habits_lib.sh"

P=$(mk_repo dg)
install_habits "$P" _lib dispatch-guard
TODAY=2026-10-24
STUB=$(stub_date "$TODAY")
GUARD="$P/sarah/hooks/dispatch-guard/guard.sh"

# agent_json TYPE MODEL ISOLATION PROMPT : MODEL/ISOLATION "-" leaves the key out.
agent_json() {
    jq -nc --arg t "$1" --arg m "$2" --arg i "$3" --arg p "$4" '
        {hook_event_name:"PreToolUse",tool_name:"Agent",cwd:"/",
         tool_input:({subagent_type:$t, description:"d", prompt:$p}
            + (if $m == "-" then {} else {model:$m} end)
            + (if $i == "-" then {} else {isolation:$i} end))}'
}

# guard TYPE MODEL ISOLATION PROMPT [PATH_PREFIX...] : sets G_OUT and G_RC.
guard() {
    t=$1 m=$2 i=$3 pr=$4
    shift 4
    G_OUT=$(
        cd "$P" || exit 0
        PATH="$STUB:$PATH"
        for x in "$@"; do PATH="$x:$PATH"; done
        export PATH
        CLAUDE_PROJECT_DIR=$P
        export CLAUDE_PROJECT_DIR
        agent_json "$t" "$m" "$i" "$pr" | sh "$GUARD" 2>&1
        echo "rc=$?"
    )
    G_RC=${G_OUT##*rc=}
    G_OUT=${G_OUT%rc=*}
}

# setting LINE... : replace the guard's lines in Settings of habits.md.
set_settings() {
    grep -v '^- \(dispatch checks\|limit\|setup\):' "$P/sarah/habits.md" >"$P/habits.tmp"
    : >"$P/ins.tmp"
    for l in "$@"; do printf '%s\n' "$l" >>"$P/ins.tmp"; done
    awk -v f="$P/ins.tmp" '{print} /^## Settings/ { print ""; while ((getline l < f) > 0) print l }' "$P/habits.tmp" >"$P/sarah/habits.md"
    rm -f "$P/habits.tmp" "$P/ins.tmp"
}

# state ROW... : sarah/state.md with the given In flight rows.
state() {
    {
        printf '# S.A.R.A.H. state\n\n## In flight\n\n| Task | File | Phase | Level | Waiting on | Since |\n| --- | --- | --- | --- | --- | --- |\n'
        for r in "$@"; do printf '%s\n' "$r"; done
        printf '\n## Pending decisions\n\n| Decision | Options | Waiting since |\n| --- | --- | --- |\n| x | y | z |\n'
    } >"$P/sarah/state.md"
}
row() { printf '| %s | `sarah/state/%s.md` | %s | 2 | nothing | 2026-10-24 |' "$1" "$1" "${2:-implement}"; }

task() { # task SLUG PREMISE-LINE...
    slug=$1
    shift
    {
        printf '# %s\n\n## Premises\n\n' "$slug"
        for l in "$@"; do printf '%s\n' "$l"; done
        printf '\n## Executor\n\nx\n'
    } >"$P/sarah/state/$slug.md"
}
mkdir -p "$P/sarah/state"

FRESH="- $TODAY - the parser still returns a list"
PROMPT="Do step 3 of sarah/state/alpha.md and report."
task alpha "$FRESH"
state "$(row alpha)"

# --- installed and registered
cmd=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Agent") | .hooks[].command' "$P/.claude/settings.json" 2>/dev/null)
assert_contains "settings register the guard on the Agent matcher" "$cmd" 'sh "$CLAUDE_PROJECT_DIR/sarah/hooks/dispatch-guard/guard.sh"'
assert_eq "baseRef is installed" head "$(jq -r '.worktree.baseRef' "$P/.claude/settings.json")"
assert_contains "the worktree include list holds the personal settings file" "$(cat "$P/.worktreeinclude")" ".claude/settings.local.json"

# --- a compliant dispatch passes (checks line absent: all three run)
guard sarah:executor sonnet worktree "$PROMPT";    assert_rc "compliant dispatch" 0
guard executor sonnet worktree "$PROMPT";          assert_rc "compliant dispatch, bare agent name" 0

# --- other agents are untouched, however wrong the call looks (IH7)
state "$(row a)" "$(row b)" "$(row c)" "$(row d)" "$(row e)"
guard Explore - - "no task file here";             assert_rc "another agent without model, over the limit" 0
guard sarah:code-reviewer - - "x";                 assert_rc "the reviewer agent" 0
guard "" - - "x";                                  assert_rc "no subagent_type" 0
state "$(row alpha)"

# --- model (R10)
guard sarah:executor - worktree "$PROMPT";         assert_rc "no model" 2
assert_contains "block names the rule" "$G_OUT" "dispatch-model"
assert_contains "block names the exception path" "$G_OUT" "named exception"
guard executor "" worktree "$PROMPT";              assert_rc "empty model" 2
guard executor "   " worktree "$PROMPT";           assert_rc "blank model" 2
add_exception "$P" dispatch-model "pilot run on the default model" 2026-10-30 2026-10-24
guard executor - worktree "$PROMPT";               assert_rc "a valid exception lets a missing model through" 0
assert_contains "the exception use is announced" "$G_OUT" "Exception in use: dispatch-model"
add_exception "$P" dispatch-limit "unrelated rule" 2026-10-30 2026-10-24
set_settings "- dispatch checks: model"
state "$(row alpha)"
guard executor - worktree "$PROMPT";               assert_rc "exception for the model rule only" 0
# a lapsed exception no longer counts
sed -i '/dispatch-model/d' "$P/sarah/habits.md"
add_exception "$P" dispatch-model "old" 2026-10-20 2026-10-10
guard executor - worktree "$PROMPT";               assert_rc "an expired exception does not lift the rule" 2
sed -i '/dispatch-model/d;/dispatch-limit/d' "$P/sarah/habits.md"

# --- which checks are on
set_settings "- dispatch checks: limit"
state "$(row a)" "$(row b)" "$(row c)" "$(row d)"
guard executor - worktree "no task named";         assert_rc "limit alone: over the limit is refused" 2
state "$(row a)"
guard executor - worktree "no task named";         assert_rc "limit alone: no model and no task file pass" 0
set_settings "- dispatch checks: model"
state "$(row a)" "$(row b)" "$(row c)" "$(row d)"
guard executor sonnet - "no task named";           assert_rc "model alone: over the limit and no isolation pass" 0
set_settings "- dispatch checks: premise"
guard executor - - "$PROMPT";                      assert_rc "premise alone: a fresh task passes without model" 0
set_settings "- dispatch checks: none"
guard executor - - "no task named";                assert_rc "no check chosen" 0
set_settings "- dispatch checks: model, nonsense"
guard executor - worktree "x";                     assert_rc "an unknown name is ignored, model still runs" 2
set_settings "- dispatch checks: Model , PREMISE"
guard executor - worktree "x";                     assert_rc "names are case-insensitive and spaced" 2
set_settings "- dispatch checks: model, premise, limit"

# --- limit (R17, R18), IH7
set_settings "- dispatch checks: model, limit" "- limit: 3"
state "$(row a)" "$(row b)" "$(row c)"
guard executor sonnet worktree "x";                assert_rc "limit 3, three in progress" 0
state "$(row a)" "$(row b)" "$(row c)" "$(row d)"
guard executor sonnet worktree "x";                assert_rc "limit 3, four in progress" 2
assert_contains "refusal names the rule" "$G_OUT" "dispatch-limit"
assert_contains "refusal lists the running tasks" "$G_OUT" "a; b; c; d"
assert_contains "refusal gives the numbers" "$G_OUT" "4"
set_settings "- dispatch checks: model, limit" "- limit: 2"
state "$(row a)" "$(row b)"
guard executor sonnet worktree "x";                assert_rc "limit 2, two in progress (limit)" 0
state "$(row a)"
guard executor sonnet worktree "x";                assert_rc "limit 2, one in progress (limit - 1)" 0
state "$(row a)" "$(row b)" "$(row c)"
guard executor sonnet worktree "x";                assert_rc "limit 2, three in progress" 2
set_settings "- dispatch checks: model, limit"
state "$(row a)" "$(row b)" "$(row c)" "$(row d)"
guard executor sonnet worktree "x";                assert_rc "no limit line: the default is 3" 2
state "$(row a)" "$(row b)" "$(row c)"
guard executor sonnet worktree "x";                assert_rc "no limit line: three pass" 0
set_settings "- dispatch checks: model, limit" "- limit: 5"
state "$(row a)" "$(row b)" "$(row c)" "$(row d)" "$(row e)"
guard executor sonnet worktree "x";                assert_rc "limit 5, five in progress" 0
state "$(row a)" "$(row b)" "$(row c)" "$(row d)" "$(row e)" "$(row f)"
guard executor sonnet worktree "x";                assert_rc "limit 5, six in progress" 2
set_settings "- dispatch checks: model, limit" "- limit: 2"
state "$(row a)" "$(row b)" "$(row c ready)" "$(row d ready)"
guard executor sonnet worktree "x";                assert_rc "ready rows are not in progress" 0
state "$(row a)" "$(row b)" "| {{task}} | {{file}} | {{phase}} | {{level}} | nothing | {{date}} |"
guard executor sonnet worktree "x";                assert_rc "a template row is not counted" 0
state "| _nothing in flight_ | | | | | |"
guard executor sonnet worktree "x";                assert_rc "the empty-index row is not counted" 0
add_exception "$P" dispatch-limit "release crunch" 2026-10-30 2026-10-24
state "$(row a)" "$(row b)" "$(row c)"
guard executor sonnet worktree "x";                assert_rc "an exception lifts the limit" 0
sed -i '/dispatch-limit/d' "$P/sarah/habits.md"

# bad limit: not a finding, so the count is not enforced, and the guard says so
for bad in "many" "0" "-1" "3x" "" "1000" "2.5"; do
    set_settings "- dispatch checks: model, limit" "- limit: $bad"
    state "$(row a)" "$(row b)" "$(row c)" "$(row d)" "$(row e)"
    guard executor sonnet worktree "x";            assert_rc "bad limit '$bad' is not enforced" 0
    assert_contains "bad limit '$bad' is announced" "$G_OUT" "Rule not checked: dispatch-limit"
done
set_settings "- dispatch checks: model, limit" "- limit: many"
guard executor sonnet - "x";                       assert_rc "bad limit: the isolation rule still applies" 2

# isolation: each task gets its own copy
set_settings "- dispatch checks: model, limit" "- limit: 3"
state "$(row a)"
guard executor sonnet - "x";                       assert_rc "no isolation" 2
assert_contains "isolation refusal says why" "$G_OUT" "own copy"
guard executor sonnet none "x";                    assert_rc "isolation other than worktree" 2
guard executor sonnet worktree "x";                assert_rc "isolation worktree" 0

# no readable state: the count could not be taken
rm -f "$P/sarah/state.md"
guard executor sonnet worktree "x";                assert_rc "no state.md" 0
assert_contains "no state.md is announced" "$G_OUT" "Rule not checked: dispatch-limit"

# --- premise (R15), IH8
set_settings "- dispatch checks: premise"
state "$(row alpha)"
task alpha "$FRESH"
guard executor sonnet worktree "$PROMPT";          assert_rc "premise dated today" 0
task alpha "- 2026-10-23 - yesterday"
guard executor sonnet worktree "$PROMPT";          assert_rc "premise dated yesterday" 2
assert_contains "refusal names the rule" "$G_OUT" "dispatch-premise"
assert_contains "refusal says to re-check against code and decisions" "$G_OUT" "sarah/decisions.md"
assert_contains "refusal says to ask one question with evidence" "$G_OUT" "one question"
assert_contains "refusal names the task file" "$G_OUT" "sarah/state/alpha.md"
task alpha "- 2026-10-25 - tomorrow"
guard executor sonnet worktree "$PROMPT";          assert_rc "premise dated in the future" 2
task alpha "$FRESH" "- 2026-10-01 - stale one"
guard executor sonnet worktree "$PROMPT";          assert_rc "one stale line among fresh ones" 2
task alpha "$FRESH" "- $TODAY - another"
guard executor sonnet worktree "$PROMPT";          assert_rc "two fresh lines" 0
task alpha "- $TODAY - none"
guard executor sonnet worktree "$PROMPT";          assert_rc "a task that assumes nothing says so, dated" 0
task alpha "the parser returns a list"
guard executor sonnet worktree "$PROMPT";          assert_rc "an undated line is not a check" 2
task alpha
guard executor sonnet worktree "$PROMPT";          assert_rc "empty Premises section" 2
printf '# alpha\n\n## Executor\n\nx\n' >"$P/sarah/state/alpha.md"
guard executor sonnet worktree "$PROMPT";          assert_rc "no Premises section" 2
printf '# alpha\n\n## Premises\n\n<!-- one line each\n- 2026-10-01 - inside a comment\n-->\n\n- %s - real\n' "$TODAY" >"$P/sarah/state/alpha.md"
guard executor sonnet worktree "$PROMPT";          assert_rc "lines inside an HTML comment are ignored" 0
printf '# alpha\n\n## Premises\n\n- %s - real\n\n## Notes\n\n- 2026-01-01 - not a premise\n' "$TODAY" >"$P/sarah/state/alpha.md"
guard executor sonnet worktree "$PROMPT";          assert_rc "a bullet in another section is not a premise" 0
rm -f "$P/sarah/state/alpha.md"
guard executor sonnet worktree "$PROMPT";          assert_rc "the named task file does not exist" 2
task alpha "$FRESH"
guard executor sonnet worktree "no file named in this brief"; assert_rc "the brief names no task file" 2
assert_contains "refusal says the brief must name it" "$G_OUT" "task file"
task other "- 2026-10-01 - stale"
guard executor sonnet worktree "first sarah/state/alpha.md then sarah/state/other.md"; assert_rc "the first task file named binds the task" 0
guard executor sonnet worktree "an absolute $P/sarah/state/alpha.md path"; assert_rc "an absolute path names the task file" 0
guard executor sonnet worktree "sarah/state/../../etc/passwd.md"; assert_rc "a traversal-shaped name binds nothing outside state/" 2
# no prompt key at all: the check could not run
G_OUT=$(
    cd "$P" || exit 0
    PATH="$STUB:$PATH"
    export PATH
    CLAUDE_PROJECT_DIR=$P
    export CLAUDE_PROJECT_DIR
    printf '{"tool_name":"Agent","tool_input":{"subagent_type":"sarah:executor","model":"sonnet"}}' | sh "$GUARD" 2>&1
    echo "rc=$?"
)
G_RC=${G_OUT##*rc=}
assert_rc "no prompt key: allowed" 0
assert_contains "no prompt key: says the check could not run" "$G_OUT" "Rule not checked: dispatch-premise"
add_exception "$P" dispatch-premise "the task was checked by hand" 2026-10-30 2026-10-24
task alpha "- 2026-10-01 - stale"
guard executor sonnet worktree "$PROMPT";          assert_rc "an exception lifts the premise check" 0
sed -i '/dispatch-premise/d' "$P/sarah/habits.md"

# --- without the shared library it allows and says so
set_settings "- dispatch checks: model, premise, limit"
mv "$P/sarah/hooks/_lib" "$P/sarah/hooks/_lib.off"
guard executor - worktree "$PROMPT";               assert_rc "no library" 0
assert_contains "no library is announced" "$G_OUT" "Rule not checked"
mv "$P/sarah/hooks/_lib.off" "$P/sarah/hooks/_lib"

# --- no jq, and the default checks line: everything fails open
NJ=$(no_jq_path)
G_OUT=$(
    cd "$P" || exit 0
    PATH="$NJ"
    export PATH
    CLAUDE_PROJECT_DIR=$P
    export CLAUDE_PROJECT_DIR
    printf '{"tool_input":{"subagent_type":"executor"}}' | sh "$GUARD" 2>&1
    echo "rc=$?"
)
G_RC=${G_OUT##*rc=}
assert_rc "no jq: allowed" 0
assert_contains "no jq is announced" "$G_OUT" "jq is not installed"

# --- IH11: whatever arrives, the exit code is 0 or 2, never 1
state "$(row alpha)"
task alpha "$FRESH"
fuzz() { # fuzz NAME : stdin is the input; checks the code
    out=$(cd "$P" && PATH="$STUB:$PATH" CLAUDE_PROJECT_DIR=$P sh "$GUARD" 2>/dev/null)
    rc=$?
    case $rc in 0 | 2) ok "fuzz: $1 -> $rc" ;; *) fail "fuzz: $1" "exit $rc" ;; esac
}
printf '' | fuzz "empty input"
printf 'not json' | fuzz "invalid JSON"
printf '[]' | fuzz "a JSON array"
printf 'null' | fuzz "null"
printf '"str"' | fuzz "a string"
printf '{}' | fuzz "empty object"
printf '{"tool_input":null}' | fuzz "null tool_input"
printf '{"tool_input":"x"}' | fuzz "string tool_input"
printf '{"tool_input":{"subagent_type":7,"model":[],"prompt":{}}}' | fuzz "wrong types"
printf '{"tool_input":{"subagent_type":"executor","model":7,"prompt":7,"isolation":[]}}' | fuzz "executor with wrong types"
printf '{"tool_input":{"subagent_type":"executor","model":null,"prompt":null}}' | fuzz "executor with nulls"
printf '{"tool_input":{"subagent_type":"sarah:executor","model":"sonnet","isolation":"worktree","prompt":"sarah/state/alpha.md"}}' | fuzz "a good call"
dd if=/dev/zero bs=1024 count=1024 2>/dev/null | tr '\0' 'a' >"$T_TMP/big"
jq -nc --rawfile p "$T_TMP/big" '{tool_input:{subagent_type:"executor",model:"sonnet",isolation:"worktree",prompt:$p}}' | fuzz "1 MB prompt"
printf '\377\376{"tool_input"' | fuzz "binary garbage"
printf '{"tool_input":{"subagent_type":"executor","prompt":"sarah/state/a\\u0000b.md"}}' | fuzz "NUL in the task name"
rm -f "$P/sarah/state.md"
printf '{"tool_input":{"subagent_type":"executor","model":"sonnet","isolation":"worktree","prompt":"x"}}' | fuzz "no state file"
printf '# habits\n\n## Settings\n\n- limit: \x01\x02\n- dispatch checks: \xff\n' >"$P/sarah/habits.md"
printf '{"tool_input":{"subagent_type":"executor","model":"sonnet","isolation":"worktree","prompt":"x"}}' | fuzz "garbage habits.md"
rm -f "$P/sarah/habits.md"
printf '{"tool_input":{"subagent_type":"executor","prompt":"x"}}' | fuzz "no habits.md"

# --- US11: the guard counts In flight rows the way the session-start hook does
install_habits "$P" _lib dispatch-guard
set_settings "- dispatch checks: limit" "- limit: 50"
sessions_count() {
    out=$(cd "$P" && printf '{"cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$P" | env -u CLAUDE_PROJECT_DIR sh "$ROOT/hooks/scripts/session-start.sh" 2>/dev/null)
    n=$(printf '%s\n' "$out" | sed -n 's/.*In flight: \([0-9][0-9]*\) task.*/\1/p' | head -n 1)
    echo "${n:-0}"
}
guard_count() { # the smallest limit at which the guard allows
    n=1
    while [ "$n" -le 20 ]; do
        set_settings "- dispatch checks: limit" "- limit: $n"
        guard executor sonnet worktree "x"
        [ "$G_RC" = 0 ] && { echo "$n"; return; }
        n=$((n + 1))
    done
    echo 99
}
tpl='| {{task}} | {{file}} | {{phase}} | {{level}} | {{who}} | {{date}} |'
for shape in 1 2 3 4; do
    case $shape in
        1) state "$(row a)" "$(row b)" ;;
        2) state "$(row a)" "$tpl" "$(row b)" "$(row c)" ;;
        3) state "$(row a)" "| _nothing in flight_ | | | | | |" "$(row b)" "$(row c)" "$(row d)" ;;
        4) state "$tpl" "$tpl" "$(row a)" "$(row b)" "$(row c)" "$(row d)" "$(row e)" ;;
    esac
    s=$(sessions_count)
    g=$(guard_count)
    assert_eq "US11 shape $shape: guard and session-start agree on the count" "$s" "$g"
done
# a header-only index counts zero in both
state
assert_eq "US11 empty index: session-start" 0 "$(sessions_count)"
assert_eq "US11 empty index: guard allows at limit 1" 1 "$(guard_count)"
# the one deliberate difference: ready rows are counted by session-start, not by the guard
state "$(row a)" "$(row b)" "$(row c ready)" "$(row d ready)"
assert_eq "US11 ready rows: session-start counts them" 4 "$(sessions_count)"
assert_eq "US11 ready rows: the guard does not" 2 "$(guard_count)"

t_end
