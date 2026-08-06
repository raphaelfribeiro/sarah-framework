#!/bin/sh
# Run one arm of the Phase E study.
#
#   sh run-arm.sh sarah 1     - with the framework, 8 phases
#   sh run-arm.sh plain 1     - control, no framework
#
# One run per invocation, deliberately. Six runs in one script would die on the
# session rate limit and lose everything after the cut; each run here is
# independently resumable and records its own completion marker.
#
# THE CONTROL ARM MUST NOT SEE THE FRAMEWORK. `--setting-sources project` drops
# user-scope settings, which is where the plugin is installed. Verified: in the
# same directory, the default invocation lists 15 sarah skills and this one
# lists none. Both arms run a sanity check before any work, and refuse to
# proceed if the condition is wrong - a control arm that silently had the
# framework loaded would invalidate the study without anyone noticing.
set -u

ARM="${1:?usage: run-arm.sh <sarah|plain> <n>}"
N="${2:?usage: run-arm.sh <sarah|plain> <n>}"

BASE=<HOME>/dev/sarah-runs/phase-e
DIR="$BASE/runs/$ARM-$N"
LOGDIR="$BASE/logs/$ARM-$N"
BRIEF="$BASE/brief.md"
STATUS="$BASE/logs/status.txt"

TOOLS="Read,Write,Edit,Glob,Grep,Bash,Task,Agent,TodoWrite,Skill"
PHASE_TIMEOUT=2400

case "$ARM" in
  sarah) SETTINGS="" ;;
  plain) SETTINGS="--setting-sources project" ;;
  *) echo "arm must be sarah or plain"; exit 2 ;;
esac

mkdir -p "$DIR" "$LOGDIR"
cd "$DIR" || exit 1
[ -d .git ] || {
  git init -q
  git config user.name "Study Runner"
  git config user.email "study@example.invalid"
}

say() { echo "[$ARM-$N] $* ($(date +%H:%M:%S))"; echo "[$ARM-$N] $*" > "$STATUS"; }

# --- sanity: is this arm actually the arm it claims to be? ---------------
say "checking arm isolation"
probe=$(claude -p "List the exact names of any skills available to you whose name starts with 'sarah'. If none, reply NONE." \
          $SETTINGS --output-format json 2>/dev/null \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('result',''))" 2>/dev/null)

case "$ARM" in
  sarah)
    echo "$probe" | grep -q "sarah-bootstrap" || {
      echo "ABORT: framework arm cannot see the framework. Probe said: $probe"
      echo "The directory may not be trusted. Run claude interactively here once."
      exit 3
    }
    say "isolation ok: framework present" ;;
  plain)
    if echo "$probe" | grep -q "sarah-bootstrap"; then
      echo "ABORT: control arm can see the framework. Probe said: $probe"
      exit 3
    fi
    say "isolation ok: framework absent" ;;
esac
echo "$probe" > "$LOGDIR/isolation-probe.txt"

run_step() {
  n="$1"; label="$2"; cont="$3"; prompt="$4"
  out="$LOGDIR/step-$n-$label.jsonl"
  [ -s "$out" ] && grep -q '"type":"result"' "$out" && { say "step $n ($label) already done, skipping"; return 0; }

  say "step $n: $label"
  : > "$out"
  if [ "$cont" = "new" ]; then
    timeout "$PHASE_TIMEOUT" claude -p "$prompt" $SETTINGS \
      --allowedTools "$TOOLS" --output-format stream-json --verbose >> "$out" 2>&1
  else
    timeout "$PHASE_TIMEOUT" claude -p "$prompt" --continue $SETTINGS \
      --allowedTools "$TOOLS" --output-format stream-json --verbose >> "$out" 2>&1
  fi
  rc=$?
  echo "[step $n exit=$rc at $(date +%H:%M:%S)]" >> "$out"
  if [ "$rc" -ne 0 ]; then
    say "step $n FAILED (exit=$rc) - rerun this same command to resume"
    exit "$rc"
  fi
}

BRIEF_TEXT=$(cat "$BRIEF" | sed -n '/^---$/,$p' | sed '1d')

if [ "$ARM" = "sarah" ]; then
  # Eight steps, prompts phrased as a user would phrase them. No skill or agent
  # is ever named: what the framework routes to on its own is the measurement.
  run_step 1 "init" "new" "/sarah-init

I want to build this:

$BRIEF_TEXT

Answer the setup interview yourself from that description. Decide anything I did
not specify and state what you decided. Do not ask me anything and do not stop
for approval."
  run_step 2 "brainstorm" "cont" "Before we build anything, I want to think this through properly.

Do not ask me anything and do not stop for approval. Decide anything open yourself and say what you decided."
  run_step 3 "spec" "cont" "Now pin it down - what exactly should it do, and how will we know it works.

Do not ask me anything and do not stop for approval. Decide anything open yourself and say what you decided."
  run_step 4 "architecture" "cont" "How should we build this? I need the structure settled before anyone writes code.

Do not ask me anything and do not stop for approval. Decide anything open yourself and say what you decided."
  run_step 5 "design" "cont" "Now the surface - the endpoints, what they return, and what happens when things go wrong.

Do not ask me anything and do not stop for approval. Decide anything open yourself and say what you decided."
  run_step 6 "implement" "cont" "Build it.

Do not ask me anything and do not stop for approval. Report honestly what passes, what fails, and what you did not finish."
  run_step 7 "review" "cont" "Implementation is done. Review it before merge, with fresh eyes that did not write it. Report a pass or the blocking changes.

Do not ask me anything and do not stop for approval."
  run_step 8 "release" "cont" "Resolve anything the review blocked on, then cut the release: determine the version, write the notes, and tag it.

Decide anything open yourself. Do not ask me anything and do not stop for approval."
else
  # Control: plain Claude Code, used well. Same brief, same tools, same model.
  #
  # It gets FOUR turns against the framework arm's eight, and that asymmetry is
  # deliberate in the control's favour on a per-turn basis: each control turn is
  # open-ended ("keep going until it is done") rather than scoped to one phase,
  # so the control is never truncated mid-thought. Giving it one single turn
  # would measure context exhaustion rather than process, and giving it eight
  # phase-shaped turns would be handing it the framework's structure without
  # the framework - which is the straw man this study must avoid in the other
  # direction.
  run_step 1 "build" "new" "$BRIEF_TEXT

Build this properly. Take as long as you need and do the job well.

Do not ask me anything and do not stop for approval. Decide anything I left open and state what you decided."
  run_step 2 "continue" "cont" "Keep going until it is done. If it is already done, say so and stop.

Do not ask me anything and do not stop for approval."
  run_step 3 "verify" "cont" "Check your own work over and fix whatever is wrong. Show the actual test output.

Do not ask me anything and do not stop for approval."
  run_step 4 "finish" "cont" "Finish up: make sure it is committed, documented, and someone else could run it.

Do not ask me anything and do not stop for approval."
fi

say "COMPLETE"
echo "done" > "$LOGDIR/COMPLETE"
