# IH9 (R24): the no-idle Stop hook. It blocks once, only on a positive finding,
# and allows on everything else. Dates come from a `date` shadowed on PATH.
. "$(dirname "$0")/lib.sh"

SCRIPT="$ROOT/skills/sarah-init/habits/no-idle/files/sarah/hooks/no-idle/stop.sh"
TODAY=2026-10-24
STUB=$(stub_date "$TODAY")
ACTIVE='"stop_hook_active":false'

# state PROJECT ROWS... : replace the In flight table with the given rows.
state() {
    p=$1
    shift
    {
        printf '# S.A.R.A.H. state\n\n## In flight\n\n'
        printf '| Task | File | Phase | Level | Waiting on | Since |\n| --- | --- | --- | --- | --- | --- |\n'
        for row in "$@"; do printf '%s\n' "$row"; done
        printf '\n## Carried forward\n\n- a lesson | with a pipe | and nothing else\n'
    } >"$p/sarah/state.md"
}

# run_stop PROJECT STDIN [PATH_PREFIX] : sets CODE, ERR and OUT.
run_stop() {
    (
        cd "$1" || exit 99
        [ -z "${3:-}" ] || PATH="$3:$PATH"
        export PATH
        unset CLAUDE_PROJECT_DIR
        printf '%s' "$2" | sh "$SCRIPT"
    ) >"$T_TMP/stdout" 2>"$T_TMP/stderr"
    CODE=$?
    ERR=$(cat "$T_TMP/stderr")
    OUT=$(cat "$T_TMP/stdout")
}

READY='| Next thing | `sarah/state/next.md` | ready | 2 | nothing | 2026-10-24 |'
BUSY='| Doing thing | `sarah/state/doing.md` | implement | 2 | nothing | 2026-10-24 |'
ASKING='| Asking thing | `sarah/state/asking.md` | spec | 2 | You, since 2026-10-20 | 2026-10-20 |'
CIWAIT='| CI thing | `sarah/state/ci.md` | review | 2 | CI | 2026-10-20 |'

# The safety against a loop comes first: stop_hook_active allows, whatever else holds.
p=$(mk_project active)
state "$p" "$READY"
run_stop "$p" '{"stop_hook_active":true}' "$STUB"
assert_eq "stop_hook_active allows with ready work" 0 "$CODE"
assert_eq "stop_hook_active says nothing" "" "$ERR"
run_stop "$p" '{"hook_event_name":"Stop","stop_hook_active":true,"cwd":"/x"}' "$STUB"
assert_eq "stop_hook_active allows with other fields around it" 0 "$CODE"
run_stop "$p" '{"stop_hook_active": true}' "$STUB"
assert_eq "stop_hook_active allows with JSON spacing" 0 "$CODE"
run_stop "$p" '{"stop_hook_active":"true"}' "$STUB"
assert_eq "a stop_hook_active that is not a boolean false allows" 0 "$CODE"

# The one positive finding: ready work, nothing in progress, nobody waiting on the user.
p=$(mk_project block)
state "$p" "$READY"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "ready work and nothing in progress blocks" 2 "$CODE"
assert_contains "the reason names the next task" "$ERR" "Next thing"
assert_contains "the reason tells the agent to take it" "$ERR" "Next up"
assert_eq "a block writes nothing to stdout" "" "$OUT"
run_stop "$p" '{"hook_event_name":"Stop"}' "$STUB"
assert_eq "an absent stop_hook_active counts as not active" 2 "$CODE"

# A task in progress, or one waiting on the user, allows.
p=$(mk_project busy)
state "$p" "$BUSY" "$READY"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "a task in progress allows" 0 "$CODE"
assert_eq "an allow says nothing" "" "$ERR"

p=$(mk_project asking)
state "$p" "$ASKING" "$READY"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "a task waiting on the user allows" 0 "$CODE"

p=$(mk_project asking-user)
state "$p" '| Q | `sarah/state/q.md` | spec | 2 | the user to decide | 2026-10-20 |' "$READY"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "waiting on 'the user' allows" 0 "$CODE"

p=$(mk_project ci)
state "$p" "$CIWAIT" "$READY"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "a task waiting on something else is not in progress" 2 "$CODE"

p=$(mk_project youngster)
state "$p" '| Yourself | `sarah/state/y.md` | spec | 2 | CI for youth | 2026-10-20 |' "$READY"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "'you' inside another word is not the user" 2 "$CODE"

