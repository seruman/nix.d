local must = require("utils").must

local function fish(command)
	return function(ctx)
		must(rex.exec.start({ os.getenv("SHELL"), "-l", "-c", command }, {
			detach = true,
			env = {
				REX_SESSION = ctx.session_id,
				REX_BLOCK = ctx.block_id,
				REX_CLIENT = ctx.client_id,
			},
			stdout = false,
			stderr = function(chunk)
				rex.log("error", command .. ": " .. chunk)
			end,
		}))
	end
end

for _, menu in ipairs({
	{ "gpick_repos", "Pick Repository", "gpick repos" },
	{ "gpick_worktrees", "Pick Worktree", "gpick worktrees" },
	{ "gpick_memos", "Pick Memo", "gpick memos" },
	{ "bpick_floating", "Pick Floating Block", "bpick floating" },
	{ "bpick_detached", "Attach Block", "bpick detached" },
}) do
	rex.action({ name = menu[1], title = menu[2], run = fish(menu[3]) })
end
