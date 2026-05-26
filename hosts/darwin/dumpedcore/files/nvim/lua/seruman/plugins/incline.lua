return {
	{
		"b0o/incline.nvim",
		dependencies = {
			"SmiteshP/nvim-navic",
		},
		config = function()
			local helpers = require("incline.helpers")
			local devicons = require("nvim-web-devicons")
			require("incline").setup({
				hide = {
					cursorline = false,
					focused_win = true,
					only_win = "count_ignored",
				},
				window = {
					zindex = 30,
					padding = 0,
					margin = {
						vertical = { top = vim.o.laststatus == 3 and 0 or 1, bottom = 0 }, -- shift to overlap window borders
						horizontal = { left = 0, right = 0 },
					},
				},
				render = function(props)
					local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
					if filename == "" then
						filename = "[No Name]"
					end
					local ft_icon, ft_color = devicons.get_icon_color(filename)
					local modified = vim.bo[props.buf].modified
					return {
						ft_icon and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) }
							or "",
						" ",
						{ filename, gui = modified and "bold,italic,underline" or "bold" },
						" ",
						-- guibg = "#44406e",
					}
				end,
			})
		end,
		event = "VeryLazy",
	},
}
