function _cashf_format_age -a age_seconds --description 'Format age in seconds'
    if test -z "$age_seconds"
        echo "unknown"
        return 0
    end

    if test $age_seconds -lt 0
        echo "unknown"
        return 0
    end

    set -l remaining $age_seconds
    set -l days (math "floor($remaining / 86400)")
    set remaining (math $remaining - $days\*86400)
    set -l hours (math "floor($remaining / 3600)")
    set remaining (math $remaining - $hours\*3600)
    set -l mins (math "floor($remaining / 60)")
    set remaining (math $remaining - $mins\*60)
    set -l secs $remaining

    set -l parts
    if test $days -gt 0
        set -a parts "$days""d"
    end
    if test $hours -gt 0
        set -a parts "$hours""h"
    end
    if test $mins -gt 0
        set -a parts "$mins""m"
    end
    if test $secs -gt 0 -o (count $parts) -eq 0
        set -a parts "$secs""s"
    end

    echo (string join ' ' -- $parts)
end
