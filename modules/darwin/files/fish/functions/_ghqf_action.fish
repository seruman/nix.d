function _ghqf_action --description 'Open a ghq repository in a Rex project tab'
    set -l repo $argv[1]
    if test -z "$repo"
        return 1
    end

    set -l repo_path (ghq list --full-path -e "$repo")
    if test -z "$repo_path"
        return 1
    end

    set -l name (__git_repo_name "$repo_path")
    or return 1

    rex do project_tab "cwd=$repo_path" "label=$name" >/dev/null
end
