local whichKey = {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 500
	end,
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
	},
}

local legendary = {
	"mrjones2014/legendary.nvim",
	priority = 10000,
	lazy = false,
	opts = {
		extension = {
			lazy_nvim = {
				auto_register = true,
			},
			which_key = {
				auto_register = false,
				mappings = {},
				opts = {},
				do_binding = true,
				use_groups = true,
			},
			nvim_tree = true,
		},
	},
}

return { whichKey, legendary }
