local function must(result, err)
	if err then
		error(err, 0)
	end
	return result
end

local function quote(value)
	return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function cell(value)
	return (value or ""):gsub("[%c]", " ")
end

local placements = {
	right = { direction = "horizontal", side = "after" },
	left = { direction = "horizontal", side = "before" },
	below = { direction = "vertical", side = "after" },
	above = { direction = "vertical", side = "before" },
}

local function restore(ctx, args)
	local placement = placements[args.placement]
	if not placement and args.placement ~= "tab" then
		error("Unknown restore placement", 0)
	end
	local session, anchor = ctx.session_id, ctx.block_id
	local placeholder, window_id
	if args.placement == "tab" then
		-- new_window cannot take an existing block, so use a disposable anchor.
		local window = must(rex.session.new_window({
			session_id = session,
			focus = false,
			layout = rex.layout.block({
				flavor = "com.superlogical.terminal.shell",
				options = { command = { "/bin/sleep", "86400" } },
			}),
		}))
		window_id, placeholder = window.window_id, window.block_ids[1]
		anchor, placement = placeholder, placements.right
	end
	local result, err = rex.session.move_block({
		session_id = session,
		block_id = args.selected_block_id,
		anchor_block_id = anchor,
		direction = placement.direction,
		side = placement.side,
	})
	local cleanup_err
	if placeholder then
		local _
		_, cleanup_err = rex.call("block.close", { session_id = session, block_id = placeholder })
	end
	must(result, err)
	must(true, cleanup_err)
	must(rex.session.focus_block({ session_id = session, block_id = args.selected_block_id }))
	if window_id then
		-- Server focus alone does not select the tab displayed by Rex.app.
		rex.client.queue("session.select", { session_id = session, window_id = window_id })
	end
	return result
end

return function(ctx, args)
	if not ctx.session_id or not ctx.block_id then
		error("Focus a tiled pane first", 0)
	end
	local session = ctx.session_id
	if args.selected_block_id then
		return restore(ctx, args)
	end

	local blocks = must(rex.session.list_blocks({ session_id = session })).blocks or {}
	local rows = {}
	for _, block in ipairs(blocks) do
		if block.placement == "detached" then
			local title =
				rex.call("block.method", { session_id = session, block_id = block.block_id, method = "title" })
			table.insert(
				rows,
				quote(table.concat({
					block.block_id,
					cell(block.label),
					cell(title and title.title),
					block.block_id:match("[^-]+$"),
				}, "\t"))
			)
		end
	end
	if #rows == 0 then
		return { message = "No detached blocks in this session" }
	end

	local view = must(rex.session.view({ session_id = session }))
	local window_id, rect
	for _, window in ipairs(view.windows or {}) do
		for _, layer in ipairs(window.layers or {}) do
			if layer.kind == "tiled" then
				for _, block in ipairs(layer.blocks or {}) do
					if block.block_id == ctx.block_id then
						window_id, rect = window.window_id, block.rect
					end
				end
			end
		end
	end
	if not rect or rect.w <= 0 or rect.h <= 0 then
		error("Launch the picker from a tiled pane", 0)
	end
	local size = must(rex.call("block.method", { session_id = session, block_id = ctx.block_id, method = "size" }))
	local cols, rows_count = size.columns / rect.w, size.rows / rect.h
	if cols <= 0 or rows_count <= 0 then
		error("Cannot determine the window size", 0)
	end

	local callback = "rex"
		.. (ctx.client_id and (" -C " .. quote(ctx.client_id)) or "")
		.. " do attach_block -s "
		.. quote(session)
		.. " -b "
		.. quote(ctx.block_id)
		.. " selected_block_id={1} placement="

	-- Rex preview renderer workaround: bounds render as edges but the PTY
	-- sizes them as extents. Reserve the clipped area with cell margins;
	-- fzf rejects percentage margins above 49% on larger windows.
	local w, h = math.min(200 / cols, 0.9), math.min(26 / rows_count, 0.9)
	local x, y = (1 - w) / 2, (1 - h) / 2
	local right = math.ceil(x * cols) + 1
	local bottom = math.ceil(y * rows_count) + 1
	local command = {
		"/usr/bin/env",
		"FZF_DEFAULT_COMMAND=printf '%s\\n' " .. table.concat(rows, " "),
		"FZF_DEFAULT_OPTS=",
		"FZF_DEFAULT_OPTS_FILE=/dev/null",
		"fzf",
		"--layout=reverse",
		string.format("--margin=0,%d,%d,0", right, bottom),
		"--border=rounded",
		"--border-label= Attach Block ",
		"--color=bg:#ece9e4,bg+:#dce7eb,fg:#6b5c4d,fg+:#6b5c4d,header:#443a31:bold",
		"--delimiter=\t",
		"--with-nth=2..",
		"--prompt=Attach > ",
		"--header=Enter / Ctrl-L: right\nCtrl-H: left  Ctrl-J: below\nCtrl-K: above Ctrl-T: new tab\nEsc: cancel  Ctrl-/: preview",
		"--preview=rex capture -s " .. quote(session) .. " -b {1} --format=vt --trim",
		"--preview-window=right,55%,nowrap,follow",
		"--bind=ctrl-/:toggle-preview,ctrl-w:toggle-preview-wrap",
	}
	for _, binding in ipairs({
		{ "enter", "right" },
		{ "ctrl-l", "right" },
		{ "ctrl-h", "left" },
		{ "ctrl-j", "below" },
		{ "ctrl-k", "above" },
		{ "ctrl-t", "tab" },
	}) do
		table.insert(command, "--bind=" .. binding[1] .. ":execute-silent(" .. callback .. binding[2] .. ")+abort")
	end
	return must(rex.session.new_layer({
		session_id = session,
		window_id = window_id,
		bounds = { x = x, y = y, w = x + w, h = y + h },
		focus = true,
		layout = rex.layout.block({
			flavor = "com.superlogical.terminal.shell",
			options = {
				size = { columns = math.ceil(cols * (x + w)), rows = math.ceil(rows_count * (y + h)) },
				command = command,
				theme = { background = "#ece9e4", foreground = "#6b5c4d" },
				exit = { on_completion = true, quick_exit_threshold_ms = 0 },
			},
		}),
	}))
end
