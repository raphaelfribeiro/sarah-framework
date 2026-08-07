#!/bin/sh
# Package one run's artefact for blind judging.
#
#   sh package-for-judging.sh sarah 1 A
#
# The third argument is the anonymous label the judges see. Labels are assigned
# so that nothing about them encodes the arm: judge packets are A through F, and
# the mapping lives in one file that judges never receive.
#
# What gets stripped, and why: a framework-arm project carries sarah/state.md,
# ARCHI.md and a changelog directory, and a control-arm project does not. A
# judge seeing any of those knows the arm instantly. Git history is stripped for
# the same reason - commit messages and their shape give the arm away as surely
# as a state file does. This costs the framework arm credit for whatever process
# documentation it produced; that trade is recorded in the method document.
set -eu

ARM="${1:?usage: package-for-judging.sh <arm> <n> <label>}"
N="${2:?}"
LABEL="${3:?}"

BASE=<HOME>/dev/sarah-runs/phase-e
SRC="$BASE/runs/$ARM-$N"
DEST="$BASE/judging/packet-$LABEL"

[ -d "$SRC" ] || { echo "no such run: $SRC"; exit 1; }

rm -rf "$DEST"
mkdir -p "$DEST"

# Copy everything, then remove what identifies the arm.
cp -a "$SRC/." "$DEST/"

# The strip is SYMMETRIC: the same paths are removed from both arms, whether or
# not they exist there. Removing "the framework's directories" from one arm and
# nothing from the other would leak the arm through what survived, and an
# enumerated list of framework-specific paths always misses one - the first run
# produced docs/plans/ and docs/design/, neither of which was on the original
# list.
#
# docs/ goes entirely. It holds specs, ADRs, plans and design notes, which are
# process artefacts rather than the software. README.md stays, and it is what
# rubric item E3 is scored against.
rm -rf "$DEST/.git" \
       "$DEST/sarah" \
       "$DEST/docs" \
       "$DEST/ARCHI.md" \
       "$DEST/CLAUDE.md" \
       "$DEST/.claude" \
       "$DEST/.venv" \
       "$DEST/.pytest_cache" \
       "$DEST/.coverage" 2>/dev/null || true

# Any remaining file that names the framework would give it away.
if grep -rlI -i -E 's\.a\.r\.a\.h|sarah' "$DEST" 2>/dev/null | grep -q .; then
  echo "WARNING: files still mention the framework by name:"
  grep -rlI -i -E 's\.a\.r\.a\.h|sarah' "$DEST" 2>/dev/null
  echo "Review these by hand before judging - blinding is not optional."
fi

# Record the mapping where judges will never see it.
mkdir -p "$BASE/judging"
echo "$LABEL=$ARM-$N" >> "$BASE/judging/KEY-DO-NOT-SHOW-JUDGES.txt"

echo "packet $LABEL built from $ARM-$N"
find "$DEST" -type f | wc -l | sed 's/^/  files: /'
