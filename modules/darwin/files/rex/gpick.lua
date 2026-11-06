local must = require("utils").must

for _, picker in ipairs({
	{ "repos", "Pick Repository" },
	{ "worktrees", "Pick Worktree" },
	{ "memos", "Pick Memo" },
}) do
	rex.action({
		name = "gpick_" .. picker[1],
		title = picker[2],
		keywords = "gpick ghq git worktree memo",
		run = function(ctx)
			must(rex.exec.start({ os.getenv("SHELL"), "-l", "-c", "gpick $argv", picker[1] }, {
				detach = true,
				env = {
					REX_SESSION = ctx.session_id,
					REX_BLOCK = ctx.block_id,
					REX_CLIENT = ctx.client_id,
				},
				stdout = false,
				stderr = function(chunk)
					rex.log("error", "gpick: " .. chunk)
				end,
			}))
		end,
	})
end
