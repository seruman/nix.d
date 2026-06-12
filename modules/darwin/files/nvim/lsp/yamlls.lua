local schemas = {}
local env_project_schemas = vim.env.YAMLLS_PROJECT_SCHEMAS
if env_project_schemas ~= nil then
	local ok, decoded = pcall(vim.json.decode, env_project_schemas)
	if ok then
		for _, schema in ipairs(decoded) do
			for uri, matcher in pairs(schema) do
				schemas[uri] = matcher
			end
		end
	end
end

return {
	settings = {
		yaml = {
			redhat = { telemetry = { enable = false } },
			keyOrdering = false,
			schemas = schemas,
		},
	},
}
