function treefd --wraps fd
    if not command -sq fd
        echo "fd is not installed"
        return 1
    end
    if not command -sq as-tree
        echo "as-tree is not installed"
        return 1
    end

    set -l fd_args $argv
    if test (count $fd_args) -eq 0
        set fd_args "."
    end
    fd $fd_args | as-tree
end
