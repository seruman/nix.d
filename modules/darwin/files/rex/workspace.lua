local must = require("utils").must
local store = require("workspace_store")
local M = {}
local SHELL = "com.superlogical.terminal.shell"

local function call(method, args)
	return must(rex.call(method, args))
end

local function parse_prefill(text)
	if type(text) == "string" and text ~= "" and not text:find("%c") then
		return text
	end
end

local function basename(path)
	return (path or ""):match("([^/]+)$") or ""
end

local shells =
	{ sh = true, bash = true, zsh = true, fish = true, dash = true, ksh = true, nu = true, csh = true, tcsh = true }

local function quote_word(value)
	if value:match("^[%w_@%%+=:,./%-]+$") then
		return value
	end
	return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function parse_command(process)
	local fg = process.foreground
	if not fg then
		return nil
	end
	local name = basename(fg.invoked_path or fg.path or fg.name)
	if name == "rex" or fg.name == "login" then
		return nil
	end
	local nested = false
	for _, parent in ipairs(process.ancestors or {}) do
		if parent.name ~= "login" then
			nested = true
		end
	end
	if shells[name] and not nested then
		return nil
	end
	local executable = parse_prefill(fg.invoked_path or fg.path or fg.argv0 or fg.name)
	if not executable then
		return nil
	end
	local words = { quote_word(executable) }
	if fg.script then
		local script = parse_prefill(fg.script)
		if not script then
			return nil
		end
		table.insert(words, quote_word(script))
	end
	return table.concat(words, " ")
end

local function parse_directory(pwd, process)
	local value = pwd.pwd
	if value and value:match("^file://") then
		value = value:match("^file://[^/]*(/.*)$")
		if value then
			value = value:gsub("%%(%x%x)", function(hex)
				return string.char(tonumber(hex, 16))
			end)
		end
	end
	if not value or value:sub(1, 1) ~= "/" then
		value = (process.foreground or {}).cwd or process.home or os.getenv("HOME")
	end
	assert(
		type(value) == "string" and value:sub(1, 1) == "/" and not value:find("%z"),
		"Cannot determine pane directory"
	)
	return value
end

local function state(path)
	local server = call("server.status")
	assert(server.host_id and server.instance_id, "Rex server must have a persistent host identity")

	if not path then
		local base = os.getenv("XDG_STATE_HOME") or (assert(os.getenv("HOME")) .. "/.local/state")
		path = base .. "/rex/workspace.json"
	end

	return path, server
end

local function live_sessions()
	local list, ids = call("session.list").sessions or {}, {}
	for _, session in ipairs(list) do
		ids[session.session_id] = true
	end
	return list, ids
end

local function live_id(snapshot, session, live)
	if live[session.id] then
		return session.id
	end
	local restored = snapshot.restored[session.id]
	if restored and live[restored.session_id] then
		return restored.session_id
	end
end

local function remembered_commands(snapshot)
	local commands = {}

	if not snapshot then
		return commands
	end

	for _, session in ipairs(snapshot.sessions) do
		local restored = snapshot.restored[session.id]
		for id, block in pairs(session.blocks) do
			commands[id] = block.prefill
			if restored and restored.blocks[id] then
				commands[restored.blocks[id]] = block.prefill
			end
		end
	end
	return commands
end

local function capture_session(id, server, remembered)
	call("session.attach", { session_id = id })
	local view = call("session.view", { session_id = id })
	local saved =
		{ id = id, label = view.label, active_window = view.active_window_id, windows = {}, blocks = {}, detached = {} }
	for _, block in ipairs(call("session.list_blocks", { session_id = id }).blocks or {}) do
		assert(block.flavor == SHELL, "Cannot snapshot non-shell block " .. block.block_id)
		assert(not block.host_id or block.host_id == server.host_id, "Cannot snapshot remote block " .. block.block_id)
		local function terminal(method)
			return call("block.method", { session_id = id, block_id = block.block_id, method = method })
		end
		local process = terminal("process")
		saved.blocks[block.block_id] = {
			label = block.label,
			cwd = parse_directory(terminal("pwd"), process),
			prefill = parse_command(process) or remembered[block.block_id],
		}
		if block.placement == "detached" then
			table.insert(saved.detached, block.block_id)
		end
	end
	for _, window in ipairs(view.windows or {}) do
		local layers = {}
		for _, layer in ipairs(window.layers or {}) do
			table.insert(layers, { kind = layer.kind, bounds = layer.bounds, layout = layer.layout })
		end
		table.insert(saved.windows, {
			id = window.window_id,
			label = window.label,
			focused = window.focused_block_id,
			zoomed = window.zoomed_block_id,
			layers = layers,
		})
	end
	assert(
		call("session.view", { session_id = id }).revision == view.revision,
		"Workspace changed while saving; try again"
	)
	return saved
