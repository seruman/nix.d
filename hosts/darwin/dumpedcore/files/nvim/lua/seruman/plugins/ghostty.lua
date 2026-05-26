return vim.env.GHOSTTY_RESOURCES_DIR
		and {
			{
				"ghostty",
				dir = vim.env.GHOSTTY_RESOURCES_DIR .. "/../nvim/site",
				lazy = true,
				ft = { "ghostty" },
			},
		}
	or {}
