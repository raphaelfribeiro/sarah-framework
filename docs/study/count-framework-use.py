#!/usr/bin/env python3
"""Count framework invocations in one step's stream-json log.

Prints a single integer on stdout and exits 0. On any failure it prints nothing
to stdout, explains itself on stderr, and exits non-zero — because the caller
must be able to tell "the framework was never invoked" from "the count did not
happen". Those two are the same number of characters apart and worlds apart in
meaning: a zero here is the study's headline finding.

That distinction is not hypothetical. The first version of this counter was an
inline heredoc that crashed with AttributeError on the one event in four
hundred whose `message` is a string rather than an object — a
system/permission_denied notice. The traceback went to a stderr nobody read,
the empty output became `${used:-0}`, and sarah-3 step 1 was logged as
"invoked the framework zero times - recorded as a finding".

It lives in a file rather than in the harness so the harness and any later
recount share one expression. Two copies of a rule disagree eventually; that
already happened once in this repository, with a rename.
"""
import json
import sys

# A slash command is expanded before it becomes a tool call, so a step that
# carries an explicit /sarah-init will legitimately count zero. Step 0 is
# judged by artefacts on disk for that reason. Steps 1-3 carry no slash
# command, so routing must appear here as a real invocation.
FRAMEWORK_TOOLS = ("Skill", "Agent", "Task")


def count(path):
    """Return the number of framework tool invocations in a step log."""
    n = 0
    with open(path, errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                ev = json.loads(line)
            except ValueError:
                # A truncated or interleaved line. Skipping one line is not a
                # failure of the count; anything worse raises and is reported.
                continue
            if not isinstance(ev, dict):
                continue
            msg = ev.get("message")
            # system events carry `message` as a plain string. Everything that
            # can hold a tool_use carries an object with a content list, so
            # anything else is simply not a candidate.
            if not isinstance(msg, dict):
                continue
            content = msg.get("content")
            if not isinstance(content, list):
                continue
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "tool_use" and block.get("name") in FRAMEWORK_TOOLS:
                    n += 1
    return n


def main(argv):
    if len(argv) != 2:
        print("usage: count-framework-use.py <step.jsonl>", file=sys.stderr)
        return 2
    try:
        total = count(argv[1])
    except OSError as exc:
        print(f"cannot read {argv[1]}: {exc}", file=sys.stderr)
        return 1
    except Exception as exc:  # noqa: BLE001 - any crash must not read as zero
        print(f"count failed on {argv[1]}: {exc!r}", file=sys.stderr)
        return 1
    print(total)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