end

local function parse_block(block)
	assert(
		type(block) == "table"
			and type(block.cwd) == "string"
			and block.cwd:sub(1, 1) == "/"
			and not block.cwd:find("%z"),
		"Invalid pane directory"
	)
	assert(block.label == nil or type(block.label) == "string", "Invalid pane label")
	block.prefill = parse_prefill(block.prefill)

	return {
		flavor = SHELL,
		label = block.label,
		options = { cwd = block.cwd, initial_input = block.prefill },
	}
end

local function parse_layout(node, blocks, ids, seen, depth)
	assert(type(node) == "table" and depth < 100, "Invalid or excessively deep layout")
	if node.block_id and not node.split then
		local id = node.block_id
		assert(blocks[id], "Layout refers to an unknown pane")
		assert(not seen[id], "Pane occurs twice in snapshot")
		seen[id] = true
		table.insert(ids, id)

		return { block = blocks[id] }
	end
	local split = node.split
	assert(not node.block_id and type(split) == "table", "Invalid layout node")
	assert(split.direction == "horizontal" or split.direction == "vertical", "Invalid split direction")
	assert(type(split.ratio) == "number" and split.ratio > 0 and split.ratio < 1, "Invalid split ratio")
	return {
		split = {
			direction = split.direction,
			ratio = split.ratio,
			before = parse_layout(split.before, blocks, ids, seen, depth + 1),
			after = parse_layout(split.after, blocks, ids, seen, depth + 1),
		},
	}
end

