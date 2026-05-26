local M = {}

local checksums_file = vim.fn.stdpath("cache") .. "/jdtls/trusted_gradle_checksums.json"
local checksums_dir = vim.fn.fnamemodify(checksums_file, ":h")
local trusted_checksums = {}

function M.init()
	if vim.fn.isdirectory(checksums_dir) ~= 1 then
		vim.fn.mkdir(checksums_dir, "p")
	end

	if vim.fn.filereadable(checksums_file) == 1 then
		local file = io.open(checksums_file, "r")
		if file then
			local content = file:read("*all")
			file:close()
			local ok, decoded = pcall(vim.json.decode, content)
			if ok and type(decoded) == "table" then
				trusted_checksums = decoded
			end
		end
	end

	if not vim.tbl_contains(trusted_checksums, "41c8aa7a337a44af18d8cda0d632ebba469aef34f3041827624ef5c1a4e4419d") then
		table.insert(trusted_checksums, "41c8aa7a337a44af18d8cda0d632ebba469aef34f3041827624ef5c1a4e4419d")
	end

	M.save_checksums()

	return trusted_checksums
end

function M.save_checksums()
	local file = io.open(checksums_file, "w")
	if file then
		file:write(vim.json.encode(trusted_checksums))
		file:close()
	end
end

function M.get_trusted_checksums()
	return trusted_checksums
end

return M
