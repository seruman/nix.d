function ghqf --wraps ghq --description 'Fuzzy find and navigate ghq repositories'
    set -l header 'Enter: cd'

    set -l fzf_args \
        --ansi \
        --prompt 'Repositories> ' \
        --preview '_ghqf_preview {}' \
        --query "$argv"

    if test "$TERM_PROGRAM" = rex; and command -q rex
        set header 'Enter: cd | ctrl-t: new project tab'
        set fzf_args $fzf_args \
            --bind 'ctrl-t:execute(_ghqf_action {})+abort'
    end

    set -l selection (ghq list | fzf $fzf_args --header "$header")
    if test -z "$selection"
        return
    end

    set -l repopath (ghq list --full-path -e "$selection")
    if test -n "$repopath"
        cd "$repopath"
    end
end
