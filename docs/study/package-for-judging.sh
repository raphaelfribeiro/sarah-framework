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

# Every argument becomes part of a path that gets rm -rf'd and cp'd into. A
# label of "../../elsewhere" would copy the artefact outside the study tree and,
# on the second run with the same label, delete that directory first. Nothing
# downstream validates these, so they are validated here.
for v in "$ARM" "$N" "$LABEL"; do
  case "$v" in
    ''|*[!A-Za-z0-9_-]*)
      echo "arguments must contain only [A-Za-z0-9_-]: got '$v'"; exit 2 ;;
  esac
done

BASE="${STUDY_BASE:?set STUDY_BASE to the study run directory}"
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

# Neutralise references to stripped paths WITHOUT deleting lines.
#
# The previous version deleted any line naming a stripped path. Only the
# framework arm cross-references its own documents, so the deletion fired on
# three packets and none of the others - truncating prose mid-sentence and
# handing judges "dangling reference" defects that the study itself created.
# Roughly 15% of the evidence base was instrument noise, perfectly correlated
# with one arm.
#
# A symlink in the artefact tree points wherever the build put it, and cp -a
# preserves it as a live link. The packet is handed to judges who build a venv
# and run the suite inside it; anything that opens the link follows it out of
# the packet. Refuse to ship one rather than carry it.
#
# The check is by exclusion, not by enumeration. Refusing symlinks specifically
# left FIFOs, sockets and device nodes walking through untouched - cp -a
# preserves those too, find -type f never selects them, and a judge's `cat` on a
# FIFO blocks forever. An artefact tree is regular files and directories; refuse
# whatever else appears rather than maintain a list of what to fear.
if find "$DEST" ! -type f ! -type d | grep -q .; then
  echo "REFUSING: the packet holds something other than files and directories:"
  find "$DEST" ! -type f ! -type d -exec ls -ld {} +
  rm -rf "$DEST"
  exit 1
fi

# A hardlink survives differently: cp -a dereferences a link to a file outside
# the source tree, so the packet gets the CONTENT with nothing left to detect.
# The link count is only visible on the source side, and only the paths that
# survived the strip are worth checking - .venv routinely hardlinks and is
# removed above, so checking $SRC wholesale would refuse every real run.
HARDLINKS=$(mktemp)
export SRC DEST HARDLINKS
find "$DEST" -type f -exec sh -c '
  for d do
    rel=${d#"$DEST/"}
    [ -f "$SRC/$rel" ] || continue
    if [ -n "$(find "$SRC/$rel" -maxdepth 0 -links +1 -print 2>/dev/null)" ]; then
      echo "  $rel" >> "$HARDLINKS"
    fi
  done
' sh {} +
if [ -s "$HARDLINKS" ]; then
  echo "REFUSING: hardlinked files in the run - their content would be copied in blind:"
  cat "$HARDLINKS"
  rm -f "$HARDLINKS"
  rm -rf "$DEST"
  exit 1
fi
rm -f "$HARDLINKS"

# Substituting a token preserves every line and every sentence.
#
# The file list comes from find, not from an unquoted $(grep -rl). A single
# space in an artefact filename word-splits that substitution, and with set -eu
# the script dies here - after the rewrite has already touched some files and
# before the integrity check below ever runs. The safety net cannot be the thing
# that fails first.
find "$DEST" -type f -exec grep -Iq . {} ';' -exec sed -i -E \
  -e 's#\[([^]]*)\]\((\.\./)*(docs/(specs|adr|plans|design)|ARCHI\.md|CLAUDE\.md)[^)]*\)#\1#g' \
  -e 's#(sarah/|docs/(specs|adr|plans|design)/|ARCHI\.md|CLAUDE\.md)#the project documentation#g' \
  -e 's#[Ss]\.?A\.?R\.?A\.?H\.?#the framework#gI' \
  {} +

# Symmetric integrity check: line counts must be unchanged from the source.
MISMATCH=$(mktemp)
export SRC DEST MISMATCH
find "$DEST" -type f -exec grep -Iq . {} ';' -exec sh -c '
  for d do
    rel=${d#"$DEST/"}
    [ -f "$SRC/$rel" ] || continue
    a=$(wc -l < "$SRC/$rel"); b=$(wc -l < "$d")
    if [ "$a" != "$b" ]; then
      echo "  LINE COUNT CHANGED in $rel: $a -> $b"
      echo x >> "$MISMATCH"
    fi
  done
' sh {} +
if [ -s "$MISMATCH" ]; then
  rm -f "$MISMATCH"
  echo "REFUSING: the sanitiser changed line counts - this is the Phase E leak again"
  rm -rf "$DEST"
  exit 1
fi
rm -f "$MISMATCH"
echo "  line counts intact"

# This was a WARNING that exited 0, which meant a packet naming the framework in
# plain text shipped to judges while the script reported success. Two rounds of
# review found it, the second time as a live leak: the substitution above only
# matched dotted capitals, so an ordinary "/sarah-init" in a README walked
# straight through and the warning scrolled past.
#
# The substitution is case-insensitive now, and this check refuses rather than
# warns. Blinding is not optional, and a check that cannot stop the thing it
# detects is decoration.
if grep -rlI -i -E 's\.a\.r\.a\.h|sarah' "$DEST" 2>/dev/null | grep -q .; then
  echo "REFUSING: files still name the framework - blinding is not optional:"
  grep -rlI -i -E 's\.a\.r\.a\.h|sarah' "$DEST" 2>/dev/null
  rm -rf "$DEST"
  exit 1
fi

# Record the mapping where judges will never see it.
mkdir -p "$BASE/judging"
echo "$LABEL=$ARM-$N" >> "$BASE/judging/KEY-DO-NOT-SHOW-JUDGES.txt"

echo "packet $LABEL built from $ARM-$N"
find "$DEST" -type f | wc -l | sed 's/^/  files: /'
