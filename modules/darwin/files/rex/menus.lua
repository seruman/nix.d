local terminal = "com.superlogical.terminal"
local shell = "com.superlogical.terminal.shell"
local NEW = "\0new"

-- The Rex server doesn't inherit the login shell's PATH (nix profile, cargo, ...).
local path
local function env()
	if not path then
		local result = rex.exec({ os.getenv("SHELL"), "-l", "-c", "printenv PATH" }, { timeout = 10 })
		path = result and result.ok and result.stdout:gsub("\n$", "") or os.getenv("PATH")
	end
	return { PATH = path }
end

local function run(argv)
	local result, err = rex.exec(argv, { timeout = 20, env = env() })
	if not result then
		error(err, 0)
	end
	if not result.ok then
		error(table.concat(argv, " ") .. ": " .. result.stderr, 0)
	end
	return result.stdout
end

local home = os.getenv("HOME")
local function tilde(p)
	if home and p:sub(1, #home + 1) == home .. "/" then
		return "~" .. p:sub(#home + 1)
	end
	return p
end

local function lines(text)
	return text:gmatch("[^\n]+")
end

local function chomp(text)
	return (text:gsub("\n$", ""))
end

local function repo_name(repo)
	local remote = rex.exec({ "git", "-C", repo, "config", "--get", "gwt.remote" }, { env = env() }).stdout
	remote = chomp(remote)
	if remote == "" then
		remote = "origin"
	end
	local url = chomp(run({ "git", "-C", repo, "remote", "get-url", "--", remote }))
	local name = url:match("^%a[%w+.-]*://[^/]+/(.+)$") or url:match("^[^/:]+:(.+)$")
	if not name then
		error("cannot derive a project name from remote " .. remote, 0)
	end
	name = name:gsub("[?#].*$", "")
		:gsub("%%(%x%x)", function(hex)
			return string.char(tonumber(hex, 16))
		end)
		:gsub("^/+", "")
		:gsub("/+$", "")
		:gsub("%.git$", "")
	return name
end

local function cwd(ctx)
	local pwd = rex.block.call(terminal, "pwd", { session_id = ctx.session_id, block_id = ctx.block_id }).pwd or ""
	return (pwd:gsub("^file://[^/]*", ""):gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

local function pick_target(title)
	return rex.ui.pick({
		title = title,
		items = {
			{ id = "tab", title = "Project tab", icon = "terminal" },
			{ id = "right", title = "Split right", icon = "terminal" },
			{ id = "below", title = "Split below", icon = "terminal" },
		},
	})
end

local function open(ctx, target, dir, repo)
	local layout = rex.layout.block({ flavor = shell, options = { cwd = dir } })
	if target ~= "tab" then
		local _, err = rex.session.new_split({
			anchor_id = ctx.block_id,
			direction = target == "right" and "horizontal" or "vertical",
			side = "after",
			focus = true,
			layout = layout,
		})
		if err then
			error(err, 0)
		end
		return
	end

	local name = repo_name(repo or dir)
	local session_id, window_id
	for _, session in ipairs(rex.call("session.list").sessions or {}) do
		if session.label == name then
			session_id = session.session_id
		end
	end
	if session_id then
		rex.call("session.attach", { session_id = session_id })
		local window, err = rex.session.new_window({ session_id = session_id, layout = layout })
		if err then
			error(err, 0)
		end
		window_id = window.window_id
	else
		local session, err = rex.call("session.create", {
			label = name,
			initial_windows = { { window_label = "shell", layout = layout } },
		})
		if err then
			error(err, 0)
		end
		session_id = session.session_id
		window_id = session.initial_windows[1].window_id
	end
	rex.client.queue("session.select", { session_id = session_id, window_id = window_id })
end

local function worktrees(ctx, repo)
	repo = repo or cwd(ctx)
	local items = { { id = NEW, title = "New worktree…", icon = "plus" } }
	for _, tree in ipairs(rex.json.decode(run({ "git", "-C", repo, "wt", "list", "--json" }))) do
		if not tree.bare then
			items[#items + 1] = {
				id = tree.path,
				title = tree.branch or "detached",
				subtitle = tilde(tree.path),
				detail = tree.current and "Current" or nil,
				icon = "branch",
			}
		end
	end

	local choice = rex.ui.pick({
		title = "Worktrees",
		placeholder = "Pick a worktree or type a new branch",
		items = items,
		allow_other = true,
	})
	if not choice then
		return
	end

	local branch
	if choice == NEW then
		branch = rex.ui.input({ title = "New worktree", placeholder = "Branch name" })
	elseif type(choice) == "table" then
		branch = choice.text
	end
	if branch == "" then
		return
	end

	local target = pick_target(branch and ("Create " .. branch) or "Open worktree")
	if not target then
		return
	end
	if branch then
		choice = rex.json.decode(run({ "git", "-C", repo, "wt", "new", "--json", "--", branch })).path
	end
	open(ctx, target, choice, repo)
end

local function memos(ctx, repo)
	repo = repo or cwd(ctx)
	local scope = chomp(run({ "git", "-C", repo, "memo", "path" }))
	local items = { { id = NEW, title = "New memo…", icon = "plus" } }
	for line in lines(run({ "git", "-C", repo, "memo", "list" })) do
		local name, title = line:match("^([^\t]+)\t?(.*)$")
		items[#items + 1] = { id = scope .. "/" .. name, title = name, subtitle = title, icon = "document" }
	end

	local choice = rex.ui.pick({
		title = "Memos",
		placeholder = "Pick a memo or type a new label",
		items = items,
		allow_other = true,
	})
	if not choice then
		return
	end

	local label
	if choice == NEW then
		label = rex.ui.input({ title = "New memo", placeholder = "Memo label" })
	elseif type(choice) == "table" then
		label = choice.text
	end
	if label == "" then
		return
	end

	local target = pick_target(label and "Create memo" or "Open memo")
	if not target then
		return
	end
	if label then
		choice = chomp(run({ "git", "-C", repo, "memo", "new", "--", label }))
	end
	open(ctx, target, choice, repo)
end

local function repos(ctx)
	local roots = {}
	for root in lines(run({ "ghq", "root", "--all" })) do
		roots[#roots + 1] = root
	end
	local items = {}
	for path in lines(run({ "ghq", "list", "-p" })) do
		local title = path
		for _, root in ipairs(roots) do
			if path:sub(1, #root + 1) == root .. "/" then
				title = path:sub(#root + 2)
			end
		end
		items[#items + 1] = { id = path, title = title, subtitle = tilde(path), icon = "folder" }
	end

	local repo = rex.ui.pick({ title = "Repositories", items = items })
	if not repo then
		return
	end
	local target = rex.ui.pick({
		title = "Open repository",
		items = {
			{ id = "tab", title = "Project tab", icon = "terminal" },
			{ id = "right", title = "Split right", icon = "terminal" },
			{ id = "below", title = "Split below", icon = "terminal" },
			{ id = "worktrees", title = "Worktrees…", icon = "branch" },
			{ id = "memos", title = "Memos…", icon = "document" },
		},
	})
	if target == "worktrees" then
		worktrees(ctx, repo)
	elseif target == "memos" then
		memos(ctx, repo)
	elseif target then
		open(ctx, target, repo)
	end
end

local function floating(ctx)
	local view = rex.session.view({})
	local layers = {}
	for _, window in ipairs(view.windows or {}) do
		if window.window_id == view.active_window_id then
			for _, layer in ipairs(window.layers or {}) do
				if layer.kind == "floating" then
					local labels = {}
					for _, block in ipairs(layer.blocks or {}) do
						labels[#labels + 1] = block.label
					end
					layers[#layers + 1] = {
						id = layer.layer_id,
						title = table.concat(labels, ", "),
						detail = layer.state == "minimized" and "Minimized" or nil,
						icon = "terminal",
					}
				end
			end
		end
	end

	local layer_id = rex.ui.pick({ title = "Floating blocks", items = layers })
	if layer_id then
		rex.call("session.set_layer_state", {
			session_id = ctx.session_id,
			layer_id = layer_id,
			state = "normal",
			focus = true,
		})
	end
end

local function detached(ctx)
	local items = {}
	for _, block in ipairs(rex.session.list_blocks({}).blocks or {}) do
		if block.placement == "detached" then
			items[#items + 1] =
				{ id = block.block_id, title = block.label, detail = block.block_id:sub(-6), icon = "terminal" }
		end
	end

	local block_id = rex.ui.pick({ title = "Attach block", items = items })
	if not block_id then
		return
	end
	local target = rex.ui.pick({
		title = "Attach in",
		items = {
			{ id = "right", title = "Split right", icon = "terminal" },
			{ id = "below", title = "Split below", icon = "terminal" },
		},
	})
	if not target then
		return
	end
	rex.session.move_block({
		block_id = block_id,
		anchor_block_id = ctx.block_id,
		direction = target == "right" and "horizontal" or "vertical",
		side = "after",
	})
	rex.session.focus_block({ block_id = block_id })
end

for _, menu in ipairs({
	{ "gpick_repos", "Pick Repository", repos },
	{ "gpick_worktrees", "Pick Worktree", worktrees },
	{ "gpick_memos", "Pick Memo", memos },
	{ "bpick_floating", "Pick Floating Block", floating },
	{ "bpick_detached", "Attach Block", detached },
}) do
	local fn = menu[3]
	rex.action({
		name = menu[1],
		title = menu[2],
		run = function(ctx)
			return fn(ctx)
		end,
	})
end
