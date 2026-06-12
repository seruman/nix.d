# @fish-lsp-disable 2001
function dockerf -a command -a query
    if test -z "$command"
        echo "Usage: docker fzf [stop|kill|rm|ls|rmi] [query]"
        return 1
    end

    switch $command
        case stop
            __dockerf_stop $query
        case kill
            __dockerf_kill $query
        case rm
            __dockerf_rm $query
        case ls
            __dockerf_ls $query
        case rmi
            __dockerf_rmi $query
        case '*'
            echo "Unknown command: $command"
            return 1
    end
end

function __dockerf_stop -a query
    __dockerf_cmd "Stop Container(s)" "docker ps" "docker stop" 1 $query
end

function __dockerf_kill -a query
    __dockerf_cmd "Kill Container(s)" "docker ps" "docker kill" 1 $query
end

function __dockerf_rm -a query
    __dockerf_cmd "Remove Container(s)" "docker ps -a" "docker rm" 1 $query
end

function __dockerf_ls -a query
    __dockerf_cmd "List Container ID(s)" "docker ps -a" echo 1 $query
end

function __dockerf_rmi -a query
    __dockerf_cmd "Remove Image(s)" "docker images" "docker rmi" 3 $query
end


function __dockerf_cmd -a prompt -a input_cmd -a action_cmd -a field -a query
    if not set -q input_cmd
        echo "command is required" >&2
        return 1
    end

    test -z "$field"; and set field 1

    if not set -q action_cmd
        echo "action is required" >&2
        return 1
    end

    if not set -l selected (eval $input_cmd | fzf --ansi --multi --header-lines=1 --prompt="$prompt >" --query="$query")
        return 0
    end

    set -l items
    for line in $selected
        set -a items (echo $line | awk -v field=$field '{print $field}')
    end

    if test -n "$items"
        echo $action_cmd $items >&2
        eval "$action_cmd $items"
    end
end
