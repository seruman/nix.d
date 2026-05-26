return {
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
				javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				html = { "prettierd", "prettier", stop_after_first = true },
				css = { "prettierd", "prettier", stop_after_first = true },
				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt" },
				go = { "gofumpt", "goimports" },
				python = {
					"ruff_fix",
					"ruff_format",
				},
				templ = { "templ" },
				java = { "palantir_java_format" },
				groovy = { "npm-groovy-lint" },
			},
			formatters = {
				goimports = {
					prepend_args = function(_, _)
						local local_ = table.concat({
							"github.com/seruman",
							vim.env.GOPLS_LOCAL,
						}, ",")

						return {
							"--local",
							local_,
						}
					end,
				},
				ruff_format = {
					append_args = function(_, _)
						return {
							"--line-length",
							"120",
						}
					end,
				},
				palantir_java_format = {
					command = "palantir-java-format",
					args = { "--palantir", "-" },
					range_args = function(_, ctx)
						return {
							"--palantir",
							"--lines",
							ctx.range.start[1] .. ":" .. ctx.range["end"][1],
							"-",
						}
					end,
				},
			},
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				return { timeout_ms = 500, lsp_format = "fallback" }
			end,
		},
		config = function(_, opts)
			require("conform").setup(opts)

			vim.api.nvim_create_user_command("Format", function(args)
				local range = nil
				if args.count ~= -1 then
					local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
					range = {
						start = { args.line1, 0 },
						["end"] = { args.line2, end_line:len() },
					}
				end
				require("conform").format({ async = true, lsp_format = "fallback", range = range })
			end, { range = true })

			vim.api.nvim_create_user_command("FormatDisable", function(args)
				if args.bang then
					vim.b.disable_autoformat = true
				else
					vim.g.disable_autoformat = true
				end
			end, {
				desc = "Disable autoformat-on-save",
				bang = true,
			})
			vim.api.nvim_create_user_command("FormatEnable", function()
				vim.b.disable_autoformat = false
				vim.g.disable_autoformat = false
			end, {
				desc = "Re-enable autoformat-on-save",
			})
		end,
	},
}
