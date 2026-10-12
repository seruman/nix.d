function __git_repo_name --description 'Get a repository namespace/name from its configured remote'
    set -l repo_path $argv[1]
    if test -z "$repo_path"
        return 1
    end

    set -l remote (git -C "$repo_path" config --get gwt.remote)
    if test -z "$remote"
        set remote origin
    end
    set -l remote_url (git -C "$repo_path" remote get-url -- "$remote")
    or return 1

    set -l name (string replace --regex '^(?:(?:ssh|https?|git)://[^/]+/|[^/:]+:(?!//))' '' -- "$remote_url")
    if test "$name" = "$remote_url"
        printf '__git_repo_name: cannot derive a project name from remote %s\n' "$remote" >&2
        return 1
    end
    set name (string replace --regex '[?#].*$' '' -- "$name" \
        | string unescape --style=url \
        | string trim --chars=/ \
        | string replace --regex '\.git$' '')
    if test -z "$name"; or string match --quiet --regex '(^|/)\.\.?(/|$)|[[:cntrl:]]' -- "$name"
        printf '__git_repo_name: remote %s has no valid project name\n' "$remote" >&2
        return 1
    end

    printf '%s\n' "$name"
end
