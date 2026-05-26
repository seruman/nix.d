function history --wraps=history --description='Show history with timestamps'
    builtin history --show-time='%F %T ' $argv
end 
