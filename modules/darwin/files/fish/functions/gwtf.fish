function gwtf --description 'Fuzzy find and navigate repository worktrees'
    argparse 'C/directory=' -- $argv; or return
    set -l repo "$PWD"
    set -q _flag_directory; and set repo "$_flag_directory"
    set -l rows (git -C "$repo" wt list --json | jq -r '
        .[] | select(.bare | not) |
        [((.branch // "detached") + (if .current then " *" else "" end)), .path] | @tsv')
    test -n "$rows"; or return

    set -l header 'Enter: cd | Esc: exit'
    set -l fzf_args
    if test "$TERM_PROGRAM" = rex; and command -q rex
        set header "$header
ctrl-v/s: split right/below | ctrl-t: project tab"
        set fzf_args \
            --bind 'ctrl-v:execute(_git_dir_action right {2})+abort' \
            --bind 'ctrl-s:execute(_git_dir_action below {2})+abort' \
            --bind 'ctrl-t:execute(_git_dir_action tab {2})+abort'
    end

    set -l selection (printf '%s\n' $rows | fzf $fzf_args \
        --ansi --no-multi --delimiter '\t' \
        --prompt 'Worktrees> ' --query "$argv" --header "$header" \
        --with-shell 'fish -c' \
        --preview 'git -C {2} -c color.status=always status --short --branch; echo; git -C {2} --no-pager log -8 --color=always --oneline')
    test -n "$selection"; or return
    cd -- (string split -f 2 \t -- "$selection")
end
