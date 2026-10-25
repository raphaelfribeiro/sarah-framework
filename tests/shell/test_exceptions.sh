# US10, IH10 (R16): the exceptions library. A row is honored only when its
# reason is non-empty, today is inside the window, and the expiry is at most 14
# days after the grant. Everything else fails closed. Dates come from a `date`
# shadowed on PATH; the library may call `date +%Y-%m-%d` and nothing else.
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/habits_lib.sh"

LIB="$ROOT/skills/sarah-init/habits/_lib/files/sarah/hooks/_lib/exceptions.sh"

# The lib as installed: stamped copy in a project.
P=$(mk_repo exc)
install_habits "$P" _lib
INSTALLED="$P/sarah/hooks/_lib/exceptions.sh"
[ -f "$INSTALLED" ] && ok "the lib installs at sarah/hooks/_lib/exceptions.sh" || fail "the lib installs at sarah/hooks/_lib/exceptions.sh"
head -1 "$INSTALLED" | grep -q '^# sarah-habit: _lib ' && ok "the lib carries the installer stamp" || fail "the lib carries the installer stamp"

# reset: a clean Exceptions table, no log.
reset() {
    rm -rf "$P/sarah/exceptions.log"
    printf '# Habits\n\n## Exceptions\n\n| rule | reason | expires | granted by | date |\n| --- | --- | --- | --- | --- |\n' >"$P/sarah/habits.md"
}

# honored TODAY RULE : exit status of sarah_exception_honored under a fixed today.
honored() {
    stub=$(stub_date "$1")
    (cd "$P" && PATH="$stub:$PATH" sh -c '. "$1"; sarah_exception_honored "$2" "$3"' sh "$INSTALLED" "$P" "$2") >/dev/null 2>&1
}

expect_honored() { # NAME TODAY RULE
    if honored "$2" "$3"; then ok "$1"; else fail "$1" "row was not honored on $2"; fi
}
expect_refused() {
    if honored "$2" "$3"; then fail "$1" "row was honored on $2"; else ok "$1"; fi
}

# Window, inclusive on both ends.
reset; add_exception "$P" gitflow "release hotfix" 2026-11-03 2026-10-24
expect_honored "grant day" 2026-10-24 gitflow
expect_honored "inside the window" 2026-10-30 gitflow
expect_honored "expiry day is inclusive" 2026-11-03 gitflow
expect_refused "the day after expiry blocks again, with no action" 2026-11-04 gitflow
expect_refused "the day before the grant" 2026-10-23 gitflow
expect_refused "another rule is not covered" 2026-10-30 changelog-fragment

# The 14-day cap, measured from the grant.
reset; add_exception "$P" gitflow "r" 2026-11-07 2026-10-24
expect_honored "exactly 14 days after the grant" 2026-10-25 gitflow
reset; add_exception "$P" gitflow "r" 2026-11-08 2026-10-24
expect_refused "15 days after the grant" 2026-10-25 gitflow

# Across a month, a year end, and leap years.
reset; add_exception "$P" gitflow "r" 2027-01-08 2026-12-25
expect_honored "14 days across New Year" 2026-12-26 gitflow
reset; add_exception "$P" gitflow "r" 2027-01-09 2026-12-25
expect_refused "15 days across New Year" 2026-12-26 gitflow
reset; add_exception "$P" gitflow "r" 2028-03-05 2028-02-20
expect_honored "14 days across 29 February 2028" 2028-02-21 gitflow
reset; add_exception "$P" gitflow "r" 2028-03-06 2028-02-20
expect_refused "15 days across 29 February 2028" 2028-02-21 gitflow
reset; add_exception "$P" gitflow "r" 2027-03-06 2027-02-20
expect_honored "14 days across February 2027 (no leap day)" 2027-02-21 gitflow
reset; add_exception "$P" gitflow "r" 2027-03-07 2027-02-20
expect_refused "15 days across February 2027" 2027-02-21 gitflow
reset; add_exception "$P" gitflow "r" 2028-02-29 2028-02-26
expect_honored "29 February 2028 is a real date" 2028-02-27 gitflow
reset; add_exception "$P" gitflow "r" 2000-02-29 2000-02-26
expect_honored "29 February 2000 is a real date (divisible by 400)" 2000-02-27 gitflow
reset; add_exception "$P" gitflow "r" 2100-02-29 2100-02-26
expect_refused "29 February 2100 is not a date (divisible by 100)" 2100-02-27 gitflow
reset; add_exception "$P" gitflow "r" 2027-02-29 2027-02-26
expect_refused "29 February 2027 is not a date" 2027-02-27 gitflow

# Malformed dates fail closed for the exception, in either column.
for bad in 2026-02-30 2026-13-01 2026-00-10 2026-11-00 tomorrow 2026-1-3 26-11-03 "" 2026-11-03x "2026-11-03 2026-11-04"; do
    reset; add_exception "$P" gitflow "r" "$bad" 2026-10-24
    expect_refused "malformed expiry '$bad'" 2026-10-30 gitflow
done
for bad in 2026-02-30 yesterday ""; do
    reset; add_exception "$P" gitflow "r" 2026-11-03 "$bad"
    expect_refused "malformed grant date '$bad'" 2026-10-30 gitflow
done
reset; add_exception "$P" gitflow "r" 2026-10-20 2026-10-24
expect_refused "expiry before the grant" 2026-10-24 gitflow

