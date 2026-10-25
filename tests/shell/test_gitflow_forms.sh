# The invocation forms the gitflow guard must judge like the plain one-line
# command: backslash continuations, env and path wrappers, tag pushes, the
# auto-merge wait, and a merge aimed at another repository.
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/habits_lib.sh"

P=$(mk_repo gff)
install_habits "$P" _lib gitflow
GH=$(stub_gh gff)
STUB=$(stub_date 2026-10-24)

on() { (cd "$P" && { git checkout -q "$1" 2>/dev/null || git checkout -q -b "$1"; }); }
guard() { run_hook_script "$P" gitflow guard.sh "$1" "$2" "$GH" "$STUB"; }
NL='
'

# --- a backslash-newline continues the command
on feature/x
guard "$P" "git push \\${NL}  origin main";                    assert_rc "continued push to main" 2
guard "$P" "gh pr create --title t \\${NL} --base main";       assert_rc "continued pr create into main" 2
guard "$P" "git push \\${NL}  origin feature/x";               assert_rc "continued push of a feature branch" 0
guard "$P" "gi\\${NL}t push origin main";                      assert_rc "a word split by a continuation" 2
guard "$P" "git push \\${NL}  origin \\${NL}  main";           assert_rc "two continuations" 2
guard "$P" "echo a \\${NL}; git push origin main";             assert_rc "continuation before a separator" 2
guard "$P" "echo 'a \\${NL}b'; git status";                    assert_rc "a backslash inside single quotes stays" 0
guard "$P" "git commit -m \"a \\${NL}b\"";                     assert_rc "continuation inside double quotes" 0
guard "$P" "git status${NL}git push origin main";              assert_rc "a plain newline still separates" 2
guard "$P" "git status \\";                                    assert_rc "trailing backslash at the very end" 0

# --- wrappers and paths
guard "$P" "env -i git push origin main";                      assert_rc "env -i" 2
guard "$P" "env -u FOO git push origin main";                  assert_rc "env -u VAR" 2
guard "$P" "env --unset FOO git push origin main";             assert_rc "env --unset VAR" 2
guard "$P" "env --unset=FOO git push origin main";             assert_rc "env --unset=VAR" 2
guard "$P" "/usr/bin/env git push origin main";                assert_rc "absolute env" 2
guard "$P" "env -i A=1 git push origin main";                  assert_rc "env -i with an assignment" 2
guard "$P" "env A=1 git push origin main";                     assert_rc "env VAR=1" 2
guard "$P" "/usr/bin/git push origin main";                    assert_rc "absolute path to git" 2
guard "$P" "./git push origin main";                           assert_rc "relative path to git" 2
guard "$P" "env -i /usr/bin/git push origin main";             assert_rc "env and a path" 2
guard "$P" "env -i /usr/bin/gh pr create --base main --title t"; assert_rc "env and a path to gh" 2
guard "$P" "env -i git push origin feature/x";                 assert_rc "env -i, a feature push" 0
guard "$P" "env -i echo git push origin main";                 assert_rc "env -i around echo" 0
guard "$P" "env -u";                                           assert_rc "env -u with nothing after" 0
on develop
guard "$P" "env -i git commit -m x";                           assert_rc "env -i commit on develop" 2

# --- pushing tags is not pushing a branch
on develop
guard "$P" "git push --tags";                                  assert_rc "push --tags from develop" 0
guard "$P" "git push origin --tags";                           assert_rc "push origin --tags from develop" 0
guard "$P" "git push --tags origin";                           assert_rc "push --tags origin from develop" 0
guard "$P" "git push origin v1.2.3";                           assert_rc "push a tag name from develop" 0
guard "$P" "git push origin refs/tags/v1.2.3";                 assert_rc "push a full tag ref from develop" 0
guard "$P" "git push origin --tags main";                      assert_rc "tags and main together" 2
guard "$P" "git push --tags origin develop";                   assert_rc "tags and develop together" 2
guard "$P" "git push --follow-tags";                           assert_rc "follow-tags pushes the branch too" 2
guard "$P" "git push --tags --all";                            assert_rc "tags and all" 2
guard "$P" "git push --tags --mirror";                         assert_rc "tags and mirror" 2
guard "$P" "git push";                                         assert_rc "bare push from develop still blocked" 2
on main
guard "$P" "git push --tags";                                  assert_rc "push --tags from main" 0
guard "$P" "git push origin --tags";                           assert_rc "push origin --tags from main" 0

