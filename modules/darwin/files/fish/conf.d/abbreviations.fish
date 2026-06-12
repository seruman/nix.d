status is-interactive; or return

# git
#abbr -a gr 'git root'
# cd into git root aka cd (git root)
abbr -a gr 'cd (git root)'

# docker-compose
abbr -a dc 'docker compose'

# go
## gotest
abbr -a got 'gotest -v'
abbr -a gota 'gotest -v ./...'
abbr -a gotai 'gotest -v ./... -tags=integration'
abbr -a gotanc 'gotest -v ./... -count=1'
abbr -a gotar --set-cursor='%' 'gotest -v ./... -run "%"'

## gotestsum
abbr -a gots gotestsum
abbr -a gotsa 'gotestsum -- ./...'
abbr -a gotsai 'gotestsum -- ./... -tags=integration'
abbr -a gotsanc 'gotestsum -- ./... -count=1'
abbr -a gotsaf 'gotestsum -- ./... -count=1 -run=(rg \'func (Test.+)\(\' (fd -t f -e go -E vendor .) -NIo --no-heading -r "\$1" | fzf)'
abbr -a gotsar --set-cursor='%' 'gotestsum -- ./... -run="%"' # run test with name

## goimports
abbr -a goil 'goimports -l (fd -t f -e go -E vendor .)'
abbr -a goid 'goimports -d (fd -t f -e go -E vendor .) | colordiff'
abbr -a goiw 'goimports -w (fd -t f -e go -E vendor .)'

# github
abbr -a ghprls 'gh pr list'
abbr -a ghprlsf 'GH_FORCE_TTY=yes gh pr list | fzf --ansi --header-lines 4 --preview "GH_FORCE_TTY=yes gh pr view {1}" | awk \'{print $1}\' | xargs -I {} gh pr view --web {}'
abbr -a ghprcof 'GH_FORCE_TTY=yes gh pr list | fzf --ansi --header-lines 4 --preview "GH_FORCE_TTY=yes gh pr view {1}" | awk \'{print $1}\' | xargs -I {} gh pr checkout {}'
abbr -a ghprmk 'gh pr create'

# ripgrep
abbr -a rgnoi 'rg --no-ignore'

# unixtime
abbr -a ute 'unixtime encode'
abbr -a utd 'unixtime decode'

abbr --position anywhere '$?' '$status'