# A malformed `date` output is not a day.
reset; add_exception "$P" gitflow "r" 2026-11-03 2026-10-24
expect_refused "today is garbage" "not-a-date" gitflow

# The reason.
reset; add_exception "$P" gitflow "" 2026-11-03 2026-10-24
expect_refused "empty reason" 2026-10-30 gitflow
reset; add_exception "$P" gitflow "   " 2026-11-03 2026-10-24
expect_refused "blank reason" 2026-10-30 gitflow
reset; add_exception "$P" gitflow "use a | in it" 2026-11-03 2026-10-24
expect_refused "a pipe in the reason breaks the row, so it fails closed" 2026-10-30 gitflow

# CRLF file: the row is the user's, the line ending is the editor's.
reset; printf '| gitflow | crlf row | 2026-11-03 | the user | 2026-10-24 |\r\n' >>"$P/sarah/habits.md"
expect_honored "a CRLF row is honored" 2026-10-30 gitflow

# A later valid row is found after an invalid one.
reset; add_exception "$P" gitflow "" 2026-11-03 2026-10-24; add_exception "$P" gitflow "second" 2026-11-03 2026-10-24
expect_honored "an invalid row does not hide a valid one" 2026-10-30 gitflow

# Rows outside the Exceptions section are not exceptions.
reset; printf '\n## Notes\n\n| gitflow | elsewhere | 2026-11-03 | the user | 2026-10-24 |\n' >>"$P/sarah/habits.md"
expect_refused "a row in another section" 2026-10-30 gitflow

# No file, no section.
rm -f "$P/sarah/habits.md"
expect_refused "no habits.md" 2026-10-30 gitflow
printf '# Habits\n' >"$P/sarah/habits.md"
expect_refused "no Exceptions section" 2026-10-30 gitflow

# Logging: every use, one line, rule and window and reason.
reset; add_exception "$P" gitflow "release hotfix" 2026-11-03 2026-10-24
honored 2026-10-30 gitflow; honored 2026-10-31 gitflow
log=$(cat "$P/sarah/exceptions.log" 2>/dev/null)
assert_eq "two uses, two lines" 2 "$(printf '%s\n' "$log" | grep -c .)"
assert_contains "log line names day, rule, expiry and reason" "$log" "2026-10-30 gitflow until 2026-11-03 reason: release hotfix"
rm -f "$P/sarah/exceptions.log"
expect_refused "a refused row writes no log line" 2026-11-30 gitflow
[ ! -s "$P/sarah/exceptions.log" ] && ok "refusal logs nothing" || fail "refusal logs nothing"

# The log cannot be written: the use could not be recorded, so it is not honored.
rm -rf "$P/sarah/exceptions.log"; mkdir "$P/sarah/exceptions.log"
expect_refused "unwritable log fails closed" 2026-10-30 gitflow
rmdir "$P/sarah/exceptions.log"

# The message on stderr says which exception is in use.
stub=$(stub_date 2026-10-30)
msg=$(cd "$P" && PATH="$stub:$PATH" sh -c '. "$1"; sarah_exception_honored "$2" gitflow' sh "$INSTALLED" "$P" 2>&1 >/dev/null)
assert_contains "use is announced" "$msg" "Exception in use: gitflow, until 2026-11-03 (reason: release hotfix). Used 1 time"

# The list, for /sarah-status: active first, then expired within 14 days, uses counted.
reset
add_exception "$P" gitflow "active one" 2026-11-03 2026-10-24
add_exception "$P" changelog-fragment "lapsed" 2026-10-20 2026-10-10
add_exception "$P" gitflow "ancient" 2026-09-01 2026-08-25
add_exception "$P" gitflow "bad dates" 2026-02-30 2026-10-24
printf '2026-10-26 gitflow until 2026-11-03 reason: active one\n2026-10-27 gitflow until 2026-11-03 reason: active one\n' >"$P/sarah/exceptions.log"
list=$(cd "$P" && PATH="$(stub_date 2026-10-30):$PATH" sh -c '. "$1"; sarah_exceptions_list "$2"' sh "$INSTALLED" "$P" 2>&1)
assert_contains "list: header" "$list" "| Rule | Until | Reason | Uses |"
assert_contains "list: active row with its use count" "$list" "| gitflow | 2026-11-03 | active one | 2 |"
assert_contains "list: recently expired row is marked" "$list" "| changelog-fragment | 2026-10-20 expired | lapsed | 0 |"
assert_not_contains "list: rows expired over 14 days ago are left out" "$list" "ancient"
assert_contains "list: a row that would not be honored says so" "$list" "bad dates"
case $list in
    *active\ one*expired*) ok "list: active comes before expired" ;;
    *) fail "list: active comes before expired" "$list" ;;
esac
reset
none=$(cd "$P" && PATH="$(stub_date 2026-10-30):$PATH" sh -c '. "$1"; sarah_exceptions_list "$2"' sh "$INSTALLED" "$P" 2>&1)
assert_eq "list with no rows" "Exceptions: none active." "$none"

# The lib reads the date through `date +%Y-%m-%d` only.
if grep -nE 'date[[:space:]]+-' "$LIB" >/dev/null 2>&1; then
    fail "the lib never calls date -d"
else
    ok "the lib never calls date -d"
fi

t_end
