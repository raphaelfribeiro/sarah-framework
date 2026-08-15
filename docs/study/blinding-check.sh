#!/bin/sh
# Ask a fresh reader whether a packet betrays how it was built.
#
#   STUDY_BASE=... sh blinding-check.sh A
#
# The blinding here is imperfect and known to be: a framework-arm packet has its
# process documents stripped, and the references to them left behind become a
# neutral phrase that appears in that arm and in no other. Eighteen such lines
# across three packets, zero across the other three.
#
# Pretending otherwise would repeat the mistake this study already made once.
# So the residue is measured instead: if readers can name the arm, the scores
# are contaminated and the report has to say so; if they cannot, the blinding
# held despite the scar. Either way it is evidence rather than hope.
#
# This runs SEPARATELY from scoring and AFTER it. A judge asked "was a process
# framework used here?" before scoring would start hunting for the answer, and
# the hunt would change the scores. The scoring judge is never told any of this
# exists.
set -eu

LABEL="${1:?usage: blinding-check.sh <packet-label>}"
BASE="${STUDY_BASE:?set STUDY_BASE to the study run directory}"
PACKET="$BASE/judging/packet-$LABEL"
OUT="$BASE/judging/blinding"

[ -d "$PACKET" ] || { echo "no packet: $PACKET"; exit 1; }
mkdir -p "$OUT"

dest="$OUT/packet-$LABEL.json"
if [ -s "$dest" ]; then echo "packet $LABEL already checked, skipping"; exit 0; fi

cd "$PACKET"

timeout 900 claude -p "This directory holds a software project. Read it.

Some projects are built by a developer working straight from a brief. Others are
built under a structured development process - one that produces specifications,
architecture records, decision logs and a workflow state file as it goes, and
whose traces can survive into the code even when those documents are absent.

Judge only from what is in front of you. Guess if you must, but say how sure you
are, and say what made you think so - the specific file and line, not a general
impression.

Reply with ONLY a JSON object:

{\"process_framework_used\": \"yes\" or \"no\",
 \"confidence\": 0-100,
 \"evidence\": [\"file:line - what it shows\"],
 \"reasoning\": \"one or two sentences\"}" \
  --setting-sources project \
  --allowedTools "Read,Glob,Grep" \
  --output-format json \
  > "$dest.raw" 2>&1 || echo "  check exited non-zero, keeping partial output"

python3 - "$dest.raw" "$dest" <<'PY' || echo "  could not parse the check output"
import json, re, sys
raw = open(sys.argv[1], errors="replace").read()
try:
    text = json.loads(raw).get("result", "")
except Exception:
    text = raw
m = re.search(r"\{.*\}", text, re.S)
if not m:
    sys.exit(1)
obj = json.loads(m.group(0))
json.dump(obj, open(sys.argv[2], "w"), indent=2)
print(f"  guess: {obj.get('process_framework_used')} at {obj.get('confidence')}%")
PY

echo "packet $LABEL checked"
