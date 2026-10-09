complete -c ollama-service -f
complete -c ollama-service -n 'not __fish_seen_subcommand_from start stop restart status logs help' -a start -d 'Start Ollama'
complete -c ollama-service -n 'not __fish_seen_subcommand_from start stop restart status logs help' -a stop -d 'Stop and unload Ollama for this session'
complete -c ollama-service -n 'not __fish_seen_subcommand_from start stop restart status logs help' -a restart -d 'Restart Ollama, or start if unloaded'
complete -c ollama-service -n 'not __fish_seen_subcommand_from start stop restart status logs help' -a status -d 'Show launchd service status'
complete -c ollama-service -n 'not __fish_seen_subcommand_from start stop restart status logs help' -a logs -d 'Follow the server log'
complete -c ollama-service -s h -l help -d 'Show usage'
