return {
	on_attach = function(client, _)
		if client.name == "ruff" then
			-- Disable hover in favor of Pyright
			client.server_capabilities.hoverProvider = false
		end
	end,
	init_options = {
		settings = {
			lineLength = 120,
		},
	},
}
