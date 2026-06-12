return {
	{
		"assistcontrol/readline.nvim",
		keys = {
			{
				"<M-f>",
				function()
					require("readline").forward_word()
				end,
				mode = "c",
				noremap = true,
				silent = true,
			},
			{
				"<M-b>",
				function()
					require("readline").backward_word()
				end,
				mode = "c",
				noremap = true,
				silent = true,
			},
			{
				"<C-a>",
				function()
					require("readline").beginning_of_line()
				end,
				mode = "c",
				noremap = true,
				silent = true,
			},
			{
				"<C-e>",
				function()
					require("readline").end_of_line()
				end,
				mode = "c",
				noremap = true,
				silent = true,
			},
			{
				"<M-d>",
				function()
					require("readline").kill_word()
				end,
				mode = "c",
				noremap = true,
				silent = true,
			},
			{
				"<M-BS>",
				function()
					require("readline").backward_kill_word()
				end,
				mode = "c",
				noremap = true,
				silent = true,
			},
			{
				"<C-w>",
				function()
					require("readline").unix_word_rubout()
				end,
				mode = "c",
				noremap = true,
				silent = true,
			},
			-- {
			--     '<C-k>',
			--     function() require('readline').kill_line() end,
			--     mode = 'c',
			--     noremap = true,
			--     silent = true
			-- },
			{
				"<C-u>",
				function()
					require("readline").backward_kill_line()
				end,
				mode = "c",
				noremap = true,
				silent = true,
			},
		},
	},
}
