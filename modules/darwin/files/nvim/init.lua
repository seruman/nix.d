-- Options (set before lazy.nvim so plugins see correct state at load time)
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.number = true
vim.o.showtabline = 2
vim.o.laststatus = 3
vim.o.mouse = "a"
vim.o.clipboard = "unnamed"
vim.o.signcolumn = "yes"
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.switchbuf = table.concat({ "useopen", "usetab", "newtab" }, ",")
vim.o.cursorline = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitkeep = "screen"
vim.o.timeout = true
vim.o.timeoutlen = 300

vim.o.background = "light"
vim.cmd("colorscheme seruzen")

vim.g.loaded_matchit = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Write" })
vim.keymap.set("n", "<leader>nh", "<cmd>nohl<CR>", { desc = "Clear highlights" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Move to next search match and center screen" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Move to previous search match and center screen" })
vim.keymap.set("n", "*", "*N", { desc = "Highlight without jumping forward" })
vim.keymap.set("t", "<leader><esc>", "<c-\\><c-n>", { desc = "Switch to normal mode in terminal buffer" })
vim.keymap.set("n", "<leader>bd", "<cmd>bd<CR>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>!bd", "<cmd>bd!<CR>", { desc = "Delete buffer (force)" })
vim.keymap.set("n", "<A-j>", "<Cmd>resize -2<CR>", { desc = "Resize split down" })
vim.keymap.set("n", "<A-k>", "<Cmd>resize +2<CR>", { desc = "Resize split up" })
vim.keymap.set("n", "<A-l>", "<Cmd>vertical resize -2<CR>", { desc = "Resize split right" })
vim.keymap.set("n", "<A-h>", "<Cmd>vertical resize +2<CR>", { desc = "Resize split left" })
vim.keymap.set("n", "gs", "<Cmd>vertical wincmd f<CR>", { desc = "Open file under cursor in vertical split" })

local yank_current_filepath = function()
	local fpath = vim.fn.expand("%")
	vim.fn.setreg("+", fpath)
end

local yank_current_absolute_filepath = function()
	local fpath = vim.fn.expand("%:p")
	vim.fn.setreg("+", fpath)
end

vim.keymap.set("n", "<leader><C-g>p", yank_current_filepath, { desc = "Yank current file path to clipboard" })
vim.keymap.set("n", "<leader><C-g>P", yank_current_absolute_filepath, { desc = "Yank current absolute file path to clipboard" })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{ import = "seruman/plugins" },
		{ import = "seruman/plugins.lsp" },
	},
	change_detection = {
		enabled = false,
		notify = false,
	},
})

require("seruman.commands.gist").setup()

local AugroupCursorLine = vim.api.nvim_create_augroup("CursorLine", { clear = true })
vim.api.nvim_create_autocmd("WinEnter", {
	group = AugroupCursorLine,
	callback = function()
		vim.wo.cursorline = true
	end,
})
vim.api.nvim_create_autocmd("WinLeave", {
	group = AugroupCursorLine,
	callback = function()
		vim.wo.cursorline = false
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	group = vim.api.nvim_create_augroup("UserVimResized", { clear = true }),
	callback = function()
		vim.cmd.wincmd("=")
	end,
})
