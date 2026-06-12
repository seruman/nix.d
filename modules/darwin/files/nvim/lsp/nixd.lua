local default_settings = {
	nixd = {
		formatting = {
			command = { "nixfmt" },
		},
	},
}

local function read_project_settings(start_path)
	local config_path = vim.fs.find(".nixd.json", {
		path = start_path or vim.uv.cwd(),
		upward = true,
	})[1]
	if not config_path then
		return default_settings
	end

	local ok, content = pcall(vim.fn.readfile, config_path)
	if not ok then
		vim.notify("nixd: failed to read " .. config_path, vim.log.levels.WARN)
		return default_settings
	end

	local decoded_ok, decoded = pcall(vim.json.decode, table.concat(content, "\n"))
	if not decoded_ok then
		vim.notify("nixd: failed to parse " .. config_path, vim.log.levels.WARN)
		return default_settings
	end

	return decoded
end

return {
	cmd = { "nixd" },
	filetypes = { "nix" },
	root_markers = { "flake.nix", ".git" },
	settings = read_project_settings(),
}
