return {
	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, function(name, path)
			return name == "vite.config.ts" and vim.fn.executable(path .. "/node_modules/vite-plus/bin/oxfmt") == 1
		end)
		if root then
			on_dir(root)
		end
	end,
	cmd = function(dispatchers, config)
		local wrapper = vim.fs.joinpath(config.root_dir, "node_modules", "vite-plus", "bin", "oxfmt")
		local bin = vim.fn.executable(wrapper) == 1 and wrapper or "oxfmt"
		return vim.lsp.rpc.start({ bin, "--lsp" }, dispatchers)
	end,
	init_options = { settings = { ["fmt.configPath"] = "./vite.config.ts" } },
}
