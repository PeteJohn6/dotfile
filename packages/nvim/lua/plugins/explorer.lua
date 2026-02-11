local neo_tree = {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    config = function()
        vim.g.neo_tree_remove_legacy_commands = 1

        local neotree = require("neo-tree")

        neotree.setup({
            close_if_last_window = true,
            popup_border_style = "rounded",
            window = {
                position = "float",
                reveal = true,
                popup = {
                    size = { height = "80%", width = "30%" },
                    position = "50%",
                },
                mappings = {
                    ["p"] = {
                        "toggle_preview",
                        config = {
                            use_float = true,
                            use_image_nvim = true,
                            use_snacks_image = true,
                            neo_tree_preview = 1,
                        },
                    },
                    ["<C-h>"] = "focus_preview",
                    ["<C-k>"] = { "scroll_preview", config = { direction = 10 } },
                    ["<C-j>"] = { "scroll_preview", config = { direction = -10 } },
                },
            },
            filesystem = {

                filtered_items = {
                    visible = true, -- when true, they will just be displayed differently than normal items
                },
                bind_to_cwd = true,
                follow_current_file = { enabled = true, leave_dirs_open = true },
                use_libuv_file_watcher = true,
            },
            buffers = {
                follow_current_file = { enabled = true },
            },
            git_status = {
                window = {
                    position = "float",
                },
            },
        })

        local keymap = vim.keymap

        keymap.set("n", "<leader>ee", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })
        keymap.set("n", "<leader>eb", "<cmd>Neotree buffers<CR>", { desc = "Toggle buffers explorer" })
        keymap.set("n", "<leader>eg", "<cmd>Neotree git_status<CR>", { desc = "Toggle git status explorer" })
    end,
}

return { neo_tree }
