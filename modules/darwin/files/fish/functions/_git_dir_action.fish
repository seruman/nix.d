function _git_dir_action --description 'Open a directory in a Rex split or project tab' --argument-names target directory repo
    test -d "$directory"; or return 1
    switch "$target"
        case tab
            test -n "$repo"; or set repo "$directory"
            set -l name (__git_repo_name "$repo"); or return
            set -l session (rex ls --json | jq -r --arg name $name 'first(.sessions[] | select(.label == $name) | .session_id) // empty')
            set -l window
            if test -n "$session"
                set window (rex window new -s $session -c "$directory" --json | jq -r .window_id); or return
            else
                set -l created (rex new $name -c "$directory" --json); or return
                set session (printf '%s\n' $created | jq -r .session_id)
                set window (printf '%s\n' $created | jq -r '.initial_windows[0].window_id')
            end
            rex do session.select session_id=$session window_id=$window >/dev/null
        case right below
            rex split --split="$target" -c "$directory" >/dev/null
    end
end
