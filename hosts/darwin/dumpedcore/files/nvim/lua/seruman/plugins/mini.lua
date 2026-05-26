return {
	{
		"echasnovski/mini.icons",
		lazy = false,
		priority = 100,
		opts = {},
		config = function(_, opts)
			require("mini.icons").setup(opts)
			MiniIcons.mock_nvim_web_devicons()
		end,
	},

	{
		"echasnovski/mini.align",
		keys = {
			{ "ga", mode = { "n", "x" }, desc = "Align" },
			{ "gA", mode = { "n", "x" }, desc = "Align with preview" },
		},
		opts = {},
	},

	{
		"echasnovski/mini.trailspace",
		event = { "BufReadPost", "BufNewFile" },
		keys = {
			{ "<leader>cts", "<cmd>lua MiniTrailspace.trim()<CR>", desc = "Trim trail spaces" },
		},
		opts = { only_in_normal_buffers = true },
	},
}
