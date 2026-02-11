vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

-- opt.number = true
-- opt.relativenumber = true
opt.signcolumn = "yes" -- show sign column so that test doesn't shift
-- 自动命令组，用于动态设置行号
vim.api.nvim_create_augroup("DynamicLineNumber", { clear = true })

-- 窗口激活时显示绝对行号和相对行号
vim.api.nvim_create_autocmd("WinEnter", {
	group = "DynamicLineNumber",
	callback = function()
		vim.wo.number = true -- 显示绝对行号
		vim.wo.relativenumber = true -- 显示相对行号
	end,
})

-- 窗口非激活时隐藏行号
vim.api.nvim_create_autocmd("WinLeave", {
	group = "DynamicLineNumber",
	callback = function()
		vim.wo.number = false -- 隐藏绝对行号
		vim.wo.relativenumber = false -- 隐藏相对行号
	end,
})

-- tab & indentation
opt.tabstop = 4 -- 2 space for tabs(prettier default)
opt.shiftwidth = 4 -- 2 space for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

opt.wrap = false

-- search settings
opt.ignorecase = true -- case when searching
opt.smartcase = true -- if you include mixed cse in your search, assumes you want case-sensitive

opt.cursorline = true

-- appearance
opt.termguicolors = true
-- opt.background = "dark"

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
-- opt.clipboard:append("unnamedplus") -- use system clipboard as default regitster

-- split windws
opt.splitright = true
opt.splitbelow = true

-- shell
if vim.loop.os_uname().sysname == "Windows_NT" then
	vim.opt.shell = "pwsh"
	vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
	vim.opt.shellquote = ""
	vim.opt.shellxquote = ""
end
