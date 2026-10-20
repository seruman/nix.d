function gmemof --description 'Fuzzy find and navigate repository memos'
    argparse 'C/directory=' -- $argv; or return
    set -l repo "$PWD"
    set -q _flag_directory; and set repo "$_flag_directory"
    set -l scope (git -C "$repo" memo path); or return
    set -l rows (git -C "$repo" memo list); or return
    test -n "$rows"; or return

    set -l entry (string escape -- "$scope")'/{1}'
    set -l source_repo (string escape -- "$repo")
    set -l header 'Enter: cd | Esc: exit'
    set -l fzf_args
    if test "$TERM_PROGRAM" = rex; and command -q rex
        set header "$header
ctrl-v/s: split right/below | ctrl-t: project tab"
        set fzf_args \
            --bind "ctrl-v:execute(_git_dir_action right $entry $source_repo)+abort" \
            --bind "ctrl-s:execute(_git_dir_action below $entry $source_repo)+abort" \
            --bind "ctrl-t:execute(_git_dir_action tab $entry $source_repo)+abort"
    end

    set -l selection (printf '%s\n' $rows | fzf $fzf_args \
        --ansi --no-multi --delimiter '\t' --prompt 'Memos> ' --query "$argv" \
        --header "$header" --with-shell 'fish -c' \
        --preview "if test -f $entry/index.md; glow -s light $entry/index.md; else; ls -A $entry; end")
    test -n "$selection"; or return
    cd -- "$scope/"(string split -f 1 \t -- "$selection")
end
