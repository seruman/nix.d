# cashfish - A Fish shell command cache utility inspired by bkt;
#  - https://github.com/dimo414/bkt
# Caches command outputs with TTL-based expiration
# Lacks a bunch of stuff bkt has; --stale , file locking for concurrent runs, etc.

function _cashfish_help
    echo "cashfish - Cache command outputs with TTL-based expiration"
    echo ""
    echo "Usage: cashfish [OPTIONS] -- COMMAND"
    echo ""
    echo "Options:"
    echo "  --ttl=DURATION       Cache lifetime (required)"
    echo "                       Examples: 1m, 30s, 1h, 1h30m, 1d"
    echo "  --scope=NAME         Namespace cache entries"
    echo "  --force              Force re-execution, ignore cache"
    echo "  --no-auto-cleanup    Skip automatic cache cleanup for this invocation"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  cashfish --ttl=1m -- date"
    echo "  cashfish --ttl=5m -- curl https://api.example.com"
    echo "  cashfish --ttl=1h --scope=project1 -- git status"
    echo "  cashfish --ttl=30s --force -- expensive_command"
    echo ""
    echo "Auto-cleanup: Runs every 24 hours (configurable via CASHFISH_AUTO_CLEANUP_INTERVAL)"
    echo "Cache location: \$XDG_CACHE_HOME/cashfish or ~/.cache/cashfish"
end

function cashfish -d "Cache command outputs with TTL"
    set -l options h/help
    set -a options ttl=
    set -a options scope=
    set -a options force
    set -a options no-auto-cleanup

    argparse $options -- $argv 2>/dev/null
    or begin
        _cashfish_help >&2
        return 1
    end

    if set -q _flag_help
        _cashfish_help
        return 0
    end

    if not set -q _flag_ttl
        echo "cashfish: --ttl is required" >&2
        echo "Run 'cashfish --help' for usage information" >&2
        return 1
    end

    if test (count $argv) -eq 0
        echo "cashfish: command is required" >&2
        echo "Run 'cashfish --help' for usage information" >&2
        return 1
    end

    set -l ttl $_flag_ttl
    set -l scope $_flag_scope
    set -l command_args $argv

    set -l ttl_seconds (_cashfish_parse_duration $ttl)
    or return 1

    set -l cache_key (_cashfish_cache_key $scope $command_args)
    or return 1
    set -l cache_dir (_cashfish_cache_dir)
    or return 1
    set -l cache_path "$cache_dir/$cache_key"

    if not set -q _flag_no_auto_cleanup
        if _cashfish_should_auto_cleanup "$cache_dir"
            _cashfish_auto_cleanup "$cache_dir"
        end
    end

    if set -q _flag_force
        _cashfish_execute_and_cache $cache_path "$ttl" "$ttl_seconds" "$scope" -- $command_args
        return $status
    end

    set -l cache_status (_cashfish_lookup $cache_path $ttl_seconds)

    switch $cache_status
        case hit
            _cashfish_replay_cache $cache_path
            return $status

        case miss expired
            _cashfish_execute_and_cache $cache_path "$ttl" "$ttl_seconds" "$scope" -- $command_args
            return $status
    end
end

# Parse duration string a.la Go time.Duration
function _cashfish_parse_duration -a duration
    set -l total_seconds 0

    set -l remaining $duration

    while test -n "$remaining"
        # Try to match a number followed by a unit
        if string match -qr '^([0-9]+)([a-z]+)(.*)$' -- $remaining
            set -l matches (string match -r '^([0-9]+)([a-z]+)(.*)$' -- $remaining)
            set -l number $matches[2]
            set -l unit $matches[3]
            set remaining $matches[4]

            switch $unit
                case s sec secs second seconds
                    set total_seconds (math $total_seconds + $number)
                case m min mins minute minutes
                    set total_seconds (math $total_seconds + $number \* 60)
                case h hr hrs hour hours
                    set total_seconds (math $total_seconds + $number \* 3600)
                case d day days
                    set total_seconds (math $total_seconds + $number \* 86400)
                case '*'
                    echo "cashfish: unknown duration unit: $unit" >&2
                    return 1
            end
        else
            if string match -qr '^[0-9]+$' -- $remaining
                set total_seconds (math $total_seconds + $remaining)
                set remaining ""
            else
                echo "cashfish: invalid duration format: $duration" >&2
                return 1
            end
        end
    end

    if test $total_seconds -eq 0
        echo "cashfish: duration cannot be zero" >&2
        return 1
    end

    echo $total_seconds
