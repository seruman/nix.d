return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "saghen/blink.cmp" },
			{ "j-hui/fidget.nvim", config = true },
		},
		config = function()
			vim.lsp.enable({
				"gopls",
				"lua_ls",
				"ty",
				"ruff",
				"rust_analyzer",
				"yamlls",
				"typos_lsp",
				"clangd",
				"protobuf-language-server",
				"fish-lsp",
				"bashls",
				"ts_ls",
				"jsonls",
				"terraformls",
				"zls",
				"tailwindcss",
				"nim_langserver",
				"taplo",
				"html",
				"biome",
				"jsonnet_ls",
				"sourcekit",
			})

			vim.diagnostic.config({
				virtual_text = false,
				signs = true,
				update_in_insert = false,
				underline = true,
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
				callback = function(ev)
					local function fzfopts(o)
						return vim.tbl_extend("force", {
							jump1 = true,
							ignore_current_line = true,
						}, o or {})
					end

					local function opts(o)
						return vim.tbl_extend("keep", { buffer = ev.buf }, o or {})
					end

					vim.keymap.set("n", "gd", function()
						require("fzf-lua").lsp_definitions(fzfopts())
					end, opts({ desc = "LSP definitions" }))
					vim.keymap.set("n", "gD", function()
						require("fzf-lua").lsp_definitions(fzfopts({
							jump1_action = require("fzf-lua.actions").file_vsplit,
						}))
					end, opts({ desc = "LSP definitions (vsplit)" }))
					vim.keymap.set("n", "gT", function()
						require("fzf-lua").lsp_definitions(fzfopts({
							jump1_action = require("fzf-lua.actions").file_tabedit,
						}))
					end, opts({ desc = "LSP definitions (new tab)" }))

					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts({ desc = "LSP hover" }))
					-- TODO: <C-k> in insert mode collides with blink.cmp's select_and_accept
					vim.keymap.set(
						{ "n", "i" },
						"<C-k>",
						vim.lsp.buf.signature_help,
						opts({ desc = "LSP signature help" })
					)

					vim.keymap.set("n", "gi", function()
						require("fzf-lua").lsp_implementations(fzfopts())
					end, opts({ desc = "LSP implementations" }))
					vim.keymap.set("n", "gr", function()
						require("fzf-lua").lsp_references(fzfopts())
					end, opts({ desc = "LSP references" }))

					vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts({ desc = "LSP rename" }))
					vim.keymap.set(
						{ "n", "v" },
						"<leader>ca",
						vim.lsp.buf.code_action,
						opts({ desc = "LSP code action" })
					)
					vim.keymap.set({ "n", "v" }, "<leader>cl", vim.lsp.codelens.run, opts({ desc = "LSP code lens" }))

					vim.keymap.set(
						{ "n", "v" },
						"<space>f",
						"<Cmd>Format<CR>",
						opts({ desc = "Conform format with LSP fallback", silent = true })
					)

					vim.keymap.set("n", "<leader>dd", function()
						require("fzf-lua").diagnostics(fzfopts({ bufnr = 0 }))
					end, opts({ desc = "LSP diagnostics (document)" }))
					vim.keymap.set("n", "<leader>dw", function()
						require("fzf-lua").diagnostics(fzfopts())
					end, opts({ desc = "LSP diagnostics (workspace)" }))
					vim.keymap.set("n", "<space>d", function()
						vim.diagnostic.open_float({
							border = "rounded",
							header = "",
							close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
							source = true,
						})
					end, opts({ desc = "LSP diagnostic under cursor (popup)" }))

					vim.keymap.set("n", "<leader>ic", function()
						require("fzf-lua").lsp_incoming_calls(fzfopts())
					end, opts({ desc = "LSP incoming calls" }))
					vim.keymap.set("n", "<leader>oc", function()
						require("fzf-lua").lsp_outgoing_calls(fzfopts())
					end, opts({ desc = "LSP outgoing calls" }))

					vim.keymap.set("n", "<leader>sd", function()
						require("fzf-lua").lsp_document_symbols(fzfopts())
					end, opts({ desc = "LSP symbols (document)" }))
					vim.keymap.set("n", "<leader>sw", function()
						require("fzf-lua").lsp_live_workspace_symbols(fzfopts())
					end, opts({ desc = "LSP symbols (workspace)" }))
					vim.keymap.set("n", "<leader>td", function()
						require("fzf-lua").lsp_typedefs(fzfopts())
					end, opts({ desc = "LSP typedefs" }))

					vim.keymap.set("n", "<space>lr", function()
						vim.cmd.LspRestart()
					end, opts({ desc = "LSP restart" }))
					vim.keymap.set("n", "<space>*", function()
						vim.lsp.buf.document_highlight()
					end, opts({ desc = "LSP document highlight" }))
					vim.keymap.set("n", "<space>nh", function()
						vim.lsp.buf.clear_references()
					end, opts({ desc = "LSP clear references" }))
				end,
			})
		end,
	},
}