# Nothing ready.
p=$(mk_project none)
state "$p"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "an empty In flight table allows" 0 "$CODE"
p=$(mk_project none2)
state "$p" "$CIWAIT"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "no ready work allows" 0 "$CODE"
p=$(mk_project template)
state "$p" '| {{one line}} | `sarah/state/{{slug}}.md` | ready | {{0-3}} | nothing | {{DATE}} |'
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "an unfilled template row is not work" 0 "$CODE"

# The stop marker: honoured on its date only.
p=$(mk_project marker)
state "$p" "$READY"
mkdir -p "$p/sarah/.local"
echo "$TODAY" >"$p/sarah/.local/stop-requested"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "a marker dated today allows" 0 "$CODE"
printf '%s' "$TODAY" >"$p/sarah/.local/stop-requested"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "a marker with no trailing newline allows" 0 "$CODE"
echo "2026-10-23" >"$p/sarah/.local/stop-requested"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "a marker dated yesterday has expired and blocks" 2 "$CODE"
echo "2026-10-25" >"$p/sarah/.local/stop-requested"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "a marker dated tomorrow is not today and blocks" 2 "$CODE"
echo "stop please" >"$p/sarah/.local/stop-requested"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "a marker that is not a date fails open" 0 "$CODE"
: >"$p/sarah/.local/stop-requested"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "an empty marker fails open" 0 "$CODE"
rm "$p/sarah/.local/stop-requested"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "no marker blocks" 2 "$CODE"

# Fail open: anything unexpected allows, silently.
p=$(mk_project failopen)
state "$p" "$READY"
for bad in '' 'not json' '{' '[]' 'null' '{"stop_hook_active":' '"x"'; do
    run_stop "$p" "$bad" "$STUB"
    assert_eq "input '$bad' fails open" 0 "$CODE"
    assert_eq "input '$bad' is silent" "" "$ERR"
done

p=$(new_dir nostate)
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "no sarah/state.md allows" 0 "$CODE"
assert_eq "no sarah/state.md is silent" "" "$ERR"

p=$(mk_project emptystate)
: >"$p/sarah/state.md"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "an empty state.md allows" 0 "$CODE"

p=$(mk_project nosection)
printf '# S.A.R.A.H. state\n\nnothing here\n' >"$p/sarah/state.md"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "a state.md with no In flight section allows" 0 "$CODE"

p=$(mk_project dirstate)
rm "$p/sarah/state.md"
mkdir "$p/sarah/state.md"
run_stop "$p" "{$ACTIVE}" "$STUB"
assert_eq "an unreadable state.md allows" 0 "$CODE"

p=$(mk_project nojq)
state "$p" "$READY"
NOJQ=$(no_jq_path)
SHBIN=$(command -v sh)
(
    cd "$p" || exit 99
    PATH="$NOJQ"
    export PATH
    printf '{%s}' "$ACTIVE" | "$SHBIN" "$SCRIPT"
) >/dev/null 2>"$T_TMP/nojq.err"
assert_eq "no jq allows" 0 "$?"
assert_eq "no jq is silent" "" "$(cat "$T_TMP/nojq.err")"

# CLAUDE_PROJECT_DIR is honoured when the hook runs from elsewhere.
p=$(mk_project projdir)
state "$p" "$READY"
other=$(new_dir elsewhere)
(
    cd "$other" || exit 99
    PATH="$STUB:$PATH"
    CLAUDE_PROJECT_DIR=$p
    export PATH CLAUDE_PROJECT_DIR
    printf '{%s}' "$ACTIVE" | sh "$SCRIPT"
) >/dev/null 2>&1
assert_eq "CLAUDE_PROJECT_DIR locates the project" 2 "$?"

# Local state only: the hook never reaches for the network or the tracker.
if [ -f "$SCRIPT" ]; then ok "the payload script exists"; else fail "the payload script exists" "$SCRIPT"; fi
net=$(grep -v '^[[:space:]]*#' "$SCRIPT" 2>/dev/null | grep -wE 'curl|wget|gh|nc|ssh|trello|tracker\.py' || true)
assert_eq "the script never calls the network or the tracker" "" "$net"

# Exit codes: only 0 or 2.
codes=$(grep -nE '^[[:space:]]*exit[[:space:]]+' "$SCRIPT" 2>/dev/null | grep -vE 'exit[[:space:]]+[02]([[:space:]]|$)' || true)
assert_eq "the script only ever exits 0 or 2" "" "$codes"

t_end
