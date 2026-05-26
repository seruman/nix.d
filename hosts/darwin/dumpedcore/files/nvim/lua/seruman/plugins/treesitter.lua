return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "TSUpdate",
				callback = function()
					local parsers = require("nvim-treesitter.parsers")
					parsers.just = {
						install_info = {
							url = "https://github.com/IndianBoy42/tree-sitter-just",
							files = { "src/parser.c", "src/scanner.c" },
							branch = "main",
						},
					}
					parsers.dotenv = {
						install_info = {
							url = "https://github.com/pnx/tree-sitter-dotenv",
							branch = "main",
							files = { "src/parser.c", "src/scanner.c" },
						},
					}
					parsers.txtar = {
						install_info = {
							url = "https://github.com/FollowTheProcess/tree-sitter-txtar",
							branch = "main",
							files = { "src/parser.c" },
						},
					}
				end,
			})

			require("nvim-treesitter").install({
				"c",
				"go",
				"gomod",
				"gowork",
				"lua",
				"vim",
				"vimdoc",
				"bash",
				"typescript",
				"tsx",
				"javascript",
				"json",
				"comment",
				"css",
				"diff",
				"dockerfile",
				"git_config",
				"git_rebase",
				"gitcommit",
				"gitignore",
				"html",
				"ini",
				"make",
				"python",
				"query",
				"sql",
				"terraform",
				"toml",
				"yaml",
				"zig",
				"http",
				"markdown",
				"markdown_inline",
				"templ",
				"java",
				"groovy",
			})

			-- Enable treesitter highlighting and indentation for all filetypes
			-- that have a parser installed.
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
				callback = function(ev)
					if vim.bo[ev.buf].buftype ~= "" then
						return
					end

					local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
					if not pcall(vim.treesitter.start, ev.buf, lang) then
						return
					end
					vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})

			-- NOTE: Incremental selection (<CR>/<BS>/<Tab>) was removed in the
			-- treesitter main branch rewrite. Use visual mode + textobjects instead.
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = {
					lookahead = true,
				},
				move = {
					set_jumps = true,
				},
			})

			local select = require("nvim-treesitter-textobjects.select")
			local move = require("nvim-treesitter-textobjects.move")
			local swap = require("nvim-treesitter-textobjects.swap")

			local select_maps = {
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
				["iB"] = "@block.inner",
				["aB"] = "@block.outer",
				["aT"] = "@structtag.outer",
				-- NOTE(selman): collides with `at` for HTML tags.
				["agstt"] = "@go.subtest_call.outer",
				["agstn"] = "@go.subtest_call.name.outer",
			}
			for key, capture in pairs(select_maps) do
				vim.keymap.set({ "x", "o" }, key, function()
					select.select_textobject(capture, "textobjects")
				end, { desc = "TS select " .. capture })
			end

			local move_maps = {
				goto_next_start = {
					["]]"] = "@function.outer",
					["]t"] = "@go.subtest_call.outer",
				},
				goto_next_end = {
					["]["] = "@function.outer",
				},
				goto_previous_start = {
					["[["] = "@function.outer",
					["[t"] = "@go.subtest_call.outer",
				},
				goto_previous_end = {
					["[]"] = "@function.outer",
				},
			}
			for method, maps in pairs(move_maps) do
				for key, capture in pairs(maps) do
					vim.keymap.set({ "n", "x", "o" }, key, function()
						move[method](capture, "textobjects")
					end, { desc = "TS " .. method .. " " .. capture })
				end
			end

			vim.keymap.set("n", "<leader>a", function()
				swap.swap_next("@parameter.inner")
			end, { desc = "TS swap next parameter" })
			vim.keymap.set("n", "<leader>A", function()
				swap.swap_previous("@parameter.inner")
			end, { desc = "TS swap previous parameter" })
		end,
	},
	{
		"vrischmann/tree-sitter-templ",
	},
	{
		"bezhermoso/tree-sitter-ghostty",
		build = "make nvim_install",
	},
}
