function fish_reload_config
    if status is-login
        exec fish -l
    else
        exec fish
    end
end
