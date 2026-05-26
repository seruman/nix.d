vim.filetype.add({
	pattern = {
		[vim.fn.expand("~") .. "/.config/massren/temp/.*"] = "massren",
		[".env.*"] = "dotenv",
	},

	extension = {
		jenkinsfile = "groovy",
		txtar = "txtar",
	},
})
