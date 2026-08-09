#!/bin/sh
# Remove references to paths that are not in the packet.
#
# The strip removes sarah/, docs/ and ARCHI.md from every packet, but a README
# written by the run still documents them - typically in a directory tree. That
# leaks the arm to any judge who reads the README, and it also describes files
# the judge cannot find, which would unfairly cost the packet on rubric item E3
# ("a reader can run it from the documentation alone").
#
# So: drop any LINE that references a path the packet no longer contains. Run
# over all six packets identically. Control packets contain no such lines, so
# nothing changes there - the rule is symmetric even though only one arm trips
# it, because the rule is "describe what is in the packet" and not "hide the
# framework".
#
# This edits an artefact after the fact, which is worth stating plainly. The
# alternative was leaving the arm visible in three of six packets, which would
# have made every blind score meaningless.
set -eu

BASE="${STUDY_BASE:?set STUDY_BASE to the study run directory}"

for packet in "$BASE"/judging/packet-*; do
  [ -d "$packet" ] || continue
  label=$(basename "$packet")
  changed=0

  # Text files only; never touch binaries.
  for f in $(grep -rlI . "$packet" 2>/dev/null); do
    before=$(md5sum "$f" | cut -d' ' -f1)
    # Drop lines naming a stripped path.
    sed -i -E '/(^|[^a-zA-Z0-9_-])(sarah\/|docs\/specs|docs\/adr|docs\/plans|docs\/design|ARCHI\.md|CLAUDE\.md)/d' "$f"
    after=$(md5sum "$f" | cut -d' ' -f1)
    [ "$before" != "$after" ] && { changed=$((changed + 1)); echo "  edited: ${f#$packet/}"; }
  done

  echo "$label: $changed file(s) edited"
done

echo
echo "verifying no packet still names the framework:"
fail=0
for packet in "$BASE"/judging/packet-*; do
  hits=$(grep -rlI -i -E 's\.a\.r\.a\.h|sarah' "$packet" 2>/dev/null | wc -l)
  echo "  $(basename "$packet"): $hits"
  [ "$hits" -gt 0 ] && fail=1
done
exit $fail
