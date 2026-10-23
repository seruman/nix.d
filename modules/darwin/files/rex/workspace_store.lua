local store = {}
local unpack = unpack or table.unpack

local function pack(...)
	return { n = select("#", ...), ... }
end

local function command(argv)
	local result, err = rex.exec(argv, { timeout = 5 })
	if not result or not result.ok then
		error(argv[1] .. " failed: " .. tostring(result and result.stderr or err or "rex.exec returned no result"), 0)
	end
	return result.stdout
end

function store.open(path)
	assert(
		type(path) == "string" and path:sub(1, 1) == "/" and not path:find("%z"),
		"workspace store path must be an absolute string without NUL bytes"
	)
	local parent, name = path:match("^(.*)/([^/]+)$")
	assert(parent and name ~= "." and name ~= "..", "workspace store path must name a file")
	if parent == "" then
		parent = "/"
	end
	local handle, held = {}, false
	local lock = path .. ".lock"
	local function require_lock()
		assert(held, "workspace store read/write requires locked(fn)")
	end

	function handle:read()
		require_lock()
		local file, err = io.open(path, "rb")
		if not file then
			local missing, test_err = rex.exec({ "test", "!", "-e", path, "-a", "!", "-L", path }, { timeout = 5 })
			if not missing then
				error("cannot check " .. path .. ": " .. tostring(test_err or "rex.exec returned no result"), 0)
			end
			if missing.ok then
				return nil
			end
			error("cannot read " .. path .. ": " .. tostring(err), 0)
		end
		local text, read_err = file:read("*a")
		local closed, close_err = file:close()
		assert(text, "cannot read " .. path .. ": " .. tostring(read_err))
		assert(closed, "cannot close " .. path .. ": " .. tostring(close_err))
		local ok, value, decode_err = pcall(rex.json.decode, text)
		if not ok or decode_err ~= nil then
			error("invalid JSON in " .. path .. ": " .. tostring(ok and decode_err or value), 0)
		end
		return value
	end

	function handle:write(value)
		require_lock()
		local text, encode_err = rex.json.encode(value, { indent = true })
		assert(type(text) == "string", "cannot encode workspace: " .. tostring(encode_err))
		local temp = command({ "mktemp", parent .. "/.workspace-XXXXXX" }):gsub("\n$", "")
		local file
		local ok, err = pcall(function()
			command({ "chmod", "600", temp })
			local open_err
			file, open_err = io.open(temp, "wb")
			assert(file, open_err)
			assert(file:write(text))
			assert(file:flush())
			local closed, close_err = file:close()
			file = nil
			assert(closed, close_err)
			assert(os.rename(temp, path))
		end)
		if not ok then
			if file then
				pcall(function()
					file:close()
				end)
			end
			local removed, remove_err = os.remove(temp)
			if not removed then
				err = tostring(err) .. "; cannot remove temporary file " .. temp .. ": " .. tostring(remove_err)
			end
			error(err, 0)
		end
	end

	function handle:locked(fn)
		assert(not held, "workspace store lock is non-reentrant: " .. lock)
		command({ "mkdir", "-p", "-m", "700", parent })
		local acquired, acquire_err = pcall(command, { "mkdir", "-m", "700", lock })
		if not acquired then
			error(
				"cannot acquire workspace lock "
					.. lock
					.. ": "
					.. tostring(acquire_err)
					.. "; if it already exists, wait for the other operation. Remove it manually only after"
					.. " confirming no writer is running; stale locks are never removed automatically.",
				0
			)
		end
		held = true
		local result = pack(pcall(fn, handle))
		held = false
		local released, release_err = pcall(command, { "rmdir", lock })
		if not released then
			local prefix = result[1] and "" or (tostring(result[2]) .. "; ")
			error(
				prefix
					.. "cannot release workspace lock "
					.. lock
					.. ": "
					.. tostring(release_err)
					.. "; inspect it and remove manually only when no writer is running",
				0
			)
		end
		if not result[1] then
			error(result[2], 0)
		end
		return unpack(result, 2, result.n)
	end

	return handle
end

return store
