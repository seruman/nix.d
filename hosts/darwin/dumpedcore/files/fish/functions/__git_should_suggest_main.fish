function __git_should_suggest_main --argument-names subcmds
    set -l cmds (string split , $subcmds)
    set -l args $argv[2..-1]

    contains -- "$args[1]" $cmds
    or return 1

    contains -- master $args[2..-1]
    or return 1

    command git rev-parse --git-dir >/dev/null 2>&1
    or return 1

    not command git show-ref --quiet refs/heads/master
    or return 1

    command git show-ref --quiet refs/heads/main
    or return 1

    contains --index -- master $args
end
