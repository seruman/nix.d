function _ghqf_preview --description 'Preview function for ghqf'
    set -l repo $argv[1]
    set -l repo_path (ghq list --full-path -e $repo)

    set -lx CLICOLOR_FORCE 1
    set -lx COLORTERM truecolor

    set -l current_branch (git -C $repo_path branch --show-current)
    set -l ref_name (git -C $repo_path name-rev --name-only HEAD)
    set -l ref_to_show $current_branch
    test -z "$ref_to_show"; and set ref_to_show $ref_name

    gum format -t template "{{ Foreground (Color \"31\" ) (Bold \"$repo\")}} @{{ Bold \"$ref_to_show\" }}"
    echo

    for remote in (git -C $repo_path remote)
        set -l url (git -C $repo_path remote get-url $remote)
        gum format -t template "{{ Bold \"$remote\" }}: {{ Underline \"$url\" }}"
        echo
    end

    set -l readme_file (find $repo_path -maxdepth 1 -iname "readme.md" -type f | head -n1)
    if test -n "$readme_file"
        glow -s light $readme_file
    end
end
