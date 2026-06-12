function __fish_ht_attach
    command -sq ht; or return

    if test -n "$(commandline)"
        return
    end

    set -l output (ht list 2>/dev/null)
    if test (count $output) -lt 2
        commandline -f repaint
        return
    end

    set -l selection (string split \n -- $output | \
        fzf --ansi \
            --prompt="ht> " \
            --preview="ht dump {1} --format vt" \
            --preview-window="right:60%:follow" \
            --header-lines=1 \
            --nth=1)

    commandline -f repaint
    if test -n "$selection"
        set -l name (string split -f1 " " -- $selection | string trim)
        commandline -i -- "ht attach $name"
    end
end
