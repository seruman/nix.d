local store = {}
local function command(argv)
	local result = assert(rex.exec(argv, { timeout = 5 }))

	if not result.ok then
		error(argv[1] .. " failed: " .. result.stderr, 0)
	end

	return result.stdout
end

function store.with_lock(path, operation)
	assert(
		type(path) == "string" and path:sub(1, 1) == "/" and not path:find("%z"),
		"workspace store path must be an absolute string without NUL bytes"
	)
	local parent, name = path:match("^(.*)/([^/]+)$")
	assert(parent and name ~= "." and name ~= "..", "workspace store path must name a file")
	if parent == "" then
		parent = "/"
	end
	local handle = {}
	local lock = path .. ".lock"

	function handle:read()
		local file, err = io.open(path, "rb")
		if not file then
			local missing = assert(rex.exec({ "test", "!", "-e", path, "-a", "!", "-L", path }, { timeout = 5 }))
			if missing.ok then
				return nil
			end
			error("cannot read " .. path .. ": " .. tostring(err), 0)
		end
		local text, read_err = file:read("*a")
		local closed, close_err = file:close()
		assert(text, "cannot read " .. path .. ": " .. tostring(read_err))
		assert(closed, "cannot close " .. path .. ": " .. tostring(close_err))
		local value, decode_err = rex.json.decode(text)
		assert(value ~= nil, "invalid workspace JSON in " .. path .. ": " .. (decode_err or "null snapshot"))

		return value
	end

	function handle:write(value)
		local text = assert(rex.json.encode(value, { indent = true }))
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

	command({ "mkdir", "-p", "-m", "700", parent })
	local acquired, acquire_err = pcall(command, { "mkdir", "-m", "700", lock })

	if not acquired then
		error(
			"Cannot acquire "
				.. lock
				.. ": "
				.. tostring(acquire_err)
				.. "; remove a stale lock only after confirming no save/restore is running",
			0
		)
	end

	local ok, result = pcall(operation, handle)
	local released, release_err = pcall(command, { "rmdir", lock })

	if not released then
		local message = "Cannot release " .. lock .. ": " .. tostring(release_err)

		if not ok then
			message = tostring(result) .. "; " .. message
		end

		error(message, 0)
	end

	if not ok then
		error(result, 0)
	end

	return result
end

return store
