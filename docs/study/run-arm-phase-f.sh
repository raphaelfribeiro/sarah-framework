#!/bin/sh
# Phase F: does memory of a decision pay for itself?
#
#   sh run-arm.sh sarah 1
#   sh run-arm.sh plain 1
#
# Build once, then three changes, each in a SEPARATE SESSION with no context
# carried over. No --continue anywhere. The session that receives change 2 did
# not write change 1 and can only read what is in the repository.
#
# That is the whole experiment. Phase E compared building from scratch, which is
# the case where a fresh model needs no memory at all - and it tied. This
# measures the case where it does.
set -u

ARM="${1:?usage: run-arm.sh <sarah|plain> <n>}"
N="${2:?usage: run-arm.sh <sarah|plain> <n>}"

BASE=<HOME>/dev/sarah-runs/phase-f
DIR="$BASE/runs/$ARM-$N"
LOGDIR="$BASE/logs/$ARM-$N"
STATUS="$BASE/logs/status.txt"

TOOLS="Read,Write,Edit,Glob,Grep,Bash,Task,Agent,TodoWrite,Skill"
STEP_TIMEOUT=2400

case "$ARM" in
  sarah) SETTINGS="" ;;
  plain) SETTINGS="--setting-sources project" ;;
  *) echo "arm must be sarah or plain"; exit 2 ;;
esac

mkdir -p "$DIR" "$LOGDIR"
cd "$DIR" || exit 1
[ -d .git ] || { git init -q; git config user.name "Study Runner"; git config user.email "study@example.invalid"; }

say() { echo "[$ARM-$N] $* ($(date +%H:%M:%S))"; echo "[$ARM-$N] $*" > "$STATUS"; }

# --- arm isolation, verified before any work ------------------------------
say "checking arm isolation"
probe=$(claude -p "List the exact names of any skills available to you whose name starts with 'sarah'. If none, reply NONE." \
          $SETTINGS --output-format json 2>/dev/null \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('result',''))" 2>/dev/null)
case "$ARM" in
  sarah) echo "$probe" | grep -q "sarah-bootstrap" || { echo "ABORT: framework arm cannot see the framework: $probe"; exit 3; }
         say "isolation ok: framework present" ;;
  plain) echo "$probe" | grep -q "sarah-bootstrap" && { echo "ABORT: control arm can see the framework: $probe"; exit 3; }
         say "isolation ok: framework absent" ;;
esac
echo "$probe" > "$LOGDIR/isolation-probe.txt"

# Capture the suite's state before a change, so regression is objective.
snapshot_tests() {
  label="$1"
  { echo "=== $label at $(date +%H:%M:%S) ==="
    if [ -x .venv/bin/pytest ]; then .venv/bin/pytest -q 2>&1 | tail -5
    elif [ -x .v/bin/pytest ]; then .v/bin/pytest -q 2>&1 | tail -5
    else echo "(no venv found; judge will build one)"; fi
    echo "--- git ---"; git log --oneline 2>&1 | head -5
  } >> "$LOGDIR/test-snapshots.log" 2>&1
}

run_step() {
  n="$1"; label="$2"; prompt="$3"
  out="$LOGDIR/step-$n-$label.jsonl"
  if [ -s "$out" ] && grep -q '"type":"result"' "$out" && ! grep -q '"is_error":true' "$out"; then
    say "step $n ($label) already done, skipping"; return 0
  fi
  say "step $n: $label"
  : > "$out"
  # NO --continue. Every step is a cold session.
  timeout "$STEP_TIMEOUT" claude -p "$prompt" $SETTINGS \
    --allowedTools "$TOOLS" --output-format stream-json --verbose >> "$out" 2>&1
  rc=$?
  echo "[step $n exit=$rc at $(date +%H:%M:%S)]" >> "$out"
  snapshot_tests "after step $n ($label)"

  # Availability is not use. The isolation probe proves the skills are loadable;
  # it cannot prove the model invoked any. A framework-arm step that routed
  # through nothing is a control run wearing the wrong label, and it would be
  # scored as treatment with nothing in the output looking wrong.
  if [ "$ARM" = "sarah" ]; then
    used=$(python3 - "$out" <<'PYEOF'
import json,sys
n=0
for line in open(sys.argv[1],errors="replace"):
    try: ev=json.loads(line)
    except: continue
    c=(ev.get("message") or {}).get("content")
    if isinstance(c,list):
        for b in c:
            if isinstance(b,dict) and b.get("type")=="tool_use" and b.get("name") in ("Skill","Agent","Task"):
                n+=1
print(n)
PYEOF
)
    echo "step $n framework invocations: $used" >> "$LOGDIR/framework-use.log"
    # Step 0 is judged by ARTEFACTS ON DISK, not by tool calls. It carries an
    # explicit /sarah-init, and the harness expands a slash command before it
    # ever becomes a Skill tool_use - so counting tool calls reports zero for a
    # step that ran the framework perfectly well. That false negative already
    # voided one valid run here.
    #
    # Steps 1-3 carry no slash command, so intent routing must appear as a real
    # Skill or Agent call and the counter is meaningful. A zero there is the
    # FINDING, not a failure: it says the framework did not survive the
    # handover to a cold session. Aborting would discard the measurement this
    # study exists to take.
    if [ "$n" = "0" ]; then
      if [ ! -f sarah/state.md ]; then
        say "step 0 produced no sarah/state.md - the framework never initialised, run is void"
        exit 4
      fi
      say "step 0 ok: framework initialised on disk ($used tool invocations)"
    elif [ "${used:-0}" -eq 0 ]; then
      say "step $n invoked the framework zero times - recorded as a finding"
    fi
  fi

  if [ "$rc" -ne 0 ]; then say "step $n FAILED (exit=$rc) - rerun to resume"; exit "$rc"; fi
}

BRIEF=$(sed -n '/^---$/,$p' <HOME>/dev/sarah-runs/phase-e/brief.md | sed '1d')

NOASK="Do not ask me anything and do not stop for approval. Decide anything I left open and state what you decided."

# The framework arm adopts the framework first, exactly as a real user does:
# once, at the start of a project. Every LATER session is cold and unaided -
# it gets only what the repository carries. That is the thing under test.
if [ "$ARM" = "sarah" ]; then
  run_step 0 "build" "/sarah-init

I want to build this:

$BRIEF

Set the project up, then build it properly. Take as long as you need and do the
job well.

$NOASK"
else
  run_step 0 "build" "$BRIEF

Build this properly. Take as long as you need and do the job well.

$NOASK"
fi

snapshot_tests "baseline before change 1"

run_step 1 "new-sender" "We're onboarding a new partner, Globex. Their platform signs the payload on its own - no timestamp in the signed string, and they send the digest base64 rather than hex. Everyone else stays as they are. Get them working.

$NOASK"

run_step 2 "duplicates" "Support is seeing the same delivery processed twice for one customer, maybe once a week. It's costing us money downstream. Make it stop.

$NOASK"

run_step 3 "retention" "Disk on the box is filling up. We need old stuff cleared out, but we can't break the duplicate protection while doing it.

$NOASK"

say "COMPLETE"
echo done > "$LOGDIR/COMPLETE"
