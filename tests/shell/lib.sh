# Assert helper for tests/shell/test_*.sh. Source it; do not execute it.
#
# Each test file calls `t_begin`, makes assertions, then ends with `t_end`,
# which exits non-zero if any assertion failed. Temp directories live under one
# root that is removed on exit.

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
T_PASS=0
T_FAIL=0
T_TMP=$(mktemp -d 2>/dev/null || mktemp -d -t sarah-shell)
trap 'rm -rf "$T_TMP"' EXIT

ok() {
    T_PASS=$((T_PASS + 1))
    echo "ok   - $1"
}

fail() {
    T_FAIL=$((T_FAIL + 1))
    echo "FAIL - $1"
    [ -z "${2:-}" ] || printf '%s\n' "$2" | sed 's/^/       /'
}

# assert_eq NAME EXPECTED ACTUAL
assert_eq() {
    if [ "$2" = "$3" ]; then ok "$1"; else fail "$1" "expected: $2
actual:   $3"; fi
}

# assert_contains NAME HAYSTACK NEEDLE (fixed string)
assert_contains() {
    case $2 in
        *"$3"*) ok "$1" ;;
        *) fail "$1" "missing: $3
in:
$2" ;;
    esac
}

# assert_not_contains NAME HAYSTACK NEEDLE (fixed string)
assert_not_contains() {
    case $2 in
        *"$3"*) fail "$1" "unexpected: $3" ;;
        *) ok "$1" ;;
    esac
}

# assert_le NAME ACTUAL LIMIT
assert_le() {
    if [ "$2" -le "$3" ]; then ok "$1 ($2 <= $3)"; else fail "$1" "$2 is over $3"; fi
}

# tokens TEXT : the chars/4 estimate the CI budgets use, rounded up.
tokens() {
    n=$(printf '%s' "$1" | wc -c | tr -d ' ')
    echo $(((n + 3) / 4))
}

# new_dir NAME : a fresh empty directory under the temp root.
new_dir() {
    d="$T_TMP/$1"
    rm -rf "$d"
    mkdir -p "$d"
    echo "$d"
}

# stub_dir : a PATH-shadow directory whose `date` prints $1 for any argument.
stub_date() {
    d=$(new_dir "stub-$1")
    printf '#!/bin/sh\necho %s\n' "$1" >"$d/date"
    chmod +x "$d/date"
    echo "$d"
}

# no_jq_path : a PATH holding the tools the hooks use, but no jq.
no_jq_path() {
    d=$(new_dir nojq)
    for tool in sh cat grep awk sed head tail wc tr date dirname basename ls mkdir printf cut sort; do
        p=$(command -v "$tool" 2>/dev/null) || continue
        case $p in /*) ln -s "$p" "$d/$tool" ;; esac
    done
    echo "$d"
}

t_end() {
    echo "$T_PASS passed, $T_FAIL failed"
    [ "$T_FAIL" -eq 0 ]
}

# mk_project NAME : a minimal S.A.R.A.H. project with one task in flight.
mk_project() {
    p=$(new_dir "proj-$1")
    mkdir -p "$p/sarah/state"
    cat >"$p/sarah/state.md" <<'STATE'
# S.A.R.A.H. state

| | |
| --- | --- |
| **Default level** | 2 |

## In flight

| Task | File | Phase | Level | Waiting on | Since |
| --- | --- | --- | --- | --- | --- |
| Example | `sarah/state/example.md` | implement | 2 | nothing | 2026-01-01 |
STATE
    echo "$p"
}

# pad FILE BYTES : append filler until FILE is exactly BYTES long.
pad() {
    have=$(wc -c <"$1" | tr -d ' ')
    need=$(($2 - have))
    [ "$need" -gt 0 ] || return 0
    dd if=/dev/zero bs=1 count="$need" 2>/dev/null | tr '\0' 'x' >>"$1"
}

# run_hook PROJECT [PATH_PREFIX] : the session-start hook as Claude Code runs it.
run_hook() {
    (
        cd "$1" || exit 0
        [ -z "${2:-}" ] || PATH="$2:$PATH"
        export PATH
        unset CLAUDE_PROJECT_DIR
        printf '{"cwd":"%s","hook_event_name":"SessionStart","source":"%s"}' "$1" "${HOOK_SOURCE:-startup}" |
            sh "$ROOT/hooks/scripts/session-start.sh"
    )
}
