local autopair = {
    "windwp/nvim-autopairs",
    event = { "InsertEnter" },
    dependencies = {
        "hrsh7th/nvim-cmp",
    },
    config = function()
        -- import nvim-autopairs
        local autopairs = require("nvim-autopairs")

        -- configure autopairs
        autopairs.setup({
            check_ts = true,                        -- enable treesitter
            ts_config = {
                lua = { "string" },                 -- don't add pairs in lua string treesitter nodes
                javascript = { "template_string" }, -- don't add pairs in javscript template_string treesitter nodes
                java = false,                       -- don't check treesitter on java
            },
        })

        -- import nvim-autopairs completion functionality
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")

        -- import nvim-cmp plugin (completions plugin)
        local cmp = require("cmp")

        -- make autopairs and completion work together
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
}

local indent_blankline = {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPre", "BufNewFile" },
    main = "ibl",
    opts = {
        indent = { char = "┊" },
    },
}

local substitue = {
    "gbprod/substitute.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
        {
            "s",
            function()
                require("substitute").operator()
            end,
            mode = "n",
            desc = "Substitute with motion",
        },
        {
            "ss",
            function()
                require("substitute").line()
            end,
            mode = "n",
            desc = "Substitute line",
        },
        {
            "S",
            function()
                require("substitute").eol()
            end,
            mode = "n",
            desc = "Substitute to end of line",
        },
        {
            "s",
            function()
                require("substitute").visual()
            end,
            mode = "x",
            desc = "Substitute in visual mode",
        },
    },
}

local surround = {
    "kylechui/nvim-surround",
    event = { "BufReadPre", "BufNewFile" },
    config = true,
}

local sleuth = {
    "tpope/vim-sleuth", -- Automatically detects which indents should be used in the current buffer
}

-- return { sleuth, surround, substitue, autopair, indent_blankline }
return { surround, substitue, autopair, indent_blankline }
