function dtouch
    if test (count $argv) -eq 0
        echo "Usage: dtouch <filepath>..."
        return 1
    end

    for filepath in $argv
        set dirpath (dirname $filepath)

        mkdir -p $dirpath
        touch $filepath
    end
end
