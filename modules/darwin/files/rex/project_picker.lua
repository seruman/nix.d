local must = require("utils").must

local script = [[
set -l selection (ghq list | fzf \
    --ansi --no-multi --layout=reverse --border=none \
    --prompt 'Repositories> ' \
    --header 'Enter: project tab  Esc: cancel' \
    --with-shell 'fish -c' --preview '_ghqf_preview {}')
set -l result $status
if test $result -eq 1; or test $result -eq 130
    exit 0
end
if test $result -ne 0
    exit $result
end
test -n "$selection"; or exit 0
set -l repo (ghq list --full-path -e "$selection")
test -n "$repo"; or exit 1
_git_dir_action tab "$repo"
]]

return function(ctx)
	if not ctx.session_id then
		error("Open a session first", 0)
	end

	local command = { "/usr/bin/env", "FZF_DEFAULT_OPTS=", "FZF_DEFAULT_OPTS_FILE=/dev/null" }
	if ctx.client_id then
		table.insert(command, "REX_CLIENT=" .. ctx.client_id)
	end
	for _, arg in ipairs({ "fish", "-c", script }) do
		table.insert(command, arg)
	end

	return must(rex.session.new_layer({
		session_id = ctx.session_id,
		bounds = { 0.1, 0.1, 0.8, 0.8 },
		focus = true,
		layout = rex.layout.block({
			flavor = "com.superlogical.terminal.shell",
			label = "Repositories",
			options = {
				command = command,
				exit = { on_completion = true, quick_exit_threshold_ms = 0 },
			},
		}),
	}))
end
