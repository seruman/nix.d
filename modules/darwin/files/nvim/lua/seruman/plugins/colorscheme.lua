return {
	{
		"mcchrish/zenbones.nvim",
		dependencies = { "rktjmp/lush.nvim" },
		lazy = true,
		cmd = { "SeruzenCompile" },
		config = function()
			vim.api.nvim_create_user_command("SeruzenCompile", function()
				vim.o.background = "light"
				vim.g.seruzen = { darken_cursor_line = 5 }

				local lush = require("lush")
				local hsluv = lush.hsluv
				local util = require("zenbones.util")
				local bg = vim.o.background

				local p = util.palette_extend({
					bg = hsluv("#f4f0ed"),
					fg = hsluv("#6b5c4d"),
					rose = hsluv("#C65333"),
					leaf = hsluv("#659E69"),
					wood = hsluv("#C29830"),
					water = hsluv("#485F84"),
					blossom = hsluv("#d7898c"),
					sky = hsluv("#83B887"),
				}, bg)

				local palette = vim.tbl_extend("keep", p, {
					bg1 = p.bg.sa(4).da(16),
					bg_bright = p.bg.abs_li(3).sa(6),
					bg_dim = p.bg.abs_da(3).de(12),
					rose1 = p.rose.sa(20).da(16),
					leaf1 = p.leaf.sa(20).da(16),
					wood1 = p.wood.sa(18).da(16),
					water1 = p.water.sa(20).da(16),
					blossom1 = p.blossom.sa(24).da(16),
					sky1 = p.sky.sa(20).da(16),
					fg1 = p.fg.li(22),
				})

				local generator = require("zenbones.specs")
				local base_specs = generator.generate(palette, bg, generator.get_global_config("seruzen", bg))

				local specs = lush.extends({ base_specs }).with(function()
					return {
						MatchParen({ gui = "bold" }),
						BlinkCmpKind({ fg = palette.bg, bg = palette.fg }),
					}
				end)

				local compiled = lush.compile(specs)
				local path = vim.fn.stdpath("config") .. "/colors/seruzen.lua"
				local f = assert(io.open(path, "w"))

				f:write("-- Compiled from colors/seruzen_src.lua — do not edit manually.\n")
				f:write("-- Regenerate with :SeruzenCompile\n\n")
				f:write('vim.g.colors_name = "seruzen"\n\n')

				local groups = {}
				for group, _ in pairs(compiled) do
					table.insert(groups, group)
				end
				table.sort(groups)

				for _, group in ipairs(groups) do
					local attrs = compiled[group]
					f:write(string.format(
						"vim.api.nvim_set_hl(0, %q, %s)\n",
						group,
						vim.inspect(attrs, { newline = " ", indent = "" })
					))
				end

				f:close()
				vim.cmd("colorscheme seruzen")
				vim.notify(string.format("SeruzenCompile: wrote %d groups to %s", #groups, path))
			end, {})
		end,
	},
}