local function parse_sequence(value, name)
	assert(type(value) == "table", "Invalid " .. name)

	local count = 0

	for key in pairs(value) do
		assert(type(key) == "number" and key >= 1 and key <= #value and key % 1 == 0, "Invalid " .. name)
		count = count + 1
	end

	assert(count == #value, "Invalid " .. name)

	return value
end

local function parse_session(saved)
	assert(
		type(saved) == "table" and type(saved.id) == "string" and type(saved.label) == "string",
		"Invalid session identity"
	)
	assert(type(saved.blocks) == "table", "Invalid session panes")
	local plan = {
		id = saved.id,
		label = saved.label,
		active_window = saved.active_window,
		initial_windows = {},
		windows = {},
		detached = {},
	}
	local blocks, seen, windows = {}, {}, {}

	for id, block in pairs(saved.blocks) do
		assert(type(id) == "string", "Invalid pane identity")
		blocks[id] = parse_block(block)
	end

	if saved.detached == nil then
		saved.detached = {}
	end
	parse_sequence(saved.detached, "detached panes")

	for _, window in ipairs(parse_sequence(saved.windows, "session windows")) do
		assert(type(window) == "table", "Invalid window")
		assert(type(window.id) == "string" and not windows[window.id], "Invalid window identity")
		assert(type(window.label) == "string" and type(window.layers) == "table", "Invalid window contents")
		windows[window.id] = true
		local tiled, floats = nil, {}
		for _, layer in ipairs(parse_sequence(window.layers, "window layers")) do
			assert(type(layer) == "table", "Invalid layer")
			local item = { ids = {}, bounds = layer.bounds }

			if layer.layout then
				item.layout = parse_layout(layer.layout, blocks, item.ids, seen, 0)
			end
			if layer.kind == "tiled" then
				assert(not tiled, "Multiple tiled layers")
				tiled = item
			else
				assert(layer.kind == "floating" and item.layout, "Unsupported layer kind or empty floating layer")
				local b = item.bounds
				assert(type(b) == "table" and #b == 4, "Invalid floating bounds")
				for _, n in ipairs(b) do
					assert(type(n) == "number" and n >= 0 and n <= 1, "Invalid floating bounds")
				end
				assert(
					b[3] > 0 and b[4] > 0 and b[1] + b[3] <= 1.000001 and b[2] + b[4] <= 1.000001,
					"Invalid floating bounds"
				)
				table.insert(floats, item)
			end
		end
		assert(tiled, "Window has no tiled layer")
		local placeholder = not tiled.layout
		table.insert(
			plan.initial_windows,
			{ window_label = window.label, layout = tiled.layout or { block = { flavor = SHELL } } }
		)
		table.insert(plan.windows, { saved = window, tiled = tiled, floats = floats, placeholder = placeholder })
	end
	for _, id in ipairs(saved.detached) do
		assert(blocks[id], "Unknown detached pane")
		assert(not seen[id], "Pane occurs twice in snapshot")
		seen[id] = true
		table.insert(plan.detached, { id = id, spec = blocks[id] })
	end
	for id in pairs(saved.blocks) do
		assert(seen[id], "Pane is missing from snapshot layout")
	end

	if #plan.initial_windows == 0 then
		plan.initial_windows = nil
	end

	return plan
end

local function parse_identities(mapping)
	assert(type(mapping) == "table", "Invalid restored identities")

	for before, after in pairs(mapping) do
		assert(type(before) == "string" and type(after) == "string", "Invalid restored identity")
	end
end

local function parse_snapshot(snapshot, server)
	assert(type(snapshot) == "table" and snapshot.version == 1, "Unsupported workspace snapshot version")
	assert(snapshot.host_id == server.host_id, "Workspace belongs to a different Rex host/account")
	assert(type(snapshot.instance_id) == "string", "Invalid server instance")
	if snapshot.restored == nil then
		snapshot.restored = {}
	end
	assert(type(snapshot.restored) == "table", "Invalid restore mappings")
	local plans, identities = {}, {}

	for _, saved in ipairs(parse_sequence(snapshot.sessions, "workspace sessions")) do
		local plan = parse_session(saved)
		assert(not identities[plan.id], "Duplicate session identity")
		identities[plan.id] = true
		table.insert(plans, plan)
	end

	for id, mapping in pairs(snapshot.restored) do
		assert(
			identities[id] and type(mapping) == "table" and type(mapping.session_id) == "string",
			"Invalid restored session"
		)

		parse_identities(mapping.blocks)
		parse_identities(mapping.windows)
	end

	return plans
end

function M.save(ctx, args)
	local path, server = state(args.path)

	return store.with_lock(path, function(file)
		local previous = file:read()

		if previous ~= nil then
			parse_snapshot(previous, server)
		end
		local sessions, live = live_sessions()
		if #sessions == 0 then
			return { message = "No sessions; previous snapshot kept" }
		end
		if
			previous
			and previous.instance_id ~= server.instance_id
			and previous.restored_instance_id ~= server.instance_id
		then
			for _, session in ipairs(previous.sessions) do
				assert(
					live_id(previous, session, live),
					"Restore Workspace before saving on this restarted server, or use a different snapshot path"
				)
			end
		end
		local snapshot = {
			version = 1,
			host_id = server.host_id,
			instance_id = server.instance_id,
			saved_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			selected_session = ctx.session_id,
			sessions = {},
		}
		local remembered = remembered_commands(previous)
		for _, session in ipairs(sessions) do
			local saved = capture_session(session.session_id, server, remembered)
			table.insert(snapshot.sessions, saved)
		end
		local _, final = live_sessions()
		for id in pairs(live) do
			assert(final[id], "Sessions changed while saving; try again")
		end
		for id in pairs(final) do
			assert(live[id], "Sessions changed while saving; try again")
		end
		parse_snapshot(snapshot, server)
		file:write(snapshot)

		return { saved = #snapshot.sessions, message = "Workspace saved" }
	end)
end

local function map_blocks(target, old, new)
	assert(type(new) == "table" and #old == #new, "Rex returned an unexpected block count")
	for i, id in ipairs(old) do
		target[id] = new[i]
	end
end

local function populate(created, plan)
	local sid = created.session_id
	call("session.attach", { session_id = sid })
	local mapping = { session_id = sid, windows = {}, blocks = {} }
	assert(#(created.initial_windows or {}) == #plan.windows, "Rex returned an unexpected window count")
	for i, window in ipairs(plan.windows) do
		local actual, saved = created.initial_windows[i], window.saved
		mapping.windows[saved.id] = actual.window_id
		if not window.placeholder then
			map_blocks(mapping.blocks, window.tiled.ids, actual.block_ids)
		end
		for _, layer in ipairs(window.floats) do
			local added = call("session.new_layer", {
				session_id = sid,
				window_id = actual.window_id,
				focus = false,
				bounds = layer.bounds,
				layout = layer.layout,
			})
			map_blocks(mapping.blocks, layer.ids, added.block_ids)
		end
		if window.placeholder and #window.floats > 0 then
			call("block.close", { session_id = sid, block_id = actual.block_ids[1] })
		end
		if saved.focused and mapping.blocks[saved.focused] then
			call("session.focus_block", { session_id = sid, block_id = mapping.blocks[saved.focused] })
		end
		if saved.zoomed and mapping.blocks[saved.zoomed] then
			call("session.zoom_block", { session_id = sid, block_id = mapping.blocks[saved.zoomed], zoom = true })
		end
	end
	for _, block in ipairs(plan.detached) do
		mapping.blocks[block.id] = call("session.new_block", {
			session_id = sid,
			flavor = block.spec.flavor,
			label = block.spec.label,
			options = block.spec.options,
		}).block_id
	end
	return mapping
end

local function restore_session(file, snapshot, plan)
	local created
	local previous = snapshot.restored[plan.id]
	local ok, result = pcall(function()
		created = call("session.create", {
			label = plan.label,
			initial_windows = plan.initial_windows,
		})
		local mapping = populate(created, plan)
		local window = mapping.windows[plan.active_window]

		if window then
			call("session.focus_window", { session_id = created.session_id, window_id = window })
		end

		snapshot.restored[plan.id] = mapping
		file:write(snapshot)

		return mapping
	end)

	if ok then
		return result
	end

	snapshot.restored[plan.id] = previous

	if created then
		local _, cleanup = rex.call("session.destroy", { session_id = created.session_id })

		if cleanup then
			result = tostring(result) .. "; could not remove partial session " .. created.session_id .. ": " .. cleanup
		end
	end

	return nil, result
end

function M.restore(ctx, args)
	local path, server = state(args.path)

	return store.with_lock(path, function(file)
		local snapshot = assert(file:read(), "No workspace snapshot; use Save Workspace first")
		local plans = parse_snapshot(snapshot, server)
		local _, live = live_sessions()
		local report = { created = 0, skipped = 0, would_create = 0, errors = {} }
		local selected
		for _, plan in ipairs(plans) do
			local existing = live_id(snapshot, plan, live)
			if existing then
				report.skipped = report.skipped + 1
			elseif args.dry_run then
				report.would_create = report.would_create + 1
			else
				local mapping, err = restore_session(file, snapshot, plan)

				if mapping then
					report.created = report.created + 1

					if plan.id == snapshot.selected_session then
						selected = { session_id = mapping.session_id, window_id = mapping.windows[plan.active_window] }
					end
				else
					table.insert(report.errors, plan.label .. ": " .. tostring(err))
				end
			end
		end
		if not args.dry_run and #report.errors == 0 then
			snapshot.restored_instance_id = server.instance_id
			file:write(snapshot)
		end
		if #report.errors > 0 then
			error("Workspace restore incomplete: " .. table.concat(report.errors, "; "), 0)
		end
		if selected and ctx.origin == "palette" then
			rex.client.queue("session.select", selected)
		end
		return report
	end)
end

return M
