local colors_name = "seruzen"
vim.g.colors_name = colors_name -- Required when defining a colorscheme

local lush = require("lush")
local hsluv = lush.hsluv -- Human-friendly hsl
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

-- Generate the lush specs using the generator util
local generator = require("zenbones.specs")
local base_specs = generator.generate(palette, bg, generator.get_global_config(colors_name, bg))

-- Optionally extend specs using Lush
local specs = lush.extends({ base_specs }).with(function()
	return {
		MatchParen({ gui = "bold" }),
		BlinkCmpKind({ fg = palette.bg, bg = palette.fg }),
	}
end)

-- Pass the specs to lush to apply
lush(specs)
