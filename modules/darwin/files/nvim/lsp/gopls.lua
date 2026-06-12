local tags = "-tags=" .. table.concat({
	"integration",
	"selman",
	"testmain",
}, ",")

return {
	settings = {
		gopls = {
			env = { GOFLAGS = tags },
			buildFlags = { tags },

			gofumpt = true,
			["local"] = table.concat({
				"github.com/seruman",
				vim.env.GOPLS_LOCAL,
			}, ","),

			analyses = {
				nilness = true,
				-- NOTE(selman): Tired of warnings for `if err := ...; err != nil`.
				shadow = false,
				unusedparams = true,
				unusedwrite = true,
				unusedvariable = true,
				useany = true,
			},
			staticcheck = true,

			codelenses = {
				generate = true,
				test = true,
				tidy = true,
				vendor = true,
			},
			semanticTokens = false,
		},
	},
}
