return {
	{
		"Wansmer/treesj",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("treesj").setup({
				use_default_keymaps = false,
				cursor_behavior = "end",
			})
		end,
		keys = {
			{
				"gJ",
				function()
					require("treesj").join()
				end,
				desc = "Join the object under cursor",
			},
			{
				"gS",
				function()
					require("treesj").split()
				end,
				desc = "Split the object under cursor",
			},
		},
	},
}
