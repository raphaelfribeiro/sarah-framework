# CI side of the gitflow agreement (R13): does this pull request follow the
# branch model? Run by .github/workflows/sarah-gitflow.yml as
#   sh sarah/hooks/gitflow/check-branch-model.sh "$BASE_REF" "$HEAD_REF"
# The refs are data: they are only ever compared, never run.
#
# Exit 2 fails the job. A missing ref means the check cannot evaluate: it says
# so and allows. Exceptions (R16) are not honored here: this file is part of
# the pull request being checked, so a row added by the PR itself would excuse
# the PR. Fix the base, or remove the habit, to get past this check.
here=$(cd "$(dirname "$0")" && pwd)
. "$here/model.sh"

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    printf 'Rule not checked: gitflow (the pull request refs are missing). I let it through.\n'
    exit 0
fi
if why=$(sarah_gitflow_violation "$1" "$2"); then
    printf 'Blocked: this pull request breaks the branch model: %s. Rule: gitflow. Retarget the pull request, see docs/branching.md.\n' "$why"
    exit 2
fi
printf 'gitflow: %s into %s follows the branch model.\n' "$2" "$1"
exit 0