end

# Generate cache key from scope and command
function _cashfish_cache_key
    set -l scope $argv[1]
    set -l command_parts $argv[2..-1]

    # Build cache key input
    set -l key_input
    if test -n "$scope"
        set -a key_input "scope:$scope"
    end
    set -a key_input $command_parts

    if not type -q md5sum; and not type -q md5
        echo "cashfish: neither md5sum nor md5 command is available" >&2
        return 1
    end

    set -l hash (string join \n -- $key_input | md5sum | string split -f1 ' ')
    or set hash (string join \n -- $key_input | md5 | string trim)

    # Paranoia
    if test -z "$hash"
        echo "cashfish: failed to generate cache key" >&2
        return 1
    end

    echo $hash
end

# Get cache directory
function _cashfish_cache_dir
    set -l cache_base
    if set -q XDG_CACHE_HOME
        set cache_base "$XDG_CACHE_HOME"
    else if set -q HOME
        set cache_base "$HOME/.cache"
    else
        echo "cashfish: HOME environment variable not set" >&2
        return 1
    end

    set -l cache_dir "$cache_base/cashfish"
    mkdir -p "$cache_dir" 2>/dev/null
    echo "$cache_dir"
end

# Check cache validity; hit | miss | expired
function _cashfish_lookup -a cache_path ttl_seconds
    # Check if cache exists
    if not test -d "$cache_path"
        echo miss
        return
    end

    if not test -f "$cache_path/stdout"
        echo miss
        return
    end
    if not test -f "$cache_path/stderr"
        echo miss
        return
    end
    if not test -f "$cache_path/exit_code"
        echo miss
        return
    end
    if not test -f "$cache_path/timestamp"
        echo miss
        return
    end

    set -l timestamp (cat "$cache_path/timestamp" 2>/dev/null)
    or begin
        echo miss
        return
    end

    set -l now (date +%s)
    set -l age (math $now - $timestamp)

    if test $age -gt $ttl_seconds
        echo expired
        return
    end

    echo hit
end

# Replay cached output
function _cashfish_replay_cache -a cache_path
    # Output stdout and stderr
    test -f "$cache_path/stdout"; and cat "$cache_path/stdout"
    test -f "$cache_path/stderr"; and cat "$cache_path/stderr" >&2

    # Return cached exit code
    set -l exit_code (cat "$cache_path/exit_code" 2>/dev/null)
    if test -n "$exit_code"
        return $exit_code
    else
        return 0
    end
end

