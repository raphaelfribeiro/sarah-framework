#!/bin/sh
# Score one blinded packet, three times, by three independent judges.
#
#   sh judge.sh A
#
# Three judges per packet, scored independently and reconciled by median. One
# judge is a single draw from a non-deterministic scorer; three give a spread
# and make a lone outlier visible instead of decisive.
#
# JUDGES RUN WITHOUT THE FRAMEWORK (--setting-sources project). If a judge had
# the plugin loaded it could invoke sarah:code-reviewer and put the framework
# inside its own evaluation. It also keeps every judge identical regardless of
# which arm produced the packet.
#
# Judges are never told which arm produced a packet, that arms exist, or that a
# comparison is happening. The packet is a piece of software to be scored
# against a rubric, and that is all they know.
set -eu

LABEL="${1:?usage: judge.sh <packet-label>}"

BASE=<HOME>/dev/sarah-runs/phase-e
PACKET="$BASE/judging/packet-$LABEL"
RUBRIC="$BASE/rubric.md"
OUT="$BASE/judging/scores"

[ -d "$PACKET" ] || { echo "no packet: $PACKET"; exit 1; }
mkdir -p "$OUT"

RUBRIC_TEXT=$(cat "$RUBRIC")

n=1
while [ "$n" -le 3 ]; do
  dest="$OUT/packet-$LABEL-judge-$n.json"
  if [ -s "$dest" ]; then
    echo "packet $LABEL judge $n already scored, skipping"
    n=$((n + 1))
    continue
  fi

  echo "packet $LABEL, judge $n ($(date +%H:%M:%S))"

  # The judge must be inside the packet: it scores what it can read and run
  # from its working directory, and nothing outside it.
  cd "$PACKET"

  timeout 1800 claude -p "You are scoring a piece of software against a fixed rubric.

The software is in the current directory. Read it, run it, and run its tests.
Score it honestly - this is an assessment, not a code review for the author, and
nobody benefits from a generous number.

$RUBRIC_TEXT

Rules you must follow:

- Every score above 0 needs evidence: a file and line, or a command you ran and
  what it printed. If you did not verify it, it scores 0. An item you believe is
  probably fine but did not check is a 0, not a 1.
- Actually run the test suite. Report what it printed. If you cannot get it to
  run, that is a finding and D1 scores 0.
- Do not credit intent. A comment saying something is handled is not the thing
  being handled.
- If you find a real defect the rubric does not cover, record it in
  unanticipated_findings with enough detail that someone could reproduce it.

Reply with ONLY a JSON object, no prose around it, in exactly this shape:

{\"scores\": {\"A1\": 0, \"A2\": 0, \"A3\": 0, \"A4\": 0, \"A5\": 0, \"A6\": 0,
 \"B1\": 0, \"B2\": 0, \"B3\": 0, \"B4\": 0, \"B5\": 0,
 \"C1\": 0, \"C2\": 0, \"C3\": 0, \"C4\": 0,
 \"D1\": 0, \"D2\": 0, \"D3\": 0, \"D4\": 0,
 \"E1\": 0, \"E2\": 0, \"E3\": 0},
 \"evidence\": {\"A1\": \"file:line or command output\"},
 \"test_output\": \"what the suite actually printed\",
 \"unanticipated_findings\": [\"...\"],
 \"total\": 0}" \
    --setting-sources project \
    --allowedTools "Read,Glob,Grep,Bash" \
    --output-format json \
    > "$dest.raw" 2>&1 || echo "  judge $n exited non-zero, keeping partial output"

  # The result field holds the model's reply; pull the JSON object out of it.
  python3 - "$dest.raw" "$dest" <<'PY' || echo "  could not parse judge $n output"
import json, re, sys
raw = open(sys.argv[1], errors="replace").read()
try:
    outer = json.loads(raw)
    text = outer.get("result", "")
except Exception:
    text = raw
m = re.search(r"\{.*\}", text, re.S)
if not m:
    sys.exit(1)
obj = json.loads(m.group(0))
json.dump(obj, open(sys.argv[2], "w"), indent=2)
print(f"  total: {obj.get('total')}")
PY

  n=$((n + 1))
done

echo "packet $LABEL scored"
