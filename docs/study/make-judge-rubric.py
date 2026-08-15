#!/usr/bin/env python3
"""Produce the judge-facing extract of the scoring rubric.

`rubric-v2.md` is two documents in one file. Most of it is the instrument: how
to score, the admission gate, and the items. The rest is the *derivation* — a
table of predicted scores per run, and appendices that quote the artefacts by
name. Those name runs (`plain-1`, `sarah-3`), name the framework, and announce
that six artefacts are being compared.

Handing a judge the whole file would end the blinding in the first paragraph.
Judges are never told which arm produced a packet, that arms exist, or that a
comparison is happening.

So this keeps a paragraph only when nothing in it can identify a run, an arm, or
the experiment — exclusion, not enumeration, because the list of things that
give the game away is not knowable in advance. Whatever survives is checked
again at the end, and the script refuses rather than emit a leaky rubric.

    make-judge-rubric.py rubric-v2.md > rubric-for-judges.md
"""
import re
import sys

# Anything that can name a run, the framework, or the study around it.
IDENTIFYING = re.compile(
    r"""(
        plain-\d | sarah | s\.a\.r\.a\.h
      | \barms?\b | \bcontrol\b | treatment
      | six\s+artefacts | \bstudy\b | comparison | calibrat
      | predicted\s+scores | \bv1\b | \bjudge\s+[A-F]-\d
      | ARCHI\.md | state\.md | changelog
    )""",
    re.I | re.X,
)

NEUTRAL_TITLE = """# Scoring rubric

Each item: **2** fully met, **1** partially met, **0** absent or wrong.
"""


def paragraphs(text):
    """Split on blank lines, but keep fenced code and tables whole."""
    blocks, current, in_fence = [], [], False
    for line in text.splitlines():
        if line.strip().startswith("```"):
            in_fence = not in_fence
        if not line.strip() and not in_fence:
            if current:
                blocks.append("\n".join(current))
                current = []
        else:
            current.append(line)
    if current:
        blocks.append("\n".join(current))
    return blocks


def extract(text):
    kept, dropped = [], 0
    current_heading_dropped = False
    for block in paragraphs(text):
        is_heading = block.lstrip().startswith("#")
        if IDENTIFYING.search(block):
            dropped += 1
            # A contaminated heading takes its section with it until the next
            # heading of the same or higher level.
            current_heading_dropped = is_heading
            continue
        if is_heading:
            current_heading_dropped = False
        elif current_heading_dropped:
            dropped += 1
            continue
        kept.append(block)
    return kept, dropped


def main(argv):
    if len(argv) != 2:
        print(f"usage: {argv[0]} <rubric.md>", file=sys.stderr)
        return 2
    text = open(argv[1], errors="replace").read()
    kept, dropped = extract(text)
    out = NEUTRAL_TITLE + "\n" + "\n\n".join(kept) + "\n"

    # The gate: whatever the logic above believed, the output is what ships.
    leak = IDENTIFYING.search(out)
    if leak:
        print(
            f"REFUSING: judge-facing rubric still contains {leak.group(0)!r}",
            file=sys.stderr,
        )
        return 1

    items = sorted(set(re.findall(r"^#+\s+([A-Z]\d+)\b", out, re.M)))
    print(out)
    print(
        f"kept {len(kept)} blocks, dropped {dropped}, items: {' '.join(items)}",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
