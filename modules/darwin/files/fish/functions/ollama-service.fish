function ollama-service --description 'Control the Home Manager Ollama service'
    if test (count $argv) -ne 1
        echo 'Usage: ollama-service start|stop|restart|status|logs' >&2
        return 2
    end

    switch $argv[1]
        case -h --help help
            echo 'Usage: ollama-service start|stop|restart|status|logs'
            echo 'stop unloads the service for this session; login or Nix activation may load it again.'
            echo 'logs follows the last 100 log lines; press Ctrl-C to exit.'
            return 0
        case start stop restart status logs
        case '*'
            echo "ollama-service: unknown command: $argv[1]" >&2
            return 2
    end

    set -l domain gui/(id -u)
    set -l target $domain/org.nix-community.home.ollama
    set -l plist "$HOME/Library/LaunchAgents/org.nix-community.home.ollama.plist"

    switch $argv[1]
        case start restart
            if command launchctl print $target >/dev/null 2>&1
                if test $argv[1] = restart
                    command launchctl kickstart -k $target
                else
                    command launchctl kickstart $target
                end
            else
                # RunAtLoad starts the server when it is registered.
                command launchctl bootstrap $domain "$plist"
            end
        case stop
            if command launchctl print $target >/dev/null 2>&1
                # A signal alone would trigger KeepAlive and restart the server.
                command launchctl bootout $target
            else
                echo 'Ollama service is already unloaded.'
                return 0
            end
        case status
            command launchctl print $target
        case logs
            set -l logfile (command plutil -extract StandardOutPath raw -o - "$plist")
            or return $status
            command tail -n 100 -F "$logfile"
    end
end
