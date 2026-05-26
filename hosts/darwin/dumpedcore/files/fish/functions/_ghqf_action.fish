function _ghqf_action --description 'Open a ghq repository in a new Ghostty split or tab'
    set -l target $argv[1]
    set -l repo $argv[2]

    if test -z "$target"
        return 1
    end

    if test -z "$repo"
        return 1
    end

    if test "$TERM_PROGRAM" != ghostty
        return 1
    end

    if not command -q boo
        return 1
    end

    set -l repo_path (ghq list --full-path -e "$repo")
    if test -z "$repo_path"
        return 1
    end

    switch "$target"
        case tab
            boo tab new --working-dir "$repo_path" >/dev/null 2>&1
        case '*'
            boo terminal split --direction "$target" --working-dir "$repo_path" >/dev/null 2>&1
    end
end
