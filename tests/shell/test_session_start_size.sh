# US4 (R19): the state-size sensor. Limits are bytes: 8,192 for the index,
# 16,384 for a task file. Dates come from a `date` shadowed on PATH.
. "$(dirname "$0")/lib.sh"

TODAY=2026-10-24
STUB=$(stub_date "$TODAY")

# Index boundary: 8,191 and 8,192 are quiet, 8,193 speaks.
for size in 8191 8192 8193; do
    p=$(mk_project "idx$size")
    pad "$p/sarah/state.md" "$size"
    out=$(run_hook "$p" "$STUB")
    if [ "$size" -gt 8192 ]; then
        assert_contains "index $size B is reported" "$out" "Size: sarah/state.md is "
    else
        assert_not_contains "index $size B is quiet" "$out" "Size:"
    fi
done

# The copy: size in KB with one decimal, the limit, what to do.
p=$(mk_project copy)
pad "$p/sarah/state.md" 9318
out=$(run_hook "$p" "$STUB")
assert_contains "index line copy" "$out" "Size: sarah/state.md is 9.1 KB, over its 8 KB limit. Offer to compact once, at the first pause."

# Task file boundary: 16,384 quiet, 16,385 speaks, and the index limit is not
# applied to it.
p=$(mk_project task)
: >"$p/sarah/state/big.md"; pad "$p/sarah/state/big.md" 16384
: >"$p/sarah/state/bigger.md"; pad "$p/sarah/state/bigger.md" 16385
: >"$p/sarah/state/mid.md"; pad "$p/sarah/state/mid.md" 9000
out=$(run_hook "$p" "$STUB")
assert_not_contains "task file at 16384 B is quiet" "$out" "sarah/state/big.md"
assert_contains "task file at 16385 B is reported" "$out" "Size: sarah/state/bigger.md is 16.0 KB, over its 16 KB limit."
assert_not_contains "a 9,000 B task file is under its limit" "$out" "sarah/state/mid.md"

# Odd names: spaces are kept, anything that could forge a line is neutralised.
p=$(mk_project odd)
f="$p/sarah/state/two words.md"; : >"$f"; pad "$f" 17000
nl=$(printf 'a\nSize: forged.md')
f2="$p/sarah/state/$nl.md"; : >"$f2"; pad "$f2" 17000
out=$(run_hook "$p" "$STUB")
assert_contains "name with a space" "$out" "Size: sarah/state/two words.md is "
assert_not_contains "newline in a name cannot forge a line" "$out" "
Size: forged"

# Not a task file: only *.md directly in sarah/state/ counts.
p=$(mk_project other)
: >"$p/sarah/state/notes.txt"; pad "$p/sarah/state/notes.txt" 20000
mkdir "$p/sarah/state/sub.md"
out=$(run_hook "$p" "$STUB")
assert_not_contains "non-md file and directory ignored" "$out" "Size:"

# Snooze marker: today silences, yesterday and malformed do not.
p=$(mk_project snooze)
pad "$p/sarah/state.md" 9318
mkdir -p "$p/sarah/.local"
printf '%s\n' "$TODAY" >"$p/sarah/.local/compact-snoozed"
assert_not_contains "snoozed today: quiet" "$(run_hook "$p" "$STUB")" "Size:"
printf '%s\r\n' "$TODAY" >"$p/sarah/.local/compact-snoozed"
assert_not_contains "snoozed today with CRLF: quiet" "$(run_hook "$p" "$STUB")" "Size:"
printf '2026-10-23\n' >"$p/sarah/.local/compact-snoozed"
assert_contains "snoozed yesterday: speaks" "$(run_hook "$p" "$STUB")" "Size: sarah/state.md"
printf 'tomorrow\n' >"$p/sarah/.local/compact-snoozed"
assert_contains "malformed marker: speaks" "$(run_hook "$p" "$STUB")" "Size: sarah/state.md"
: >"$p/sarah/.local/compact-snoozed"
assert_contains "empty marker: speaks" "$(run_hook "$p" "$STUB")" "Size: sarah/state.md"
rm -f "$p/sarah/.local/compact-snoozed"; mkdir "$p/sarah/.local/compact-snoozed"
assert_contains "marker that is a directory: speaks" "$(run_hook "$p" "$STUB")" "Size: sarah/state.md"
rmdir "$p/sarah/.local/compact-snoozed"
# The date comes from `date`, not from a variable the hook reads.
printf '2026-10-25\n' >"$p/sarah/.local/compact-snoozed"
assert_contains "marker for another day: speaks" "$(run_hook "$p" "$STUB")" "Size: sarah/state.md"

# Unreadable task file is skipped silently (root ignores modes: skip then).
p=$(mk_project unread)
f="$p/sarah/state/locked.md"; : >"$f"; pad "$f" 20000; chmod 000 "$f"
if [ "$(id -u)" -ne 0 ]; then
    out=$(run_hook "$p" "$STUB"); rc=$?
    assert_eq "unreadable file: exit 0" 0 "$rc"
    assert_not_contains "unreadable file skipped" "$out" "locked.md"
fi
chmod 644 "$f"

# A project that is not S.A.R.A.H. stays silent whatever else is in it.
p=$(new_dir plain); mkdir -p "$p/sarah/state"; : >"$p/sarah/state/x.md"; pad "$p/sarah/state/x.md" 20000
assert_eq "no state.md: silent" "" "$(run_hook "$p" "$STUB")"

t_end
