return {
	{
		"ibhagwan/fzf-lua",
		event = "VeryLazy",
		config = function()
			local fzflua = require("fzf-lua")

			---@type string[]?
			local img_previewer
			for _, v in ipairs({
				{ cmd = "chafa", args = { "{file}", "--format=symbols" } },
				{ cmd = "viu", args = { "-b" } },
			}) do
				if vim.fn.executable(v.cmd) == 1 then
					img_previewer = vim.list_extend({ v.cmd }, v.args)
					break
				end
			end

			local troubleactions = require("trouble.sources.fzf").actions
			fzflua.setup({
				"default-title",
				-- fzf_colors = true,
				fzf_opts = {
					["--no-scrollbar"] = true,
				},
				hls = { title = "PmenuSel" },
				grep = { RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH },
				defaults = {
					actions = {
						["ctrl-r"] = troubleactions.open,
					},
				},
				files = {
					prompt = "Files> ",
					-- Use FZF_DEFAULT_COMMAND to keep the default behavior.
					cmd = vim.env.FZF_DEFAULT_COMMAND,
				},
				winopts = {
					preview = {
						vertical = "up:60%",
						layout = "flex",
						wrap = true,
						title = false,
						scrollbar = "float",
						delay = 50,
					},
					border = "single",
					backdrop = 97,
				},
				lsp = {
					code_actions = {
						prompt = "Code Actions> ",
						async_or_timeout = 5000,
						winopts = {
							height = 0.3,
						},
					},
				},
				previewers = {
					builtin = {
						extensions = {
							["png"] = img_previewer,
							["jpg"] = img_previewer,
							["jpeg"] = img_previewer,
							["gif"] = img_previewer,
							["webp"] = img_previewer,
						},
					},
				},
			})

			vim.keymap.set("n", "<leader>ff", function()
				require("fzf-lua").files()
			end, { desc = "Files" })
			vim.keymap.set("n", "<leader>fcf", function()
				require("fzf-lua").files({
					cwd = vim.fn.expand("%:p:h"),
				})
			end, { desc = "Files in current buffer's directory" })
			vim.keymap.set("n", "<leader>fg", function()
				require("fzf-lua").git_files()
			end, { desc = "Git files" })
			vim.keymap.set("n", "<leader>fb", function()
				require("fzf-lua").buffers()
			end, { desc = "Buffers" })
			vim.keymap.set("n", "<leader>frb", function()
				require("fzf-lua").lgrep_curbuf()
			end, { desc = "Grep current buffer" })
			vim.keymap.set("n", "<leader>frg", function()
				require("fzf-lua").live_grep_native()
			end, { desc = "Live grep" })
			vim.keymap.set("n", "<leader>frr", function()
				require("fzf-lua").resume()
			end, { desc = "Resume last command/query" })
			vim.keymap.set("n", "<leader>fh/", function()
				require("fzf-lua").search_history()
			end, { desc = "Search history" })
			vim.keymap.set("n", "<leader>fh:", function()
				require("fzf-lua").command_history()
			end, { desc = "Command history" })
			vim.keymap.set("n", "<leader>fc", function()
				require("fzf-lua").commands()
			end, { desc = "Commands" })

			vim.keymap.set("i", "<c-x><c-l>a", function()
				require("fzf-lua").complete_line()
			end, { desc = "Complete line (all buffers)" })

			vim.keymap.set("i", "<c-x><c-l>b", function()
				require("fzf-lua").complete_bline()
			end, { desc = "Complete line (current buffer)" })

			vim.keymap.set("n", "<leader>ft", function()
				local fzf = require("fzf-lua")
				fzf.grep({
					prompt = "TODO> ",
					search = [[TODO(\(.+?\))?:]],
					no_esc = true,
					no_header_i = true,
					no_header = true,
				})
			end, { desc = "Find TODOs" })

			vim.keymap.set("n", "<leader>fn", function()
				require("fzf-lua").grep({
					prompt = "NOTE> ",
					search = [[NOTE(\(.+?\))?:]],
					no_esc = true,
					no_header_i = true,
					no_header = true,
				})
			end, { desc = "Find NOTEs" })

			local function search_go_tests()
				return require("fzf-lua").fzf_exec("listests --vimgrep ./...", {
					prompt = "Go Tests> ",
					file_icons = true,
					color_icons = true,
					actions = require("fzf-lua").defaults.actions.files,
					previewer = "builtin",
				})
			end

			local function search_go_tests_in_current_file()
				local current_file = vim.fn.expand("%:p")
				if current_file == "" then
					vim.notify("No file is currently open.", vim.log.levels.WARN)
					return
				end
				return require("fzf-lua").fzf_exec("listests --vimgrep " .. vim.fn.shellescape(current_file), {
					prompt = "Go Tests in Current File> ",
					file_icons = true,
					color_icons = true,
					actions = require("fzf-lua").defaults.actions.files,
					previewer = "builtin",
				})
			end

			vim.api.nvim_create_user_command("FzfGoTests", search_go_tests, { desc = "Fuzzy Go Tests" })
			vim.api.nvim_create_user_command(
				"FzfGoTestsCurrentFile",
				search_go_tests_in_current_file,
				{ desc = "Fuzzy Go Tests in Current File" }
			)

			vim.keymap.set("n", "<leader>fut", "<cmd>FzfGoTests<CR>", { desc = "Fuzzy Go Tests", silent = true })
			vim.keymap.set(
				"n",
				"<leader>fuc",
				"<cmd>FzfGoTestsCurrentFile<CR>",
				{ desc = "Fuzzy Go Tests (current file)", silent = true }
			)
		end,
	},
}
