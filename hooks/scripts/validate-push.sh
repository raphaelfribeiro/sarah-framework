#!/bin/sh
# S.A.R.A.H. — PreToolUse(Bash), push inspection.
#
# Warns before a push to a protected branch, and before a force push anywhere.
#
# Contract: sensor only. NEVER blocks, always exits 0. The user's own branch
# protection, if they have any, is the real control; this is a reminder at the
# moment it is useful.
#
# One thing worth knowing about this hook: a push is often a publish. On a
# repository with any mirroring or public visibility, pushed is public. That is
# worth one line of warning and no more.
#
# POSIX sh only.

set -u
trap 'exit 0' EXIT

payload=$(cat 2>/dev/null || true)
[ -n "$payload" ] || exit 0

if command -v jq >/dev/null 2>&1; then
    command_line=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
    command_line=$(printf '%s' "$payload" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
fi

[ -n "${command_line:-}" ] || exit 0

# Fast path.
case "$command_line" in
    *"git push"*) ;;
    *) exit 0 ;;
esac

findings=""
note() { findings="${findings}- $1
"; }

# ---------------------------------------------------------------------------
# Force push. Rewriting published history breaks every clone downstream.
# ---------------------------------------------------------------------------

case "$command_line" in
    *--force-with-lease*)
        note "Force push with lease. Safer than a bare force, but it still rewrites history that others may have pulled."
        ;;
    *--force*|*" -f "*|*" -f")
        note "Bare force push. This rewrites published history and breaks every clone that has it. \`--force-with-lease\` at least refuses when someone else has pushed since you last fetched."
        ;;
esac

# ---------------------------------------------------------------------------
# Protected branch.
# ---------------------------------------------------------------------------

if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    # The branch named on the command line, if any; otherwise the current one.
    #
    # Parse by dropping flags rather than by position: `git push --force origin
    # main` and `git push origin main` must both resolve to `main`. Reading the
    # positional argument naively makes the flag case report the remote as the
    # branch, which silently loses the warning in exactly the most dangerous
    # case - a force push to a protected branch.
    args=${command_line#*git push}
    target=""
    remote_seen=0
    # Intentional word splitting over the argument list.
    # shellcheck disable=SC2086
    set -- $args
    for tok in "$@"; do
        case "$tok" in
            -*) continue ;;                 # flag
            *=*) continue ;;                # --opt=value remnant
            \&\&*|\|\|*|\;*) break ;;       # end of this command
        esac
        if [ "$remote_seen" -eq 0 ]; then
            remote_seen=1                   # first bare word is the remote
        else
            target=$tok                     # second is the refspec
            break
        fi
    done

    [ -n "${target:-}" ] || target=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)

    # Strip a refspec such as HEAD:main down to its destination.
    case "$target" in *:*) target=${target#*:} ;; esac
    target=${target#refs/heads/}

    case "$target" in
        main|master|develop|release|production|prod)
            note "Pushing to \`$target\`, a protected-by-convention branch. If this project reviews through pull requests, this bypasses that."
            ;;
    esac

    # Unpushed work is not necessarily what is about to be pushed, but a large
    # count is worth surfacing before it lands in one go.
    upstream=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)
    if [ -n "$upstream" ]; then
        ahead=$(git rev-list --count "$upstream"..HEAD 2>/dev/null || echo 0)
        [ "${ahead:-0}" -gt 20 ] 2>/dev/null &&
            note "$ahead commits ahead of \`$upstream\`. Worth confirming that is intended."
    fi
fi

if [ -n "$findings" ]; then
    echo "S.A.R.A.H. push check — advisory, not blocking:"
    printf '%s' "$findings"
    echo "- A push is a publish wherever this repository is visible or mirrored. Confirm the user asked for this."
fi

exit 0
