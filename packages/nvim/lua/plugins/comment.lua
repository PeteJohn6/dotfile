local comment = {
	"numToStr/Comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	config = function()
		local C = require("Comment")
		local api = require("Comment.api")
		local tscc = require("ts_context_commentstring.integrations.comment_nvim")
		local selection = require("utils.selection")

		C.setup({
			mappings = { basic = false, extra = false }, -- 关闭 gc/gco/gcO/gcA
			pre_hook = tscc.create_pre_hook(),
			padding = true,
			sticky = true,
			-- ignore   = "^$",
		})

		local map = vim.keymap.set

		map("x", "<leader>cl", function()
			local range = selection.get_selection_range()
			api.toggle.linewise(range.mode)
		end, { desc = "Toggle line comments for selection" })

		map("x", "<leader>cb", function()
			local range = selection.get_selection_range()
			api.toggle.blockwise(range.mode)
		end, { desc = "Toggle block comments for selection" })

		-- 带标签前缀助手
		local function tag(where, s)
			local f = ({
				eol = api.insert.linewise.eol,
				above = api.insert.linewise.above,
				below = api.insert.linewise.below,
			})[where]
			if not f then
				return
			end
			f() -- 进入插入点
			vim.schedule(function()
				local keys = vim.api.nvim_replace_termcodes(s .. ": ", true, false, true)
				vim.api.nvim_feedkeys(keys, "i", false)
			end)
		end

		map("n", "<leader>cOt", function()
			tag("above", "TODO")
		end, { desc = "EOL TODO" })
		map("n", "<leader>cOf", function()
			tag("above", "FIXUP")
		end, { desc = "EOL FIXUP" })
		map("n", "<leader>cOn", function()
			tag("above", "NOTE")
		end, { desc = "EOL NOTE" })
		map("n", "<leader>cOc", function()
			tag("above", "COPILOT_TODO")
		end, { desc = "EOL COPILOT_TODO" })
		map("n", "<leader>cOq", function()
			tag("above", "COPILOT_QUESTION")
		end, { desc = "EOL COPILOT_QUESTION" })
	end,
}

local todo = {
	"folke/todo-comments.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { "nvim-lua/plenary.nvim" },
	-- todo: refactor to integrate with telescope
	keys = {
		{
			"]t",
			function()
				todo_comments.jump_next()
			end,
			desc = "Next todo comment",
		},
		{
			"[t",
			function()
				todo_comments.jump_prev()
			end,
			desc = "Previous todo comment",
		},
	},
}

return { comment, todo }
