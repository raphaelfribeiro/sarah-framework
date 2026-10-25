# IH6 (R14): `gh pr create` is refused unless the branch adds a sarah/changelog/
# entry that carries a `User-facing:` line with a real sentence. The hook checks
# that the line exists and is not a placeholder, and nothing about its wording.
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/habits_lib.sh"

P=$(mk_repo cl)
install_habits "$P" _lib changelog-fragment
GH=$(stub_gh cl)
STUB=$(stub_date 2026-10-24)
guard() { run_hook_script "$P" changelog-fragment guard.sh "$1" "$2" "$GH" "$STUB"; }
g() { (cd "$P" && git "$@" >/dev/null 2>&1); }

# An old entry already on develop must not satisfy the rule for a new delivery.
mkdir -p "$P/sarah/changelog"
printf '# Old delivery\n\nUser-facing: Something shipped long ago.\n' >"$P/sarah/changelog/2026-01-01-old.md"
g add -A; g commit -q -m "old entry"
g checkout -q -b feature/x

guard "$P" "gh pr create --base develop --title x"
assert_eq "no fragment on the branch" 2 "$G_RC"
assert_contains "block names the rule" "$G_OUT" "changelog-fragment"
assert_contains "block shows the line to write" "$G_OUT" "User-facing:"
assert_contains "block names the exception path" "$G_OUT" "named exception"
assert_contains "block leads with Blocked" "$G_OUT" "Blocked:"

# An entry without the marked line.
printf '# New delivery\n\nChanged things.\n' >"$P/sarah/changelog/2026-10-24-new.md"
g add -A; g commit -q -m "entry without the line"
guard "$P" "gh pr create --base develop --title x"
assert_eq "entry without a User-facing line" 2 "$G_RC"

# Placeholders do not count.
for ph in "<one sentence for the release notes>" "TODO" "tbd" "" "   " "-" "..."; do
    printf '# New delivery\n\nUser-facing: %s\n' "$ph" >"$P/sarah/changelog/2026-10-24-new.md"
    g add -A; g commit -q -m "placeholder"
    guard "$P" "gh pr create --base develop --title x"
    assert_eq "placeholder '$ph'" 2 "$G_RC"
done

# The marker is exact and at the start of a line.
printf '# New\n\nuser-facing: Lower case does not count.\n' >"$P/sarah/changelog/2026-10-24-new.md"
g add -A; g commit -q -m "case"
guard "$P" "gh pr create --base develop --title x"
assert_eq "marker is case-sensitive" 2 "$G_RC"
printf '# New\n\nSee User-facing: Mid-line does not count.\n' >"$P/sarah/changelog/2026-10-24-new.md"
g add -A; g commit -q -m "midline"
guard "$P" "gh pr create --base develop --title x"
assert_eq "marker starts the line" 2 "$G_RC"

# Present.
printf '# New delivery\n\nUser-facing: Export now has a share button.\n\nMore detail follows.\n' >"$P/sarah/changelog/2026-10-24-new.md"
g add -A; g commit -q -m "real entry"
guard "$P" "gh pr create --base develop --title x"
assert_eq "entry with a real line" 0 "$G_RC"
guard "$P" "gh pr create --title x --fill"
assert_eq "no --base: develop is assumed" 0 "$G_RC"
guard "$P" "cd sub && gh pr create -B develop -t x"
assert_eq "short flag, chained" 0 "$G_RC"
guard "$P" 'echo "gh pr create"'
assert_eq "echo of gh pr create is allowed" 0 "$G_RC"
guard "$P" "gh pr view 3"
assert_eq "other gh verbs are not checked" 0 "$G_RC"
guard "$P" "gh pr merge 3"
assert_eq "merge is not this rule" 0 "$G_RC"

# CRLF line endings.
printf '# New delivery\r\n\r\nUser-facing: Windows editors work too.\r\n' >"$P/sarah/changelog/2026-10-24-new.md"
g add -A; g commit -q -m "crlf"
guard "$P" "gh pr create --base develop --title x"
assert_eq "CRLF entry" 0 "$G_RC"

