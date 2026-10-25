# IH1, IH2, IH4, IH11, IH12, IH13 (R13): the gitflow guard and its CI check.
# Each case runs the installed, stamped script as Claude Code would: absolute
# path through CLAUDE_PROJECT_DIR, JSON on stdin, a stub gh on PATH.
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/habits_lib.sh"

P=$(mk_repo gf)
install_habits "$P" _lib gitflow
GH=$(stub_gh gf)
TODAY=2026-10-24
STUB=$(stub_date "$TODAY")
SUB="$P/sub/dir"
mkdir -p "$SUB"

on() { (cd "$P" && { git checkout -q "$1" 2>/dev/null || git checkout -q -b "$1"; }); }
guard() { run_hook_script "$P" gitflow guard.sh "$1" "$2" "$GH" "$STUB"; }

# --- the command string the engine registers works from a subdirectory (IH1)
cmd=$(jq -r '.hooks.PreToolUse[].hooks[].command' "$P/.claude/settings.json" 2>/dev/null | grep gitflow)
assert_contains "settings registers the guard by absolute path" "$cmd" 'sh "$CLAUDE_PROJECT_DIR/sarah/hooks/gitflow/guard.sh"'
on develop
G_OUT=$(cd "$SUB" && hook_json "$SUB" "git commit -m x" | CLAUDE_PROJECT_DIR=$P PATH="$GH:$STUB:$PATH" sh -c "$cmd" 2>&1; echo "rc=$?")
G_RC=${G_OUT##*rc=}
assert_rc "commit on develop is refused from a subdirectory, through the registered command" 2

# --- commits (IH2)
on develop
guard "$P" "git commit -m x";                      assert_rc "commit on develop" 2
assert_contains "block names the rule" "$G_OUT" "gitflow"
assert_contains "block names the exception path" "$G_OUT" "named exception"
assert_contains "block states the 14-day cap" "$G_OUT" "14 days"
assert_contains "block leads with Blocked" "$G_OUT" "Blocked:"
guard "$P" "git -C $P commit -m x";                assert_rc "commit with -C" 2
guard "$P" "git commit -am wip";                   assert_rc "commit -am" 2
guard "$P" "git add . && git commit -m x";         assert_rc "commit after &&" 2
guard "$P" "cd sub; git commit -m x";              assert_rc "commit after ;" 2
guard "$P" "GIT_AUTHOR_NAME=a git commit -m x";    assert_rc "commit with an env prefix" 2
guard "$P" 'echo "git commit"';                    assert_rc "echo of a commit is allowed" 0
guard "$P" "git status";                           assert_rc "git status" 0
guard "$P" "git log --oneline";                    assert_rc "git log" 0
on main
guard "$P" "git commit -m x";                      assert_rc "commit on main" 2
on feature/x
guard "$P" "git commit -m x";                      assert_rc "commit on feature/x" 0
guard "$P" "git commit -m 'note: git push origin main'"; assert_rc "a push named inside a quoted message is not a push" 0
guard "$SUB" "git commit -m x";                    assert_rc "commit on feature/x from a subdirectory" 0
on develop
guard "$SUB" "git commit -m x";                    assert_rc "commit on develop from a subdirectory" 2

# --- pushes (IH2)
on feature/x
guard "$P" "git push origin main";                 assert_rc "push main" 2
guard "$P" "git push origin develop";              assert_rc "push develop" 2
guard "$P" "git push origin HEAD:main";            assert_rc "push HEAD:main" 2
guard "$P" "git push origin feature/x:refs/heads/develop"; assert_rc "push to refs/heads/develop" 2
guard "$P" "git push --force origin main";         assert_rc "force push main" 2
guard "$P" "git push -f origin +main";             assert_rc "push +main" 2
guard "$P" "git push --all origin";                assert_rc "push --all reaches main" 2
guard "$P" "git push origin feature/x";            assert_rc "push feature/x" 0
guard "$P" "git push -u origin feature/x";         assert_rc "push -u feature/x" 0
guard "$P" "git push origin HEAD";                 assert_rc "push HEAD from a feature branch" 0
guard "$P" "git push";                             assert_rc "bare push from a feature branch" 0
guard "$P" "git push origin v0.2.0";               assert_rc "push a tag name" 0
on develop
guard "$P" "git push";                             assert_rc "bare push from develop" 2
guard "$P" "git push origin HEAD";                 assert_rc "push HEAD from develop" 2
guard "$P" "git push origin feature/x";            assert_rc "push feature/x while on develop" 0

# --- attribution: a separate choice, default off
on feature/x
msg='git commit -m "$(cat <<'"'"'EOF'"'"'
feat: x

Co-Authored-By: Someone <someone@example.invalid>
EOF
)"'
guard "$P" "$msg";                                 assert_rc "attribution line, default" 2
assert_contains "attribution block names the rule" "$G_OUT" "gitflow"
guard "$P" "git commit -m 'co-authored-by: A <a@example.invalid>'"; assert_rc "attribution line, any case" 2
guard "$P" "echo Co-Authored-By: x";               assert_rc "text outside a commit is not a commit" 0
# the engine owns Chosen and Manifest; Settings is the user's, so write it there
awk '/^## Settings/ && !d {print; print ""; print "- attribution: on"; d=1; next} {print}' "$P/sarah/habits.md" >"$P/h.new" && mv "$P/h.new" "$P/sarah/habits.md"
guard "$P" "$msg";                                 assert_rc "attribution chosen: allowed" 0
awk '!/^- attribution: on$/' "$P/sarah/habits.md" >"$P/h.new" && mv "$P/h.new" "$P/sarah/habits.md"
guard "$P" "$msg";                                 assert_rc "attribution choice removed: back to off" 2

