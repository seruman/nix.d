function _cashf_preview --description 'Preview cache entry for cashf'
    set -l cache_path $argv[1]
    if test -z "$cache_path"
        echo "No cache entry selected"
        return 0
    end

    if not test -d "$cache_path"
        echo "Cache entry not found: $cache_path"
        return 1
    end

    set -l command_lines (cat "$cache_path/command" 2>/dev/null)
    if test (count $command_lines) -gt 0; and string match -q -- "--" $command_lines[1]
        set command_lines $command_lines[2..-1]
    end
    set -l command (string join ' ' -- $command_lines)

    set -l scope_lines (cat "$cache_path/scope" 2>/dev/null)
    if test (count $scope_lines) -gt 0; and string match -q -- "--" $scope_lines[1]
        set scope_lines $scope_lines[2..-1]
    end
    set -l scope (string join ' ' -- $scope_lines)

    set -l ttl_lines (cat "$cache_path/ttl" 2>/dev/null)
    if test (count $ttl_lines) -gt 0; and string match -q -- "--" $ttl_lines[1]
        set ttl_lines $ttl_lines[2..-1]
    end
    set -l ttl (string join ' ' -- $ttl_lines)

    set -l ttl_seconds_lines (cat "$cache_path/ttl_seconds" 2>/dev/null)
    if test (count $ttl_seconds_lines) -gt 0; and string match -q -- "--" $ttl_seconds_lines[1]
        set ttl_seconds_lines $ttl_seconds_lines[2..-1]
    end
    set -l ttl_seconds (string join ' ' -- $ttl_seconds_lines)
    set -l timestamp (cat "$cache_path/timestamp" 2>/dev/null)
    set -l exit_code (cat "$cache_path/exit_code" 2>/dev/null)

    if test -z "$command"
        set command (path basename "$cache_path")
    end

    if test -z "$exit_code"
        set exit_code "?"
    end

    set -l now (date +%s)
    set -l age_seconds -1
    if string match -qr '^[0-9]+$' -- "$timestamp"
        set age_seconds (math $now - $timestamp)
    end

    set -l age_label (_cashf_format_age $age_seconds)

    set -l entry_state fresh
    if test $age_seconds -le 0
        set entry_state expired
    else if string match -qr '^[0-9]+$' -- "$ttl_seconds"
        if test $age_seconds -gt $ttl_seconds
            set entry_state expired
        end
    end

    echo "Command: $command"
    if test -n "$scope"
        echo "Scope: $scope"
    end
    if test -n "$ttl"
        echo "TTL: $ttl"
    else if string match -qr '^[0-9]+$' -- "$ttl_seconds"
        echo "TTL: $ttl_seconds""s"
    end
    if test -n "$timestamp"
        echo "Timestamp: $timestamp"
    end
    echo "Age: $age_label"
    echo "Exit: $exit_code"
    echo "Status: $entry_state"
    echo ""
    echo "STDOUT:"
    if test -f "$cache_path/stdout"
        if type -q bat
            bat --style=plain --paging=never --color=always "$cache_path/stdout"
        else
            cat "$cache_path/stdout"
        end
    else
        echo "(missing)"
    end
    echo ""
    echo "STDERR:"
    if test -f "$cache_path/stderr"
        if type -q bat
            bat --style=plain --paging=never --color=always "$cache_path/stderr"
        else
            cat "$cache_path/stderr"
        end
    else
        echo "(missing)"
    end
end