# A second file may carry the line while the first does not.
printf '# Notes\n\nNo line here.\n' >"$P/sarah/changelog/2026-10-24-new.md"
printf '# Other\n\nUser-facing: Another entry has it.\n' >"$P/sarah/changelog/2026-10-25-other.md"
g add -A; g commit -q -m "two"
guard "$P" "gh pr create --base develop --title x"
assert_eq "any added entry may carry the line" 0 "$G_RC"

# Written but not committed: the pull request would not contain it.
g reset -q --hard
g checkout -q develop; g checkout -q -b feature/y
printf '# Fresh\n\nUser-facing: Not committed yet.\n' >"$P/sarah/changelog/2026-10-26-fresh.md"
guard "$P" "gh pr create --base develop --title x"
assert_eq "an uncommitted entry is not on the branch" 2 "$G_RC"
assert_contains "block says to commit it" "$G_OUT" "commit"
rm -f "$P/sarah/changelog/2026-10-26-fresh.md"

# Deleted: removing the old entry is not adding one.
g rm -q sarah/changelog/2026-01-01-old.md; g commit -q -m "delete the old entry"
guard "$P" "gh pr create --base develop --title x"
assert_eq "a deleted entry does not count" 2 "$G_RC"

# Base unknown: cannot evaluate, so allow and say so.
guard "$P" "gh pr create --base no-such-branch --title x"
assert_eq "unknown base: allowed" 0 "$G_RC"
assert_contains "unknown base says it was not checked" "$G_OUT" "Rule not checked: changelog-fragment"
assert_contains "not-checked line has the UX shape" "$G_OUT" "I let it through."

# Not a repository: nothing to compare.
NR=$(new_dir norepo)
G_OUT=$(cd "$NR" && hook_json "$NR" "gh pr create --base develop" | CLAUDE_PROJECT_DIR=$P PATH="$STUB:$PATH" sh "$P/sarah/hooks/changelog-fragment/guard.sh" 2>&1; echo "rc=$?")
G_RC=${G_OUT##*rc=}
assert_eq "outside a repository: allowed" 0 "$G_RC"

# jq missing.
G_OUT=$(cd "$P" && printf '{"tool_input":{"command":"gh pr create --base develop"}}' | PATH="$(no_jq_path)" CLAUDE_PROJECT_DIR=$P "$(command -v sh)" "$P/sarah/hooks/changelog-fragment/guard.sh" 2>&1; echo "rc=$?")
G_RC=${G_OUT##*rc=}
assert_eq "jq missing: allowed" 0 "$G_RC"
assert_contains "jq missing says so" "$G_OUT" "Rule not checked: changelog-fragment (jq is not installed)"

# Fuzz: 0 or 2, never 1.
for input in '' '{not json' '[]' '{"tool_input":null}' '{"tool_input":{"command":false}}'; do
    G_OUT=$(cd "$P" && printf '%s' "$input" | PATH="$GH:$STUB:$PATH" CLAUDE_PROJECT_DIR=$P sh "$P/sarah/hooks/changelog-fragment/guard.sh" 2>&1; echo "rc=$?")
    G_RC=${G_OUT##*rc=}
    case $G_RC in 0 | 2) ok "fuzz '$input' exits $G_RC" ;; *) fail "fuzz '$input' exited $G_RC" ;; esac
done

# The exception path.
add_exception "$P" changelog-fragment "docs-only hotfix" 2026-11-03 2026-10-24
guard "$P" "gh pr create --base develop --title x"
assert_eq "an exception lets the call through" 0 "$G_RC"
assert_contains "the use is announced" "$G_OUT" "Exception in use: changelog-fragment, until 2026-11-03"
assert_contains "the use is logged" "$(cat "$P/sarah/exceptions.log")" "2026-10-24 changelog-fragment until 2026-11-03 reason: docs-only hotfix"
run_hook_script "$P" changelog-fragment guard.sh "$P" "gh pr create --base develop --title x" "$GH" "$(stub_date 2026-11-04)"
assert_eq "after expiry the rule blocks again" 2 "$G_RC"
rm -f "$P/sarah/exceptions.log"
add_exception "$P" gitflow "wrong rule" 2026-12-01 2026-10-24
run_hook_script "$P" changelog-fragment guard.sh "$P" "gh pr create --base develop --title x" "$GH" "$(stub_date 2026-11-30)"
assert_eq "an exception for another rule does not apply" 2 "$G_RC"

t_end