# --- pull request base (IH13)
on feature/x
guard "$P" "gh pr create --base develop --title x";          assert_rc "feature into develop" 0
guard "$P" "gh pr create --base main --title x";             assert_rc "feature into main" 2
guard "$P" "gh pr create -B main --title x";                 assert_rc "feature into main, short flag" 2
guard "$P" "gh pr create --base feature/y --title x";        assert_rc "feature into another feature" 2
guard "$P" "gh pr create --title x";                         assert_rc "no base: cannot evaluate, allowed" 0
assert_contains "no base says it was not checked" "$G_OUT" "Rule not checked: gitflow"
on release/0.2.0
guard "$P" "gh pr create --base main --title x";             assert_rc "release into main" 0
guard "$P" "gh pr create --base develop --title x";          assert_rc "release back into develop" 0
guard "$P" "gh pr create --base feature/y --title x";        assert_rc "release into a feature" 2
on hotfix/a
guard "$P" "gh pr create --base main --title x";             assert_rc "hotfix into main" 0
on develop
guard "$P" "gh pr create --base main --title x";             assert_rc "develop into main directly" 2
on feature/x
guard "$P" "gh pr create --base main --head release/0.2.0 --title x"; assert_rc "--head overrides the current branch" 0
guard "$P" "gh pr view --web";                               assert_rc "other gh pr verbs" 0

