# The branch model, in one place so the guard and the CI check cannot disagree.
# Sourced; defines one function. POSIX sh, no shebang (the installer prepends a stamp).
#
#   main      released code, reached only from release/* and hotfix/*
#   develop   integration, reached from feature/*, and from release/* and hotfix/*
#   feature/* merges into develop only

# sarah_gitflow_violation BASE HEAD : prints why the pull request breaks the
# model and returns 0, or prints nothing and returns 1.
sarah_gitflow_violation() {
    case $2 in
        feature/*)
            [ "$1" = develop ] && return 1
            printf 'a feature/* branch merges into develop only, not into %s\n' "$1"
            return 0
            ;;
        release/* | hotfix/*)
            case $1 in
                main | develop) return 1 ;;
            esac
            printf 'a %s branch merges into main and develop only, not into %s\n' "${2%%/*}" "$1"
            return 0
            ;;
        *)
            [ "$1" = main ] || return 1
            printf 'only release/* and hotfix/* branches merge into main, and this one is %s\n' "$2"
            return 0
            ;;
    esac
}
