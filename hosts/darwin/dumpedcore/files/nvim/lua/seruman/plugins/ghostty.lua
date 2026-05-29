return vim.env.GHOSTTY_RESOURCES_DIR
		and vim.env.TERM_PROGRAM == "ghostty"
		and {
			{
				"ghostty",
				dir = vim.env.GHOSTTY_RESOURCES_DIR .. "/../nvim/site",
				lazy = true,
				ft = { "ghostty" },
			},
		}
	or {}
