function _git_dir_action --description 'Open a directory in a Rex split or project tab' --argument-names target directory repo
    test -d "$directory"; or return 1
    switch "$target"
        case tab
            test -n "$repo"; or set repo "$directory"
            set -l name (__git_repo_name "$repo"); or return
            rex do project_tab "cwd=$directory" "label=$name" >/dev/null
        case right below
            rex split --split="$target" -c "$directory" >/dev/null
    end
end
