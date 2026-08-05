#!/usr/bin/env python3
"""Measure a file against the ARCHI.md context budget.

S.A.R.A.H. holds ARCHI.md to a hard ceiling of 10% of the context window. The
ceiling exists because an architecture memory too expensive to read gets skimmed
instead, and a skimmed memory is worse than none: it is trusted without being
read.

Standard library only, by design. A framework that needs a pip install before it
can measure a markdown file has already lost.

Usage:
    token_budget.py ARCHI.md
    token_budget.py ARCHI.md --window 200000
    token_budget.py ARCHI.md --json

Exit codes:
    0  within budget
    1  over the ceiling
    2  could not read the file
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# Default assumed context window. Overridable, because the right number depends
# on the model in use and this script cannot know it.
DEFAULT_WINDOW = 200_000

# Fraction of the window ARCHI.md may occupy. This is the rule, not a knob.
CEILING_FRACTION = 0.10

# Below this fraction of the ceiling, the file is comfortable and no action is
# suggested. Between here and the ceiling it is worth watching.
COMFORT_FRACTION = 0.60


def estimate_tokens(text: str) -> int:
    """Estimate token count without a tokenizer.

    This is an estimate and is labelled as one everywhere it surfaces. Real
    tokenization needs the model's vocabulary, which is not available offline.

    The heuristic: English prose runs near 4 characters per token, but markdown
    is denser than prose. Tables, code fences, punctuation, and long paths all
    tokenize worse than running text. Counting words and punctuation separately
    tracks that better than dividing the character count by a constant.

    Calibrated against Claude Code's own reported token counts for this
    repository's skill files, it lands within roughly 10% in both directions -
    close enough for a budget gauge, not close enough to argue over the last
    hundred tokens. Treat a reading near the ceiling as near the ceiling.
    """
    words = re.findall(r"[A-Za-z]+", text)
    # Short words are usually one token; longer ones split roughly every four
    # characters.
    word_tokens = sum(1 if len(w) <= 4 else -(-len(w) // 4) for w in words)

    # Everything that is not a letter or whitespace: punctuation, digits,
    # markdown syntax, path separators. These tokenize densely.
    symbols = len(re.findall(r"[^A-Za-z\s]", text))

    # Newlines carry their own tokens in markdown-heavy text.
    newlines = text.count("\n")

    return int(word_tokens + symbols * 0.5 + newlines * 0.5)


def bar(fraction: float, width: int = 32) -> str:
    filled = min(width, int(fraction * width))
    return "#" * filled + "." * (width - filled)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Measure a file against the S.A.R.A.H. context budget."
    )
    parser.add_argument("path", help="file to measure, normally ARCHI.md")
    parser.add_argument(
        "--window",
        type=int,
        default=DEFAULT_WINDOW,
        help=f"context window in tokens (default {DEFAULT_WINDOW})",
    )
    parser.add_argument(
        "--json", action="store_true", help="machine-readable output"
    )
    args = parser.parse_args()

    path = Path(args.path)
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        print(f"Cannot read {path}: {exc}", file=sys.stderr)
        return 2

    tokens = estimate_tokens(text)
    ceiling = int(args.window * CEILING_FRACTION)
    used = tokens / ceiling if ceiling else 0.0

    if used >= 1.0:
        status, advice = "OVER", "Compact it. This is over the hard ceiling."
    elif used >= COMFORT_FRACTION:
        status, advice = (
            "WATCH",
            "Still within budget, but drifting. Worth a pass soon.",
        )
    else:
        status, advice = "OK", "Comfortable. No action needed."

    if args.json:
        print(
            json.dumps(
                {
                    "path": str(path),
                    "lines": text.count("\n") + 1,
                    "bytes": len(text.encode("utf-8")),
                    "estimated_tokens": tokens,
                    "window": args.window,
                    "ceiling": ceiling,
                    "fraction_of_ceiling": round(used, 4),
                    "fraction_of_window": round(tokens / args.window, 4)
                    if args.window
                    else 0,
                    "status": status,
                    "estimate": True,
                },
                indent=2,
            )
        )
    else:
        print(f"{path}")
        print(f"  {text.count(chr(10)) + 1} lines, {len(text.encode('utf-8')):,} bytes")
        print(f"  ~{tokens:,} tokens (estimated, no tokenizer available)")
        print(f"  ceiling: {ceiling:,} tokens = 10% of a {args.window:,} window")
        print(f"  [{bar(used)}] {used * 100:.0f}% of ceiling")
        print(f"  {status} - {advice}")

    return 1 if status == "OVER" else 0


if __name__ == "__main__":
    sys.exit(main())
