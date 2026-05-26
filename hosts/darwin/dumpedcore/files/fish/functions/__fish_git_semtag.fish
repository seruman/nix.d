function __fish_git_semtag
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        return 1
    end

    set -l tags (git semtag -r -ii -fc)
    if not test -n "$tags"
        return
    end

    set -l selection (string split \n -- $tags | \
        fzf --ansi \
            --prompt="semtag> " \
            --preview="git show --color {1}" \
            --header="Enter: select | ctrl-p: patch | ctrl-n: minor | ctrl-j: major | ctrl-r: prerelease" \
            --bind "ctrl-p:become(echo {} | semver-parse bump patch)" \
            --bind "ctrl-n:become(echo {} | semver-parse bump minor)" \
            --bind "ctrl-j:become(echo {} | semver-parse bump major)" \
            --bind "ctrl-r:become(echo {} | semver-parse bump prerelease)")

    commandline -f repaint
    if test -n "$selection"
        commandline -i -- $selection
    end
end
