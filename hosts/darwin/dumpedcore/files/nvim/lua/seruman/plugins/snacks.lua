return {
	{
		"folke/snacks.nvim",
		opts = {
			bigfile = {},
			quickfile = {},
			indent = { enabled = false },
		},
		config = function(_, opts)
			require("snacks").setup(opts)
			vim.api.nvim_create_user_command("IndentEnable", function()
				Snacks.indent.enable()
			end, { desc = "Enable indent guides" })
			vim.api.nvim_create_user_command("IndentDisable", function()
				Snacks.indent.disable()
			end, { desc = "Disable indent guides" })
		end,
	},
}
