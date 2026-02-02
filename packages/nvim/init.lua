-- Example Neovim configuration
-- This will be symlinked to ~/.config/nvim/init.lua (Unix)
-- or ~/AppData/Local/nvim/init.lua (Windows) via dotter

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true

-- Leader key
vim.g.mapleader = " "

-- Basic keymaps
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })

print("Neovim config loaded!")