# --- merge on green CI only (IH4)
on feature/x
rm -f "$GH/checks.err" "$GH/hang"
printf '[{"name":"lint","bucket":"pass"},{"name":"tests","bucket":"pass"}]\n' >"$GH/checks.out"; echo 0 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --merge";               assert_rc "green" 0
printf '[{"name":"lint","bucket":"pass"},{"name":"tests","bucket":"skipping"}]\n' >"$GH/checks.out"
guard "$P" "gh pr merge 12 --merge";               assert_rc "pass and skipping" 0
printf '[{"name":"lint","bucket":"pass"},{"name":"tests","bucket":"fail"}]\n' >"$GH/checks.out"; echo 1 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --merge";               assert_rc "red" 2
assert_contains "red names the failing check" "$G_OUT" "tests"
assert_contains "red names the exception path" "$G_OUT" "named exception"
printf '[{"name":"lint","bucket":"pass"},{"name":"tests","bucket":"pending"}]\n' >"$GH/checks.out"; echo 8 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --merge";               assert_rc "pending" 2
printf '[{"name":"x","bucket":"cancel"}]\n' >"$GH/checks.out"; echo 1 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --merge";               assert_rc "cancelled" 2
printf '[]\n' >"$GH/checks.out"; echo 0 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --merge";               assert_rc "no checks at all" 2
: >"$GH/checks.out"; echo "no checks reported on the 'feature/x' branch" >"$GH/checks.err"; echo 1 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --merge";               assert_rc "gh reports no checks" 2
rm -f "$GH/checks.err"
printf 'this is not json\n' >"$GH/checks.out"; echo 0 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --merge";               assert_rc "gh answers garbage: allowed" 0
assert_contains "garbage says it was not checked" "$G_OUT" "Rule not checked: gitflow"
assert_contains "not-checked line has the UX shape" "$G_OUT" "I let it through."
: >"$GH/checks.out"; echo 4 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --merge";               assert_rc "gh fails: allowed" 0
assert_contains "gh failing says it was not checked" "$G_OUT" "Rule not checked: gitflow"
touch "$GH/hang"
start=$(date +%s)
guard "$P" "gh pr merge 12 --merge";               assert_rc "gh hangs: allowed" 0
elapsed=$(($(date +%s) - start))
assert_le "a hanging gh returns within the hook's wait" "$elapsed" 20
rm -f "$GH/hang"
# gh missing: PATH without it, jq and git kept.
NOGH=$(new_dir nogh)
for t in sh cat grep awk sed head tail wc tr date dirname basename ls mkdir printf cut sort jq git sleep kill rm mktemp tee; do
    pth=$(command -v "$t" 2>/dev/null) && case $pth in /*) ln -s "$pth" "$NOGH/$t" ;; esac
done
G_OUT=$(cd "$P" && hook_json "$P" "gh pr merge 12 --merge" | PATH="$NOGH" CLAUDE_PROJECT_DIR=$P "$(command -v sh)" "$P/sarah/hooks/gitflow/guard.sh" 2>&1; echo "rc=$?")
G_RC=${G_OUT##*rc=}
assert_rc "gh missing: allowed" 0
assert_contains "gh missing says so" "$G_OUT" "Rule not checked: gitflow (gh is not installed)"
printf '[{"name":"tests","bucket":"pass"}]\n' >"$GH/checks.out"; echo 0 >"$GH/checks.rc"
guard "$P" "gh pr merge --auto 12";                assert_rc "merge with options" 0

# --- jq missing: allow and say so
on develop
G_OUT=$(cd "$P" && printf '{"tool_input":{"command":"git commit -m x"}}' | PATH="$(no_jq_path)" CLAUDE_PROJECT_DIR=$P "$(command -v sh)" "$P/sarah/hooks/gitflow/guard.sh" 2>&1; echo "rc=$?")
G_RC=${G_OUT##*rc=}
assert_rc "jq missing: allowed" 0
assert_contains "jq missing says so" "$G_OUT" "Rule not checked: gitflow (jq is not installed)"

# --- fuzz (IH11): only ever 0 or 2, never 1
fuzz() { # NAME STDIN-FILE
    G_OUT=$(cd "$P" && PATH="$GH:$STUB:$PATH" CLAUDE_PROJECT_DIR=$P sh "$P/sarah/hooks/gitflow/guard.sh" <"$2" 2>&1; echo "rc=$?")
    G_RC=${G_OUT##*rc=}
    case $G_RC in 0 | 2) ok "fuzz: $1 exits $G_RC" ;; *) fail "fuzz: $1 exited $G_RC" ;; esac
}
: >"$T_TMP/f1"; fuzz "empty input" "$T_TMP/f1"
printf '{not json' >"$T_TMP/f2"; fuzz "invalid JSON" "$T_TMP/f2"
printf '[]' >"$T_TMP/f3"; fuzz "JSON array" "$T_TMP/f3"
printf '{"tool_input":{"command":42}}' >"$T_TMP/f4"; fuzz "command is a number" "$T_TMP/f4"
printf '{"tool_input":null}' >"$T_TMP/f5"; fuzz "tool_input null" "$T_TMP/f5"
awk 'BEGIN{for(i=0;i<20000;i++) printf "echo aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa; "; print "git status"}' >"$T_TMP/big.txt"
jq -nc --rawfile c "$T_TMP/big.txt" '{tool_input:{command:$c}}' >"$T_TMP/f6"
assert_le "the 1 MB fixture is really that large" 1000000 "$(wc -c <"$T_TMP/f6" | tr -d ' ')"
start=$(date +%s)
fuzz "1 MB command" "$T_TMP/f6"
assert_le "a 1 MB command is split in time" "$(($(date +%s) - start))" 10
jq -nc --arg c "git commit -m aaa 'unterminated" '{tool_input:{command:$c}}' >"$T_TMP/f7"; fuzz "unterminated quote" "$T_TMP/f7"

# --- the exception path (IH10, R16) through the guard
on develop
guard "$P" "git commit -m x";                      assert_rc "before any exception" 2
add_exception "$P" gitflow "release hotfix" 2026-11-03 2026-10-24
guard "$P" "git commit -m x";                      assert_rc "an exception lets the call through" 0
assert_contains "the use is announced" "$G_OUT" "Exception in use: gitflow, until 2026-11-03"
assert_contains "the use is logged" "$(cat "$P/sarah/exceptions.log")" "2026-10-24 gitflow until 2026-11-03 reason: release hotfix"
run_hook_script "$P" gitflow guard.sh "$P" "git commit -m x" "$GH" "$(stub_date 2026-11-04)"
assert_rc "the day after expiry the rule blocks again" 2

# --- the CI check (IH13)
CHECK="$P/sarah/hooks/gitflow/check-branch-model.sh"
ci() { G_OUT=$(sh "$CHECK" "$1" "$2" 2>&1; echo "rc=$?"); G_RC=${G_OUT##*rc=}; }
ci develop feature/x;   assert_rc "CI: feature into develop" 0
ci main feature/x;      assert_rc "CI: feature into main" 2
assert_contains "CI names the rule" "$G_OUT" "gitflow"
ci main release/0.2.0;  assert_rc "CI: release into main" 0
ci develop release/0.2.0; assert_rc "CI: release into develop" 0
ci main hotfix/a;       assert_rc "CI: hotfix into main" 0
ci main develop;        assert_rc "CI: develop into main" 2
ci main fix/typo;       assert_rc "CI: unprefixed branch into main" 2
ci develop fix/typo;    assert_rc "CI: unprefixed branch into develop" 0
ci feature/y feature/x; assert_rc "CI: feature into a feature" 2
ci "" "";               assert_rc "CI: no refs, cannot evaluate" 0
assert_contains "CI says when it could not check" "$G_OUT" "Rule not checked: gitflow"
ci 'main; echo pwned' 'feature/x'; assert_rc "CI: refs are data, never code" 2

t_end
