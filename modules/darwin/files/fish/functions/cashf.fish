function cashf --description 'Fuzzy browse cashfish cache'
    set -l cashf_dir (path dirname (status --current-filename))
    if not functions -q _cashf_format_age
        if test -n "$__fish_config_dir"; and test -f "$__fish_config_dir/functions/_cashf_format_age.fish"
            source "$__fish_config_dir/functions/_cashf_format_age.fish"
        else if test -f "$cashf_dir/_cashf_format_age.fish"
            source "$cashf_dir/_cashf_format_age.fish"
        end
    end

    if not functions -q _cashf_preview
        if test -n "$__fish_config_dir"; and test -f "$__fish_config_dir/functions/_cashf_preview.fish"
            source "$__fish_config_dir/functions/_cashf_preview.fish"
        else if test -f "$cashf_dir/_cashf_preview.fish"
            source "$cashf_dir/_cashf_preview.fish"
        end
    end

    if not type -q fzf
        echo "cashf: fzf is required" >&2
        return 1
    end

    set -l cache_base
    if set -q XDG_CACHE_HOME
        set cache_base "$XDG_CACHE_HOME"
    else if set -q HOME
        set cache_base "$HOME/.cache"
    else
        echo "cashf: HOME environment variable not set" >&2
        return 1
    end

    set -l cache_dir "$cache_base/cashfish"
    if not test -d "$cache_dir"
        echo "cashf: cache directory not found: $cache_dir" >&2
        return 1
    end

    set -l now (date +%s)
    set -l lines
    set -l tab (printf '\t')
    set -l command_width 60
    set -l age_width 10
    set -l exit_width 4
    set -l state_width 8

    for entry in $cache_dir/*
        if not test -d "$entry"
            continue
        end

        set -l timestamp (cat "$entry/timestamp" 2>/dev/null)
        set -l exit_code (cat "$entry/exit_code" 2>/dev/null)
        set -l command_lines (cat "$entry/command" 2>/dev/null)
        if test (count $command_lines) -gt 0; and string match -q -- "--" $command_lines[1]
            set command_lines $command_lines[2..-1]
        end
        set -l command (string join ' ' -- $command_lines)

        set -l scope_lines (cat "$entry/scope" 2>/dev/null)
        if test (count $scope_lines) -gt 0; and string match -q -- "--" $scope_lines[1]
            set scope_lines $scope_lines[2..-1]
        end
        set -l scope (string join ' ' -- $scope_lines)

        set -l ttl_seconds_lines (cat "$entry/ttl_seconds" 2>/dev/null)
        if test (count $ttl_seconds_lines) -gt 0; and string match -q -- "--" $ttl_seconds_lines[1]
            set ttl_seconds_lines $ttl_seconds_lines[2..-1]
        end
        set -l ttl_seconds_raw (string join ' ' -- $ttl_seconds_lines)

        if test -z "$command"
            set command (path basename "$entry")
        end

        if test -n "$scope"
            set command "[$scope] $command"
        end

        set -l age_seconds -1
        if string match -qr '^[0-9]+$' -- "$timestamp"
            set age_seconds (math $now - $timestamp)
        end

        set -l age_label (_cashf_format_age $age_seconds)

    set -l entry_state fresh
    if test $age_seconds -le 0
        set entry_state expired
    else if string match -qr '^[0-9]+$' -- "$ttl_seconds_raw"
        if test $age_seconds -gt $ttl_seconds_raw
            set entry_state expired
        end
    end

        if test -z "$exit_code"
            set exit_code "?"
        end

        set -l command_display $command
        if test (string length -- "$command_display") -gt $command_width
            set -l cut (math $command_width - 3)
            if test $cut -lt 1
                set cut 1
            end
            set command_display (string sub -l $cut -- "$command_display")"..."
        end

        set -l display (printf "%-*s %-*s %-*s %-*s" $command_width $command_display $age_width $age_label $exit_width $exit_code $state_width $entry_state)
        set -a lines "$display$tab$entry"
    end

    if test (count $lines) -eq 0
        echo "cashf: no cache entries found" >&2
        return 0
    end

    set -l header_display (printf "%-*s %-*s %-*s %-*s %s" $command_width "COMMAND" $age_width "AGE" $exit_width "EXIT" $state_width "STATE" "[enter]=select [ctrl-d]=delete")
    set -l selection_file (mktemp)
    printf '%s\n' "$header_display$tab" $lines | fzf \
        --multi \
        --delimiter '\t' \
        --with-nth=1 \
        --header-lines=1 \
        --prompt 'cashf> ' \
        --preview '_cashf_preview {2}' \
        --preview-window 'right,60%,wrap' \
        --expect=ctrl-d \
    > "$selection_file"

    if not test -s "$selection_file"
        rm -f "$selection_file"
        return 0
    end

    set -l selection
    while read -l line
        set -a selection -- "$line"
    end < "$selection_file"
    rm -f "$selection_file"

    if test (count $selection) -eq 0
        return 0
    end

    set -l key $selection[1]
    set -l picks $selection[2..-1]

    if test (count $picks) -eq 0
        return 0
    end

    if test "$key" = "ctrl-d"
        set -l to_delete
        for line in $picks
            set -l fields (string split -m 1 $tab -- $line)
            set -l path $fields[2]
            if test -n "$path"
                set -a to_delete $path
            end
        end

        if test (count $to_delete) -eq 0
            return 0
        end

        set -l count (count $to_delete)
        read -l -P "Delete $count cache entr(y/ies)? [y/N] " confirm
        set -l confirm_l (string lower -- "$confirm")
        if test "$confirm_l" = "y" -o "$confirm_l" = "yes"
            for path in $to_delete
                if test -d "$path"
                    if string match -q "$cache_dir/*" "$path"
                        rm -rf "$path" 2>/dev/null
                    end
                end
            end
            echo "Deleted $count cache entr(y/ies)."
        end
    end
end
