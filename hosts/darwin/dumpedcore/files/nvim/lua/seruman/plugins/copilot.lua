return {
	{
		"github/copilot.vim",
		init = function()
			vim.g.copilot_no_tab_map = true
			vim.g.copilot_assume_mapped = true
			vim.g.copilot_tab_fallback = ""
		end,
		config = function()
			vim.keymap.set("i", "<C-T>", 'copilot#Accept("<CR>")', {
				silent = true,
				expr = true,
				script = true,
				replace_keycodes = false,
				desc = "Copilot accept suggestion",
			})

			vim.keymap.set("i", "<C-C><C-]>", "copilot#Next()", {
				silent = true,
				expr = true,
				script = true,
				replace_keycodes = false,
				desc = "Copilot next suggestion",
			})

			vim.keymap.set("i", "<C-C><C-[>", "copilot#Previous()", {
				silent = true,
				expr = true,
				replace_keycodes = false,
				desc = "Copilot previous suggestion",
			})
		end,
	},

}
