function _gotaf_cmd
    if not command -sq listests
        echo "gotaf: listests is not installed" >&2
        return 1
    end

    argparse 'tags=' -- $argv
    or return

    set -l pkgs $argv
    if test -z "$pkgs"
        set pkgs ./...
    end

    set -l tags_opt
    if set -q _flag_tags
        set tags_opt "-tags=$_flag_tags"
    end

    set -l format "{{.FullDisplayName}}:{{.RelativeFileName}}:{{.Range.Start.Line}}:{{.Range.End.Line}}"
    set -l lines ( listests --format="$format" $tags_opt $pkgs | fzf --delimiter : \
        --multi \
        --preview 'echo $FZF_COLUMNS; bat --style=full --color=always --terminal-width $FZF_COLUMNS --highlight-line {3}:{4} {2}' \
        --preview-window '70%,~4,+{4}+4/4' \
        --height 60%
    )
    if test -z "$lines"
        return 0
    end

    set -l tests
    set -l packages
    for line in $lines
        set -l testname ( echo $line | cut -d : -f 1 )
        set -l filename ( echo $line | cut -d : -f 2 )
        set -l dir "./$(path dirname $filename)"

        set tests $tests $testname
        set packages $packages "$dir"
    end

    set packages ( printf '%s\n' $packages | sort -u )

    set -l gotest_tags
    if set -q _flag_tags
        set gotest_tags "-tags=\"$_flag_tags\""
    end

    set -l cmd "gotest -v $gotest_tags $(string join ' ' $packages) -count=1 -run=\"$(string join '|' $tests)\""
    echo $cmd
end

function gotaf
    set -l cmd ( _gotaf_cmd $argv )
    if test -n "$cmd"
        echo $cmd
        history append -- $cmd
        eval $cmd
    end
end
