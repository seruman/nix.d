function fish_user_key_bindings
    set -g fish_sequence_key_delay_ms 300

    bind ctrl-c cancel-commandline
    bind ctrl-x,ctrl-e edit_command_buffer
    bind ctrl-l,ctrl-t __fish_git_semtag
    bind ctrl-h,ctrl-t __fish_ht_attach
end
