function dsf --wraps colordiff --description 'colordiff with diff-so-fancy'
    colordiff -u $argv | diff-so-fancy
end