# --- gh pr merge --auto waits for the checks; it is the safe way to wait
on feature/x
rm -f "$GH/checks.err" "$GH/hang"
printf '[{"name":"tests","bucket":"pending"}]\n' >"$GH/checks.out"; echo 8 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --merge";                           assert_rc "pending, no --auto" 2
guard "$P" "gh pr merge 12 --merge --auto";                    assert_rc "pending with --auto" 0
guard "$P" "gh pr merge --auto 12";                            assert_rc "--auto before the number" 0
printf '[{"name":"tests","bucket":"fail"}]\n' >"$GH/checks.out"; echo 1 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --auto";                            assert_rc "failing with --auto stays blocked" 2
printf '[]\n' >"$GH/checks.out"; echo 0 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 --auto";                            assert_rc "no checks with --auto stays blocked" 2

# --- the merge is checked in the repository it names
printf '[{"name":"tests","bucket":"pass"}]\n' >"$GH/checks.out"; echo 0 >"$GH/checks.rc"
rm -f "$GH/args"
guard "$P" "gh pr merge 12 -R acme/widgets --merge";           assert_rc "merge with -R" 0
assert_contains "-R reaches the checks query" "$(cat "$GH/args")" "-R acme/widgets"
assert_contains "the query is for the pull request" "$(cat "$GH/args")" "pr checks 12"
rm -f "$GH/args"
guard "$P" "gh pr merge 12 --repo acme/widgets";               assert_rc "merge with --repo" 0
assert_contains "--repo reaches the checks query" "$(cat "$GH/args")" "-R acme/widgets"
rm -f "$GH/args"
guard "$P" "gh pr merge 12 --repo=acme/widgets";               assert_rc "merge with --repo=" 0
assert_contains "--repo= reaches the checks query" "$(cat "$GH/args")" "-R acme/widgets"
rm -f "$GH/args"
guard "$P" "gh pr merge 12";                                   assert_rc "merge without a repo" 0
assert_not_contains "no -R when none was named" "$(cat "$GH/args")" "-R"
printf '[{"name":"tests","bucket":"fail"}]\n' >"$GH/checks.out"; echo 1 >"$GH/checks.rc"
guard "$P" "gh pr merge 12 -R acme/widgets";                   assert_rc "red in the named repository" 2

# --- a rule that could not be checked is said on stdout as hook JSON, because
# Claude Code never shows stderr of a hook that exits 0.
on feature/x
raw() { # COMMAND [PATH] : stdout alone, the way the harness reads it
    jq -nc --arg c "$1" --arg d "$P" '{tool_name:"Bash",cwd:$d,tool_input:{command:$c}}' >"$T_TMP/in.json"
    R_OUT=$(cd "$P" && PATH="${2:-$GH:$STUB:$PATH}" CLAUDE_PROJECT_DIR=$P "$(command -v sh)" "$P/sarah/hooks/gitflow/guard.sh" <"$T_TMP/in.json" 2>"$T_TMP/err"; echo "rc=$?")
    R_RC=${R_OUT##*rc=}
    R_OUT=${R_OUT%rc=*}
}
raw "gh pr create --title x"
assert_eq "not checked still allows" 0 "$R_RC"
assert_eq "stdout is valid JSON" "PreToolUse" "$(printf '%s' "$R_OUT" | jq -r '.hookSpecificOutput.hookEventName' 2>/dev/null)"
assert_contains "context carries the message" "$(printf '%s' "$R_OUT" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)" "Rule not checked: gitflow (the pull request names no --base)"
assert_eq "no permission decision is set" "null" "$(printf '%s' "$R_OUT" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)"
assert_contains "stderr keeps the line" "$(cat "$T_TMP/err")" "Rule not checked: gitflow"
raw "git status"
assert_eq "nothing to say, nothing on stdout" "" "$R_OUT"
# two unchecked rules in one command: still exactly one JSON document
raw "gh pr create --title x; gh pr create --title y"
assert_eq "one document for two findings" 1 "$(printf '%s' "$R_OUT" | jq -s 'length' 2>/dev/null)"
# a block is not a not-checked: no JSON on stdout
on develop
raw "git commit -m x"
assert_eq "a block exits 2" 2 "$R_RC"
assert_eq "a block prints nothing on stdout" "" "$R_OUT"
# jq absent: the JSON is built without it
raw "git commit -m x" "$(no_jq_path)"
assert_eq "jq missing: allowed" 0 "$R_RC"
assert_contains "jq missing: hook JSON by hand" "$R_OUT" '"additionalContext":"Rule not checked: gitflow (jq is not installed). I let it through."'
assert_eq "jq missing: the by-hand JSON parses" "PreToolUse" "$(printf '%s' "$R_OUT" | jq -r '.hookSpecificOutput.hookEventName' 2>/dev/null)"

t_end
