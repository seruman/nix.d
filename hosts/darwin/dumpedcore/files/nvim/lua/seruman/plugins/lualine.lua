return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"SmiteshP/nvim-navic",
		},
		opts = function()
			local function format_mode(mode)
				local parts = vim.split(mode, "-", { plain = true })
				local m = ""
				for _, v in pairs(parts) do
					m = m .. v:sub(1, 1)
				end
				return m
			end

			return {
				options = {
					-- theme = "seruzen",
					icons_enabled = false,
					component_separators = { left = "|", right = "|" },
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = {
						{ "mode", fmt = format_mode },
					},
					lualine_c = {
						{ "navic" },
					},
				},
			}
		end,
	},
}
