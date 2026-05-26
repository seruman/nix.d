function ghqf --wraps ghq --description 'Fuzzy find and navigate ghq repositories'
    set -l header 'Enter: cd'

    set -l fzf_args \
        --ansi \
        --prompt 'Repositories> ' \
        --preview '_ghqf_preview {}' \
        --query "$argv"

    if test "$TERM_PROGRAM" = ghostty; and command -q boo
        set header 'Enter: cd | ctrl-v: vertical split | ctrl-s: horizontal split | ctrl-t: new tab'
        set fzf_args $fzf_args \
            --bind 'ctrl-v:execute-silent(_ghqf_action right {})+abort' \
            --bind 'ctrl-s:execute-silent(_ghqf_action down {})+abort' \
            --bind 'ctrl-t:execute-silent(_ghqf_action tab {})+abort'
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
