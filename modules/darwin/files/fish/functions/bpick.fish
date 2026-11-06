function bpick --argument-names start --description 'Pick a floating or detached Rex block with mmenu'
    switch "$start"
        case --rows
            __bpick_rows $argv[2]
            return
        case --toggle
            __bpick_toggle
            return
        case floating detached
        case '*'
            printf 'usage: bpick floating|detached\n' >&2
            return 2
    end

    set -l config (mktemp -t bpick)
    or return
    jq -n --arg start $start --arg fish (status fish-path) '
        def level($id; $label; $key):
            {id: $id, label: $label, key: $key, prompt: $label, format: "jsonl",
             command: [$fish, "-c", "bpick --rows \($id)"],
             preview: [$fish, "-c", "rex capture -b $MMENU_VALUE --trim | tail -n 80"]};
        {
            theme: "rex",
            initialSource: $start,
            sources: [level("floating"; "Floating"; "cmd+1"), level("detached"; "Detached"; "cmd+2")],
            bindings: [
                {key: "cmd+m", id: "toggle", label: "Minimize", action: "run", reload: true,
                 command: [$fish, "-c", "bpick --toggle"], sources: ["floating"]},
                {key: "ctrl+v", id: "right", label: "Split right", action: "accept", sources: ["detached"]},
                {key: "ctrl+s", id: "below", label: "Split below", action: "accept", sources: ["detached"]},
                {key: "ctrl+t", id: "tab", label: "New tab", action: "accept", sources: ["detached"]},
                {key: "cmd+p", label: "Preview", action: "togglePreview"}
            ]
        }' >$config
    set -l result (~/Applications/mmenu.app/Contents/MacOS/mmenu --config $config --json --width 560)
    set -l code $status
    rm -f $config
    test $code -eq 0; or return $code

    set -l action (printf '%s\n' $result | jq -r .action)
    set -l source (printf '%s\n' $result | jq -r .source)
    set -l id (printf '%s\n' $result | jq -r '.items[0].id')
    set -l block (printf '%s\n' $result | jq -r '.items[0].value')
    if test $source = floating
        __bpick_layer_state $id normal true
        return
    end
    switch $action
        case accept right
            __bpick_place $block horizontal $REX_BLOCK
        case below
            __bpick_place $block vertical $REX_BLOCK
        case tab
            set -l window (rex window new --focus=false --shell=none --json -- /bin/sleep 86400)
            or return
            set -l placeholder (printf '%s\n' $window | jq -r '.block_ids[0]')
            __bpick_place $block horizontal $placeholder
            rex block close $placeholder >/dev/null
            rex do session.select session_id=$REX_SESSION window_id=(printf '%s\n' $window | jq -r .window_id) >/dev/null
    end
end

function __bpick_layer_state --argument-names layer state focus
    rex api call session.set_layer_state (jq -nc --arg s $REX_SESSION --arg l $layer --arg state $state --argjson focus $focus \
        '{session_id: $s, layer_id: $l, state: $state, focus: $focus}') >/dev/null
end

function __bpick_place --argument-names block direction anchor
    rex api call session.move_block (jq -nc --arg s $REX_SESSION --arg b $block --arg a $anchor --arg d $direction \
        '{session_id: $s, block_id: $b, anchor_block_id: $a, direction: $d, side: "after"}') >/dev/null
    and rex api call session.focus_block (jq -nc --arg s $REX_SESSION --arg b $block '{session_id: $s, block_id: $b}') >/dev/null
end

function __bpick_toggle
    set -l state (rex session inspect $REX_SESSION --json | jq -r --arg layer $MMENU_ID '
        first(.windows[].layers[] | select(.layer_id == $layer)) | if .state == "minimized" then "normal" else "minimized" end')
    __bpick_layer_state $MMENU_ID $state false
end

function __bpick_rows --argument-names level
    switch $level
        case floating
            rex session inspect $REX_SESSION --json | jq -c --arg block "$REX_BLOCK" '
                .active_window_id as $active |
                (first(.windows[] | select(any(.layers[].blocks[]; .block_id == $block))) // first(.windows[] | select(.window_id == $active))) |
                .focused_block_id as $focused |
                .layers[] | select(.kind == "floating") |
                {id: .layer_id, value: .blocks[0].block_id, title: (.blocks | map(.label) | join(", ")),
                 detail: (if .state == "minimized" then "Minimized" elif any(.blocks[]; .block_id == $focused) then "Focused" else "" end)}'
        case detached
            rex block ls --json | jq -c '
                .blocks[] | select(.placement == "detached") |
                {id: .block_id, value: .block_id, title: .label, detail: .block_id[-6:]}'
    end | while read -l row
        set -l block (printf '%s\n' $row | jq -r .value)
        set -l title (rex block call title -b $block 2>/dev/null | jq -r '.title // empty')
        printf '%s\n' $row | jq -c --arg title "$title" '. + {title: (if $title == "" then .title else $title end), subtitle: .title}'
    end
end
