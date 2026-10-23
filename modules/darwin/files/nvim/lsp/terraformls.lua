return {
	on_init = function(client)
		-- https://github.com/hashicorp/terraform-ls/issues/2094
		client.server_capabilities.semanticTokensProvider = nil
	end,
}
