#!/bin/sh
# S.A.R.A.H. — PreToolUse(Bash), commit inspection.
#
# Looks at `git commit` commands and reports what a reviewer would flag anyway:
# a message that is not conventional, or an obviously hardcoded credential in
# the staged diff.
#
# Contract: this hook is a sensor. It NEVER blocks. It exits 0 on every path and
# writes advice to stdout, which Claude sees and can act on. A workflow that
# blocks a commit on a heuristic will be disabled by the third false positive,
# and then it is not there for the true one.
#
# Fast path: anything that is not `git commit` exits immediately, before any
# other work, so the cost on ordinary Bash calls is one string comparison.
#
# POSIX sh only.

set -u
trap 'exit 0' EXIT

payload=$(cat 2>/dev/null || true)
[ -n "$payload" ] || exit 0

# ---------------------------------------------------------------------------
# Extract the command. Without jq, fall back to a crude grep - and if that
# cannot find it, do nothing rather than guess.
# ---------------------------------------------------------------------------

if command -v jq >/dev/null 2>&1; then
    command_line=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
    command_line=$(printf '%s' "$payload" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
fi

[ -n "${command_line:-}" ] || exit 0

# Fast path: not a commit, nothing to do.
case "$command_line" in
    *"git commit"*) ;;
    *) exit 0 ;;
esac

# Amending or continuing an existing message: the author already decided.
case "$command_line" in
    *--amend*|*--no-edit*) exit 0 ;;
esac

findings=""
note() { findings="${findings}- $1
"; }

# ---------------------------------------------------------------------------
# Conventional commit message.
# ---------------------------------------------------------------------------

# Pull the subject out of -m "..." or -m '...'. A heredoc or editor-composed
# message is not inspectable here, and that is fine - skip it.
subject=$(printf '%s' "$command_line" | sed -n "s/.*-m[[:space:]]*[\"']\([^\"']*\).*/\1/p" | head -n 1)

if [ -n "$subject" ]; then
    if ! printf '%s' "$subject" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?: .+'; then
        note "The message does not look conventional. Expected \`type(scope): summary\` with type in feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert."
    fi

    # A subject long enough to be truncated everywhere it is displayed.
    if [ "${#subject}" -gt 72 ]; then
        note "The subject line is ${#subject} characters. Most tools truncate around 72."
    fi
fi

# ---------------------------------------------------------------------------
# Hardcoded credentials in the staged diff.
#
# Deliberately narrow. Broad secret patterns produce constant false positives on
# test fixtures and example files, and a noisy check is a disabled check.
# ---------------------------------------------------------------------------

if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    staged=$(git diff --cached --no-color 2>/dev/null | grep '^+' | grep -v '^+++' || true)

    if [ -n "$staged" ]; then
        # Long opaque values assigned to a secret-shaped name. Placeholders,
        # environment lookups, and template markers are excluded.
        hits=$(printf '%s' "$staged" |
            grep -iE '(api[_-]?key|secret|password|passwd|token|private[_-]?key|access[_-]?key)[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9/+_=-]{16,}["'"'"']' |
            grep -viE 'example|placeholder|dummy|changeme|your[_-]?|xxx|<|\{\{|\$\{|process\.env|os\.environ|getenv' |
            head -n 3 || true)

        [ -n "$hits" ] && note "Possible hardcoded credential in the staged diff. Check these, and remember that a committed secret must be rotated, not merely deleted:
$(printf '%s' "$hits" | sed 's/^/    /' | cut -c1-120)"

        # Private key blocks are unambiguous.
        printf '%s' "$staged" | grep -q 'BEGIN [A-Z ]*PRIVATE KEY' &&
            note "A private key block appears in the staged diff."
    fi

    # ---------------------------------------------------------------------
    # Staged JSON must parse. A malformed manifest committed is a broken build
    # for everyone who pulls it.
    # ---------------------------------------------------------------------
    if command -v jq >/dev/null 2>&1; then
        for f in $(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep '\.json$' || true); do
            [ -r "$f" ] || continue
            jq empty "$f" >/dev/null 2>&1 || note "\`$f\` is staged but is not valid JSON."
        done
    fi
fi

# ---------------------------------------------------------------------------
# Report. Silence when there is nothing to say.
# ---------------------------------------------------------------------------

if [ -n "$findings" ]; then
    echo "S.A.R.A.H. commit check — advisory, not blocking:"
    printf '%s' "$findings"
    echo "Fix what is real and ignore what is not. This check does not stop the commit."
fi

exit 0
