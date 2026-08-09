#!/bin/sh
# Score all six packets, waiting out rate limits.
set -u
BASE="${STUDY_BASE:?set STUDY_BASE to the study run directory}"
LOG="$BASE/logs/judging.log"
note() { echo "$(date '+%H:%M:%S') $*" >> "$LOG"; echo "$*" > "$BASE/logs/judge-status.txt"; }

wait_for_quota() {
  i=0
  while [ "$i" -lt 40 ]; do
    if timeout 90 claude -p "Reply with exactly: OK" --output-format json 2>/dev/null | grep -q '"is_error":false'; then
      note "quota back"; return 0
    fi
    i=$((i+1)); note "rate limited, waiting ($i/40)"; sleep 900
  done
  return 1
}

for label in A B C D E F; do
  attempt=0
  while [ "$attempt" -lt 8 ]; do
    attempt=$((attempt+1))
    note "packet $label (attempt $attempt)"
    if sh "$BASE/judge.sh" "$label" >> "$LOG" 2>&1; then note "packet $label done"; break; fi
    wait_for_quota || { note "quota gone"; exit 1; }
  done
done
note "JUDGING COMPLETE"
echo done > "$BASE/logs/JUDGING-COMPLETE"
