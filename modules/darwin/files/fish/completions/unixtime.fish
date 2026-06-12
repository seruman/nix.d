complete -c unixtime -f  # -f prevents file completion

# subcommands
complete -c unixtime -n "__fish_use_subcommand" -a "now" -d "Current time in epoch seconds"
complete -c unixtime -n "__fish_use_subcommand" -a "decode" -d "Decode epoch seconds to human readable time"
complete -c unixtime -n "__fish_use_subcommand" -a "encode" -d "Encode human readable time to epoch seconds"

# help flag
complete -c unixtime -s h -l help -d "Show help message"
