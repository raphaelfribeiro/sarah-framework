#!/bin/sh
# Runs every tests/shell/test_*.sh in its own shell and totals the results.
# Exit 0 only when every file passes. POSIX sh; no test framework.
#
# Usage: sh tests/shell/run.sh [file ...]

here=$(cd "$(dirname "$0")" && pwd)
files="$*"
[ -n "$files" ] || files=$(ls "$here"/test_*.sh 2>/dev/null)

total_files=0
failed_files=0
for f in $files; do
    total_files=$((total_files + 1))
    echo "== $(basename "$f")"
    if ! sh "$f"; then
        failed_files=$((failed_files + 1))
    fi
done

echo "--"
echo "$total_files file(s), $failed_files failed"
[ "$failed_files" -eq 0 ]
