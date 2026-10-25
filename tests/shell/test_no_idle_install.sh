# IH9 (R24): the no-idle habit installs through habits.py, registers one Stop
# hook, and the stamped copy still behaves. Remove takes it out again.
. "$(dirname "$0")/lib.sh"

if ! command -v python3 >/dev/null 2>&1; then
    ok "python3 absent, install test skipped"
    t_end
    exit $?
fi

p=$(mk_project install)
STUB=$(stub_date 2026-10-24)
habits() { python3 -I "$ROOT/scripts/habits.py" --project "$p" --plugin-root "$ROOT" "$@" 2>&1; }

out=$(habits apply no-idle)
assert_eq "apply exits 0" 0 "$?"
installed="$p/sarah/hooks/no-idle/stop.sh"
if [ -f "$installed" ]; then ok "the hook is installed"; else fail "the hook is installed" "$out"; fi
assert_contains "the hook carries a stamp" "$(head -n 1 "$installed" 2>/dev/null)" "# sarah-habit: no-idle "

settings=$(cat "$p/.claude/settings.json" 2>/dev/null)
assert_contains "settings register a Stop hook" "$settings" '"Stop"'
assert_contains "settings point at the installed script" "$settings" "sarah/hooks/no-idle/stop.sh"

# The stamped copy runs: a ready task blocks, then stop_hook_active allows.
printf '## In flight\n\n| Task | File | Phase | Level | Waiting on | Since |\n| --- | --- | --- | --- | --- | --- |\n| Next | `sarah/state/n.md` | ready | 2 | nothing | 2026-10-24 |\n' >"$p/sarah/state.md"
(cd "$p" && PATH="$STUB:$PATH" && printf '{"stop_hook_active":false}' | sh "$installed") >/dev/null 2>&1
assert_eq "the installed copy blocks on ready work" 2 "$?"
(cd "$p" && PATH="$STUB:$PATH" && printf '{"stop_hook_active":true}' | sh "$installed") >/dev/null 2>&1
assert_eq "the installed copy allows when stop_hook_active" 0 "$?"

out=$(habits remove no-idle)
assert_eq "remove exits 0" 0 "$?"
if [ -e "$installed" ]; then fail "remove deletes the hook"; else ok "remove deletes the hook"; fi
assert_not_contains "remove drops the Stop entry" "$(cat "$p/.claude/settings.json" 2>/dev/null)" "no-idle"

t_end
