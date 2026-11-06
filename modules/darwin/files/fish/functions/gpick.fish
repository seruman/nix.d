function gpick --argument-names start --description 'Pick a repository, worktree or memo with mmenu and open it in Rex'
    if test "$start" = --rows
        __gpick_rows $argv[2]
        return
    end
    if not contains -- "$start" repos worktrees memos
        printf 'usage: gpick repos|worktrees|memos\n' >&2
        return 2
    end

    set -l repo
    if test $start != repos
        set repo (rex do com.superlogical.terminal.pwd --json | jq -r .pwd | string replace -r '^file://[^/]*' '' | string unescape --style=url)
        test -d "$repo"; or return 1
    end

    set -l config (mktemp -t gpick)
    or return
    jq -n --arg start $start --arg fish (status fish-path) '
        def level($id; $label):
            {id: $id, label: $label, format: "jsonl", command: [$fish, "-c", "gpick --rows \($id)"], hidden: ($id != $start)}
            + if $id == $start then {prompt: $label} else {} end;
        {
            theme: "rex",
            sources: [level("repos"; "Repositories"), level("worktrees"; "Worktrees"), level("memos"; "Memos")],
            bindings: [
                {key: "ctrl+w", id: "worktrees", label: "Worktrees", action: "push", source: "worktrees", sources: ["repos"]},
                {key: "alt+n", id: "memos", label: "Memos", action: "push", source: "memos", sources: ["repos"]},
                {key: "ctrl+v", id: "right", label: "Split right", action: "accept"},
                {key: "ctrl+s", id: "below", label: "Split below", action: "accept"}
            ]
        }' >$config
    set -l result (GPICK_REPO=$repo ~/Applications/mmenu.app/Contents/MacOS/mmenu --config $config --json --width 720)
    set -l code $status
    rm -f $config
    test $code -eq 0; or return $code

    set -l action (printf '%s\n' $result | jq -r .action)
    set -l directory (printf '%s\n' $result | jq -j '.items[0].value, "\u0000"' | string split0)
    switch $action
        case accept
            set -l label_repo $directory
            if test (printf '%s\n' $result | jq -r .source) = memos
                set label_repo (printf '%s\n' $result | jq -j '.path[0] | select(.source == "repos") | .items[0].value, "\u0000"' | string split0)
                test -n "$label_repo"; or set label_repo $repo
            end
            _git_dir_action tab $directory $label_repo
        case right below
            _git_dir_action $action $directory
    end
end

function __gpick_rows --argument-names level
    set -l repo $MMENU_VALUE
    test -n "$repo"; or set repo $GPICK_REPO
    switch $level
        case repos
            set -l roots (ghq root --all); or return
            ghq list -p | jq -Rc --args '
                select(length > 0) | . as $path |
                ([$ARGS.positional[] | select(. as $root | $path | startswith($root + "/"))] | max_by(length)) as $root |
                (if $root then $path[($root | length) + 1:] else $path end) as $name |
                {id: $name, title: $name, value: $path}' $roots
        case worktrees
            git -C $repo wt list --json | jq -c '
                .[] | select(.bare | not) |
                {id: .path, title: (.branch // "detached"), subtitle: .path,
                 detail: (if .current then "Current" else "" end), value: .path}'
        case memos
            set -l scope (git -C $repo memo path); or return
            git -C $repo memo list | jq -Rc --arg scope $scope '
                select(length > 0) | split("\t") |
                if .[0] | test("^\\\\.{0,2}$|/") then error("not a memo directory: \(.[0])") end |
                {id: .[0], title: .[0], subtitle: (.[1:] | join("\t")), value: ($scope + "/" + .[0])}'
    end
end
