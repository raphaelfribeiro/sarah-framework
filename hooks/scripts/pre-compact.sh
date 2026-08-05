#!/bin/sh
# S.A.R.A.H. — PreCompact.
#
# Context compaction discards detail. Anything not carried forward is gone, and
# what is worth carrying is exactly what S.A.R.A.H. already writes down:
# sarah/state.md holds the phase, the level, the open gates, and the pending
# decisions.
#
# So this hook does not try to summarize the session. It points at the file that
# already holds the durable state, and reminds the session to write anything
# that is not in it yet BEFORE the detail disappears.
#
# Contract: sensor only. Exits 0 on every path. Silent outside S.A.R.A.H.
# projects.
#
# POSIX sh only.

set -u
trap 'exit 0' EXIT

payload=$(cat 2>/dev/null || true)

project_dir=""
if [ -n "$payload" ] && command -v jq >/dev/null 2>&1; then
    project_dir=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)
fi
[ -n "$project_dir" ] && [ -d "$project_dir" ] || project_dir="${CLAUDE_PROJECT_DIR:-}"
[ -n "$project_dir" ] && [ -d "$project_dir" ] || project_dir="$PWD"

state="$project_dir/sarah/state.md"
[ -r "$state" ] || exit 0

echo "Context is about to be compacted. Detail not written down is lost."
echo "Before continuing: if anything decided or discovered in this session is not yet in sarah/state.md - a gate that closed, a decision the user made, a blocker found, a next step agreed - write it there now."
echo "After compaction, sarah/state.md and ARCHI.md are the reliable record of where the work stands. Re-read them rather than reconstructing from memory."

exit 0
