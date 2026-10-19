-- Run from the repository root: lua checks/rex-restore.lua
package.path = "modules/darwin/files/rex/?.lua;" .. package.path
local restore = require("restore")
local created, view
local pane_size = { columns = 100, rows = 30 }

rex = {
	session = {
		list_blocks = function()
			return { blocks = { { block_id = "block-detached", placement = "detached", label = "shell" } } }
		end,
		view = function()
			return view
		end,
		new_layer = function(args)
			created = args
			return { layer_id = "picker" }
		end,
	},
	call = function(_, args)
		if args.method == "title" then
			return { title = "shell" }
		end
		assert(args.method == "size")
		return pane_size
	end,
	layout = {
		block = function(args)
			return args
		end,
	},
}

local function leaf(id, rect)
	return { block_id = id, rect = rect }
end

local function check(name, layout, kind, expected_error)
	created = nil
	-- Current session.view schema: geometry lives in the layout tree,
	-- while blocks contains metadata only. Rectangles are [x, y, w, h].
	view = {
		windows = {
			{
				window_id = "window",
				layers = {
					{
						kind = kind or "tiled",
						bounds = { 0, 0, 1, 1 },
						layout = layout,
						blocks = { { block_id = "anchor" } },
					},
				},
			},
		},
	}
	local ok, result = pcall(restore, { session_id = "session", block_id = "anchor" }, {})
	if expected_error then
		assert(not ok and result == expected_error, name .. ": " .. tostring(result))
		assert(not created)
	else
		assert(ok, name .. ": " .. tostring(result))
		assert(result.layer_id == "picker" and created.window_id == "window")
		assert(created.session_id == "session" and created.focus)
		-- Every successful fixture implies a 100x30 window.
		assert(math.abs(created.bounds.w - 0.95) < 1e-9)
		assert(math.abs(created.bounds.h - (1 + 26 / 30) / 2) < 1e-9)
	end
	print("PASS " .. name)
end

check("single tiled pane", leaf("anchor", { 0, 0, 1, 1 }))
pane_size = { columns = 50, rows = 15 }
check("nested after branch", {
	rect = { 0, 0, 1, 1 },
	split = {
		before = leaf("other", { 0, 0, 0.5, 1 }),
		after = {
			rect = { 0.5, 0, 0.5, 1 },
			split = {
				before = leaf("another", { 0.5, 0, 0.5, 0.5 }),
				after = leaf("anchor", { 0.5, 0.5, 0.5, 0.5 }),
			},
		},
	},
})
pane_size = { columns = 50, rows = 30 }
check("before branch", {
	rect = { 0, 0, 1, 1 },
	split = {
		before = leaf("anchor", { 0, 0, 0.5, 1 }),
		after = leaf("other", { 0.5, 0, 0.5, 1 }),
	},
})
check("floating pane rejected", leaf("anchor", { 0, 0, 1, 1 }), "floating", "Launch the picker from a tiled pane")
check("missing pane rejected", leaf("other", { 0, 0, 1, 1 }), nil, "Launch the picker from a tiled pane")
check("empty layout rejected", nil, nil, "Launch the picker from a tiled pane")
check("zero-sized pane rejected", leaf("anchor", { 0, 0, 0, 1 }), nil, "Launch the picker from a tiled pane")
