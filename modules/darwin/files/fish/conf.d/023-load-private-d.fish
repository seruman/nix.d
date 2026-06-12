# Load private fish config snippets from ~/.config/fish/private.d
set -l private_d ~/.config/fish/private.d
if test -d $private_d
    for f in $private_d/*.fish
        if test -f $f
            source $f
        end
    end
end
