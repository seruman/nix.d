return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luv types when `vim.uv` is found in the code.
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
}
