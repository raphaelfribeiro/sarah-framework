#!/bin/sh
# Phase F, all six runs, unattended.
#
#   STUDY_BASE=/path/to/phase-f STUDY_BRIEF=/path/to/brief.md sh run-phase-f.sh
#
# Runs sarah-1, plain-1, sarah-2, plain-2, sarah-3, plain-3 in that order, so a
# matched pair completes before the next one starts and an interrupted study
# still has whole pairs to compare rather than three of one arm.
#
# Rate limits are expected, not exceptional. A step that hits one exits 5 and
# leaves its log; this waits and re-invokes, and run-arm-phase-f.sh skips every
# step that already finished. Nothing is lost and nobody has to watch it.
set -u

BASE="${STUDY_BASE:?set STUDY_BASE to the study run directory}"
BRIEF="${STUDY_BRIEF:-$BASE/brief.md}"
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ARM_SCRIPT="$HERE/run-arm-phase-f.sh"

[ -f "$ARM_SCRIPT" ] || { echo "no run-arm-phase-f.sh beside this script"; exit 2; }
[ -f "$BRIEF" ] || { echo "no brief at $BRIEF - set STUDY_BRIEF"; exit 2; }

WAIT=${STUDY_WAIT:-900}      # 15 minutes between attempts after a rate limit
MAX_ATTEMPTS=${STUDY_MAX_ATTEMPTS:-40}

mkdir -p "$BASE/logs"
LOG="$BASE/logs/orchestrator.log"
say() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

# Starting the study never destroys it.
#
# This used to archive everything in runs/ unconditionally, because on
# 2026-08-14 the only thing there was two pre-fix builds carrying the
# setting-sources confound. That migration ran once and is done. The rule it
# left behind was not "clear the confound", it was "clear whatever is here",
# and the documented recovery step is to rerun this script - so the first
# response to a dead orchestrator would have deleted every finished run and its
# logs. Three runs and about $100 sat inside that window for a day.
#
# Resuming is now the default and the safe one: run-arm-phase-f.sh skips every
# step that already finished, so an existing runs/ is progress, not garbage.
# Discarding is an explicit act, spelled STUDY_ARCHIVE=1, and it still moves
# rather than deletes.
if [ "${STUDY_ARCHIVE:-0}" = "1" ]; then
  if [ -d "$BASE/runs" ] && [ -n "$(ls -A "$BASE/runs" 2>/dev/null)" ]; then
    STAMP=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$BASE/archive"
    mv "$BASE/runs" "$BASE/archive/runs-archived-$STAMP" || {
      say "could not archive runs/ - refusing to start over data I cannot move"; exit 2; }
    [ -d "$BASE/logs" ] && cp -R "$BASE/logs" "$BASE/archive/logs-archived-$STAMP" 2>/dev/null || true
    find "$BASE/logs" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
    say "STUDY_ARCHIVE=1: moved previous runs to archive/runs-archived-$STAMP and cleared their logs"
  fi
elif [ -d "$BASE/runs" ] && [ -n "$(ls -A "$BASE/runs" 2>/dev/null)" ]; then
  say "runs/ already holds work - resuming it; finished steps are skipped and nothing here is moved or deleted"
  say "to start from nothing instead, rerun with STUDY_ARCHIVE=1"
fi
mkdir -p "$BASE/runs"

say "starting Phase F: six runs, brief $BRIEF"
say "arm isolation is verified by the harness before each run; a failure there aborts that run"

STARTED=$(date +%s)

for pair in sarah-1 plain-1 sarah-2 plain-2 sarah-3 plain-3; do
  arm=${pair%-*}
  n=${pair##*-}
  attempt=0

  while [ ! -f "$BASE/logs/$arm-$n/COMPLETE" ]; do
    attempt=$((attempt + 1))
    if [ "$attempt" -gt "$MAX_ATTEMPTS" ]; then
      say "$pair: giving up after $MAX_ATTEMPTS attempts - see logs/$arm-$n/"
      break
    fi
    say "$pair: attempt $attempt"

    STUDY_BASE="$BASE" STUDY_BRIEF="$BRIEF" sh "$ARM_SCRIPT" "$arm" "$n" >> "$LOG" 2>&1
    rc=$?

    if [ -f "$BASE/logs/$arm-$n/COMPLETE" ]; then
      say "$pair: COMPLETE"
      break
    fi

    case "$rc" in
      2) say "$pair: configuration error (exit 2) - fix it and rerun; not retrying"; break ;;
      3) say "$pair: ARM ISOLATION FAILED (exit 3) - the arms are not what they claim; not retrying"; break ;;
      4) say "$pair: framework never initialised (exit 4) - run is void; not retrying"; break ;;
      5) say "$pair: step ended in-band, most likely a rate limit - waiting ${WAIT}s" ;;
      124) say "$pair: a step hit the timeout - waiting ${WAIT}s" ;;
      *) say "$pair: exit $rc - waiting ${WAIT}s" ;;
    esac
    sleep "$WAIT"
  done
done

ELAPSED=$(( ($(date +%s) - STARTED) / 60 ))
DONE=$(find "$BASE/logs" -name COMPLETE 2>/dev/null | wc -l)
say "finished: $DONE of 6 runs complete, ${ELAPSED} minutes elapsed"

if [ "$DONE" -eq 6 ]; then
  : > "$BASE/logs/STUDY-COMPLETE"
  say "all six runs complete - package with package-for-judging.sh, then judge"
else
  say "INCOMPLETE - rerun this script, it resumes from where each run stopped"
fi
