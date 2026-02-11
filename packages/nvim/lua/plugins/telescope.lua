local telescope_config = {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = vim.fn.has("win32") == 1 and
                "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release" or "make",
        },
        "nvim-tree/nvim-web-devicons",
    },
    keys = {
        { "<leader>ff", "<cmd>Telescope find_files<cr>",  desc = "Fuzzy find files in cwd" },
        { "<leader>fr", "<cmd>Telescope oldfiles<cr>",    desc = "Fuzzy find recent files in cwd" },
        { "<leader>fs", "<cmd>Telescope live_grep<cr>",   desc = "Find string in cwd" },
        { "<leader>fc", "<cmd>Telescope grep_string<cr>", desc = "Find string under cursor in cwd" },
        { "<leader>fb", "<cmd>Telescope buffers<cr>",     desc = "Find buffers" },
        { "<leader>ft", "<cmd>TodoTelescope<cr>",         desc = "Find todos" },
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        local transform_mod = require("telescope.actions.mt").transform_mod

        -- local trouble = require("trouble")
        -- local trouble_telescope = require("trouble.sources.telescope")

        -- or create your custom action
        -- TODO: it's not working here
        local custom_actions = transform_mod({
            open_trouble_qflist = function(prompt_bufnr)
                trouble.toggle("quickfix")
            end,
        })

        telescope.setup({
            defaults = {
                path_display = { "smart" },
                mappings = {
                    i = {
                        ["<C-k>"] = actions.move_selection_previous, -- move to prev result
                        ["<C-j>"] = actions.move_selection_next,     -- move to next result
                        ["<C-q>"] = actions.send_selected_to_qflist + custom_actions.open_trouble_qflist,
                        -- ["<C-t>"] = trouble_telescope.open,
                    },
                },
            },
        })

        -- 安全加载 fzf 扩展，如果失败则使用默认排序器
        local has_fzf, _ = pcall(telescope.load_extension, "fzf")
        if not has_fzf then
          vim.notify("FZF extension not available, using default sorter", vim.log.levels.WARN)
        end
    end,
}

return { telescope_config }
