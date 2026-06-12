local M = {}

local gist_content_from_args = function(args)
	local bufnr = vim.api.nvim_get_current_buf()

	if args.range == 0 then
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		return table.concat(lines, "\n")
	end

	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	if args.line1 == start_pos[2] and args.line2 == end_pos[2] then
		local region = vim.fn.getregion(start_pos, end_pos, { type = vim.fn.visualmode() })
		return table.concat(region, "\n")
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, args.line1 - 1, args.line2, false)
	return table.concat(lines, "\n")
end

local gist_command_cwd = function()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		return vim.fn.getcwd()
	end

	return vim.fn.fnamemodify(path, ":p:h")
end

local gist_repo_host = function(cwd)
	local result = vim.system(
		{ "gh", "repo", "view", "--json", "url", "--jq", '.url | split("/")[2]' },
		{ text = true, cwd = cwd }
	):wait()
	if result.code ~= 0 then
		return nil
	end

	local host = vim.trim(result.stdout or "")
	if host == "" then
		return nil
	end

	return host
end

function M.setup()
	vim.api.nvim_create_user_command("Gist", function(args)
		if vim.fn.executable("gh") ~= 1 then
			vim.notify("gh executable not found in PATH.", vim.log.levels.ERROR)
			return
		end

		local content = gist_content_from_args(args)
		if content == "" then
			vim.notify("Nothing to publish.", vim.log.levels.WARN)
			return
		end

		local filename = vim.fn.expand("%:t")
		if filename == "" then
			filename = "buffer.txt"
		end

		local cwd = gist_command_cwd()
		local host = gist_repo_host(cwd)
		local command = { "gh", "gist", "create", "--filename", filename }
		if not args.bang then
			table.insert(command, "--web")
		end
		table.insert(command, "-")

		local options = {
			text = true,
			stdin = content,
			cwd = cwd,
		}

		if host and host ~= "" then
			options.env = { GH_HOST = host }
		end

		local result = vim.system(command, options):wait()

		if result.code ~= 0 then
			local error_message = vim.trim(result.stderr or "")
			if error_message == "" then
				error_message = "Failed to create gist."
			end
			vim.notify(error_message, vim.log.levels.ERROR)
			return
		end

		local url = vim.trim(result.stdout or "")
		if url ~= "" then
			vim.fn.setreg("+", url)
			vim.notify("Gist created: " .. url, vim.log.levels.INFO)
			return
		end

		vim.notify("Gist created.", vim.log.levels.INFO)
	end, {
		desc = "Create gist from current buffer or visual selection (:Gist! skips browser)",
		range = true,
		bang = true,
	})
end

return M
