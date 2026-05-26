# disable file completion
complete -c dockerf -f

complete -c dockerf -n "not __fish_seen_subcommand_from stop kill rm ls rmi" -a stop -d "Stop containers"
complete -c dockerf -n "not __fish_seen_subcommand_from stop kill rm ls rmi" -a kill -d "Kill containers"
complete -c dockerf -n "not __fish_seen_subcommand_from stop kill rm ls rmi" -a rm -d "Remove containers"
complete -c dockerf -n "not __fish_seen_subcommand_from stop kill rm ls rmi" -a ls -d "List containers"
complete -c dockerf -n "not __fish_seen_subcommand_from stop kill rm ls rmi" -a rmi -d "Remove images"
