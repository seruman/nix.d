function ghqf --wraps ghq --description 'Fuzzy find and navigate ghq repositories'
    set -l header 'Enter: cd | ctrl-w/n: worktrees/memos'
    set -l fzf_args \
        --bind 'ctrl-w:print(worktrees)+accept' \
        --bind 'ctrl-n:print(memos)+accept'

    if test "$TERM_PROGRAM" = rex; and command -q rex
        set header "$header
ctrl-v/s: split right/below | ctrl-t: project tab"
        set -a fzf_args \
            --bind 'ctrl-v:execute(_git_dir_action right (ghq list --full-path -e {}))+abort' \
            --bind 'ctrl-s:execute(_git_dir_action below (ghq list --full-path -e {}))+abort' \
            --bind 'ctrl-t:execute(_git_dir_action tab (ghq list --full-path -e {}))+abort'
    end

    set -l selection (ghq list | fzf $fzf_args \
        --ansi --no-multi --prompt 'Repositories> ' --query "$argv" \
        --header "$header" --with-shell 'fish -c' --preview '_ghqf_preview {}')
    test -n "$selection"; or return

    set -l repo (ghq list --full-path -e "$selection[-1]")
    test -n "$repo"; or return
    if test (count $selection) -eq 2
        switch "$selection[1]"
            case worktrees
                gwtf -C "$repo"
            case memos
                gmemof -C "$repo"
        end
    else
        cd "$repo"
    end
end