# Execute command and cache results if successful
function _cashfish_execute_and_cache -a cache_path ttl_raw ttl_seconds scope
    set -l command_parts $argv[5..-1]
    if test (count $command_parts) -gt 0; and string match -q -- "--" $command_parts[1]
        set command_parts $command_parts[2..-1]
    end

    if test (count $command_parts) -eq 0
        echo "cashfish: command is required" >&2
        return 1
    end

    # Create temporary files for output capture
    set -l temp_dir (mktemp -d)
    or begin
        echo "cashfish: failed to create temporary directory" >&2
        return 1
    end
    set -l stdout_file "$temp_dir/stdout"
    set -l stderr_file "$temp_dir/stderr"

    begin
        begin
            $command_parts
        end 2>"$stderr_file"
    end >"$stdout_file"
    set -l exit_code $status

    cat "$stdout_file"
    cat "$stderr_file" >&2

    if test $exit_code -eq 0
        mkdir -p "$cache_path" 2>/dev/null

        cp "$stdout_file" "$cache_path/stdout"
        cp "$stderr_file" "$cache_path/stderr"
        echo $exit_code >"$cache_path/exit_code"
        date +%s >"$cache_path/timestamp"

        set -l command_line (string join ' ' -- (string escape -- $command_parts))
        if test -n "$command_line"
            printf '%s\n' "$command_line" >"$cache_path/command"
        end
        if test -n "$scope"
            printf '%s\n' "$scope" >"$cache_path/scope"
        end
        if test -n "$ttl_raw"
            printf '%s\n' "$ttl_raw" >"$cache_path/ttl"
        end
        if test -n "$ttl_seconds"
            printf '%s\n' "$ttl_seconds" >"$cache_path/ttl_seconds"
        end
    else
        # Clean up any existing cache on failure.
        set -l cache_dir (_cashfish_cache_dir)
        or return $exit_code # can not create cache dir, just return

        # Me being paranoid about deleting stuff.
        if string match -q "$cache_dir/*" "$cache_path"
            rm -rf "$cache_path" 2>/dev/null
        end
    end

    rm -rf "$temp_dir"

    return $exit_code
end

# Check if auto cleanup should run; 1 | 0
function _cashfish_should_auto_cleanup -a cache_dir
    set -l cleanup_interval 86400 # 24 hours
    if set -q CASHFISH_AUTO_CLEANUP_INTERVAL
        set cleanup_interval $CASHFISH_AUTO_CLEANUP_INTERVAL
    end

    set -l last_cleanup_file "$cache_dir/.last_cleanup"
    if not test -f "$last_cleanup_file"
        return 0
    end

    set -l last_cleanup (cat "$last_cleanup_file" 2>/dev/null)
    or return 0 # If can't read, cleanup

    set -l now (date +%s)
    set -l elapsed (math $now - $last_cleanup)

    if test $elapsed -ge $cleanup_interval
        return 0
    else
        return 1
    end
end

# Run cleanup and update last cleanup timestamp
function _cashfish_auto_cleanup -a cache_dir
    set -l now (date +%s)
    for entry in "$cache_dir"/*
        if test "$entry" = "$cache_dir/.last_cleanup"
            continue
        end

        if not test -d "$entry"
            continue
        end

        # Paranoia
        if not string match -q "$cache_dir/*" "$entry"
            continue
        end

        if not test -f "$entry/timestamp"
            # Some how incomplete cache entry, nuke em.
            rm -rf "$entry" 2>/dev/null
            continue
        end

        set -l timestamp (cat "$entry/timestamp" 2>/dev/null)
        or begin
            rm -rf "$entry" 2>/dev/null
            continue
        end

        set -l age (math $now - $timestamp)
        if test $age -gt 604800 # 7 days
            rm -rf "$entry" 2>/dev/null
        end
    end

    echo $now >"$cache_dir/.last_cleanup" 2>/dev/null
end

# Cleanup old cache entries, on demand.
# TODO: can be re-used in auto cleanup.
function cashfish_cleanup -d "Remove expired cache entries"
    set -l cache_dir (_cashfish_cache_dir)
    or return 1

    if not test -d "$cache_dir"
        return 0
    end

    set -l now (date +%s)

    # Iterate through cache entries
    for entry in $cache_dir/*
        if not test -d "$entry"
            continue
        end

        # Defensive check: only delete if entry is under cache directory
        if not string match -q "$cache_dir/*" "$entry"
            continue
        end

        # Check if timestamp file exists
        if not test -f "$entry/timestamp"
            # Remove incomplete cache entries
            rm -rf "$entry" 2>/dev/null
            continue
        end

        set -l timestamp (cat "$entry/timestamp" 2>/dev/null)
        or begin
            rm -rf "$entry" 2>/dev/null
            continue
        end

        # Remove entries older than 7 days
        set -l age (math $now - $timestamp)
        if test $age -gt 604800 # 7 days in seconds
            rm -rf "$entry" 2>/dev/null
        end
    end
end
