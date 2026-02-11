local lsp_keymaps = {
    { mode = "n",          key = "gR",         action = "<cmd>Telescope lsp_references<CR>",       desc = "Show LSP references" },
    { mode = "n",          key = "gD",         action = vim.lsp.buf.declaration,                   desc = "Go to declaration" },
    { mode = "n",          key = "gd",         action = "<cmd>Telescope lsp_definitions<CR>",      desc = "Show LSP definitions" },
    { mode = "n",          key = "gi",         action = "<cmd>Telescope lsp_implementations<CR>",  desc = "Show LSP implementations" },
    { mode = "n",          key = "gp",         action = "<cmd>Telescope lsp_type_definitions<CR>", desc = "Show LSP type definitions" },
    { mode = { "n", "v" }, key = "<leader>ca", action = vim.lsp.buf.code_action,                   desc = "See available code actions" },
    { mode = "n",          key = "<leader>rn", action = vim.lsp.buf.rename,                        desc = "Smart rename" },
    {
        mode = "n",
        key = "<leader>D",
        action = "<cmd>Telescope diagnostics bufnr=0<CR>",
        desc = "Show buffer diagnostics",
    },
    { mode = "n", key = "<leader>d",  action = vim.diagnostic.open_float, desc = "Show line diagnostics" },
    { mode = "n", key = "[d",         action = vim.diagnostic.goto_prev,  desc = "Go to previous diagnostic" },
    { mode = "n", key = "]d",         action = vim.diagnostic.goto_next,  desc = "Go to next diagnostic" },
    { mode = "n", key = "K",          action = vim.lsp.buf.hover,         desc = "Show documentation for what is under cursor" },
    { mode = "n", key = "<leader>rs", action = ":LspRestart<CR>",         desc = "Restart LSP" },
}

local languagePluginConfig = {
    base = {
        treesitter = { "toml", "yaml", "json" },
        formatter = {
            prettier = {
                filetypes = { "json" },
            },
            yamlfmt = {
                env = {
                    YAMLFIX_SEQUENCE_STYLE = "block_style",
                },
            },
            "taplo"
        },
        linter = {
            "yamllint",
            "jsonlint",
        },
        lsp = {
            ["json-lsp"] = {
                mason_lspconfig_name = "jsonls"
            },
            ["yaml-language-server"] = {
                mason_lspconfig_name = "yamlls"
            },
            taplo = {
                filetypes = { "toml" },
            }
        }
    },
    -- Web/React Development
    web = {
        treesitter = { "html", "css", "javascript", "typescript", "tsx", "json" },
        formatter = {
            prettier = {
                filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact", "css", "html", "json" },
            }
        },
        linter = {
            eslint_d = {
                filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
            },
        },
        lsp = {
            ["html-lsp"] = {
                mason_lspconfig_name = "html"
            },
            ["tailwindcss-language-server"] = {
                mason_lspconfig_name = "tailwindcss",
            },
            ["typescript-language-server"] = {
                mason_lspconfig_name = "ts_ls",
            },
            ["css-lsp"] = {
                mason_lspconfig_name = "cssls",
                filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
            },
            ["emmet-ls"] = {
                mason_lspconfig_name = "emmet_ls",
                filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
            },
        }
    },

    -- Lua/Neovim Development
    lua = {
        treesitter = { "lua", "vim", "vimdoc" },
        formatter = { "stylua" },
        linter = { "luac" },
        lsp = {
            ["lua-language-server"] = {
                mason_lspconfig_name = "lua_ls",
                filetypes = { "lua" },
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" },
                        },
                        completion = {
                            callSnippet = "Replace",
                        },
                    },
                },
            }
        },
    },

    -- solidity development
    solidity = {
        treesitter = { "solidity" },
        -- formatter = {
        --     ["vscode-solidity-server"] = {
        --         filetypes = { "solidity" }
        --     }
        -- },
        linter = {
            solhint = {
                filetypes = { "solidity" }
            }
        },
        lsp = {
            ["nomicfoundation-solidity-language-server"] = {
                mason_lspconfig_name = "solidity_ls_nomicfoundation"
            }
        },
    },

    -- rust development
    rust = {
        treesitter = { "rust", "toml" },

        formatter = {
            rustfmt = {
                filetypes = { "rust" },
            },
        },

        -- prefer rust-analyzer’s built-in checks; keep this only if you wire external linters
        linter = {
            clippy = {
                filetypes = { "rust" },
            },
        },

        lsp = {
            rust_analyzer = {
                mason_lspconfig_name = "rust_analyzer",
                settings = {
                    ["rust-analyzer"] = {
                        cargo = { allFeatures = true },
                        checkOnSave = { command = "clippy" },
                        procMacro = { enable = true },
                    },
                },
            },
            -- optional: TOML for Cargo.toml
            taplo = {
                mason_lspconfig_name = "taplo",
            },
        },
    }
}

local treesitter = {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    dependencies = {
        "windwp/nvim-ts-autotag",
    },
    opts = function()
        local ensure_installed = {}
        -- Extract treesitter parsers from language configs
        for _, lang_config in pairs(languagePluginConfig) do
            if lang_config.treesitter then
                for k, v in pairs(lang_config.treesitter) do
                    if type(k) == "number" then
                        table.insert(ensure_installed, v)
                    else
                        table.insert(ensure_installed, k)
                    end
                end
            end
        end
        return {
            highlight = {
                enable = true,
            },
            -- Install parsers synchronously (only applied to `ensure_installed`)
            sync_install = false,
            -- ensure these language parsers are installed
            ensure_installed = ensure_installed,

            -- Automatically install missing parsers when entering buffer
            -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
            auto_install = true,

            -- enable indentation
            indent = { enable = true },

            -- enable autotagging (w/ nvim-ts-autotag plugin)
            autotag = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<C-space>",
                    node_incremental = "<C-space>",
                    scope_incremental = false,
                    node_decremental = "<bs>",
                },
            },
        }
    end,
}

local mason = {
    "williamboman/mason.nvim",
    opts = {
        ui = {
            icons = {
                package_installed = "✓",
                package_pending = "➜",
                package_uninstalled = "✗",
            },
        },
    }
}

local mason_install_package = function(package_list)
    local mason_registry = require("mason-registry")
    for _, server_name in pairs(package_list) do
        if not mason_registry.is_installed(server_name) and
            mason_registry.has_package(server_name) then
            vim.defer_fn(function()
                mason_registry.get_package(server_name):install()
            end, 0)
        end
    end
end

-- linter
local linter = {
    "mfussenegger/nvim-lint",
    dependencies = {
        mason,
    },
    event = { "BufReadPre", "BufNewFile" },
    keys = {
        {
            "<leader>l",
            function()
                require("lint").try_lint()
            end,
            mode = { "n" },
            desc = "Trigger linting for current file",
        },
    },
    config = function()
        local lint = require("lint")
        local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            group = lint_augroup,
            callback = function()
                require("lint").try_lint()
            end,
        })

        local lint_progress = function()
            local linters = lint.get_running()
            if #linters == 0 then
                return "󰦕"
            end
            return "󱉶 " .. table.concat(linters, ", ")
        end

        vim.api.nvim_create_user_command("LintProgress", function()
            print(lint_progress())
        end, {})

        -- extract linters from language configs
        local needed_linter = {}
        local linters_by_ft = {}
        -- Extract treesitter parsers from language configs
        -- transform linter config to nvim-lint format
        -- filetype: linter with { languages } => language with { linters }

        --    eslint_d = {
        --        filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
        --    },
        for _, lang_config in pairs(languagePluginConfig) do
            if lang_config.linter then
                for k, v in pairs(lang_config.linter) do
                    if type(k) == "number" then
                        table.insert(needed_linter, v)
                    else
                        table.insert(needed_linter, k)
                        if v.filetypes then
                            for _, ft in pairs(v.filetypes) do
                                if linters_by_ft[ft] then
                                    table.insert(linters_by_ft[ft], k)
                                end
                            end
                        end
                    end
                end
            end
        end
        mason_install_package(needed_linter)
        lint.linters_by_ft = linters_by_ft
    end,
}

-- format
local formatter = {
    "stevearc/conform.nvim",
    dependencies = {
        mason,
    },
    event = { "BufReadPre", "BufNewFile" },
    keys = {
        {
            "<leader>mp",
            function()
                require("conform").format({
                    lsp_fallback = true,
                    async = false,
                    timeout_ms = 1000,
                })
            end,
            mode = { "n", "v" },
            desc = "Format file or range (in visual mode)",
        },
    },
    config = function()
        local needed_formatter = {}
        local formatter_by_ft = {}
        -- Extract treesitter parsers from language configs
        -- transform formatter config to conform format
        -- filetype: formatter with { languages } => language with { formatters }
        --    prettier = {
        --        filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact", "css", "html", "json" },
        --    },

        for _, lang_config in pairs(languagePluginConfig) do
            if lang_config.formatter then
                for formatter, conf in pairs(lang_config.formatter) do
                    if type(formatter) == "number" then
                        table.insert(needed_formatter, conf)
                    else
                        table.insert(needed_formatter, formatter)
                        if conf.filetypes then
                            for _, ft in pairs(conf.filetypes) do
                                if not formatter_by_ft[ft] then
                                    formatter_by_ft[ft] = {}
                                end
                                table.insert(formatter_by_ft[ft], formatter)
                            end
                        end
                    end
                end
            end
        end
        mason_install_package(needed_formatter)

        local conform = require("conform")
        conform.setup({
            formatters_by_ft = formatter_by_ft,
            default_format_opts = {
                lsp_format = "fallback",
            },
            format_on_save = {
                lsp_fallback = true,
                timeout_ms = 1000,
            },
            format_after_save = {
                enabled = true,
                timeout_ms = 1000,
            },
        })
    end,
}

-- language server protocol
local lsp = {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        { "antosha417/nvim-lsp-file-operations", config = true },
        { "folke/neodev.nvim",                   opts = {} },
        {
            "williamboman/mason-lspconfig.nvim", -- mason-lspconfig.nvim closes some gaps that exist between "mason.nvim" and "lspconfig".
            dependencies = { mason }
        },
        "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        local ensure = {}

        for _, lang in pairs(languagePluginConfig or {}) do
            if not lang.lsp then goto CONTINUE end
            for name, conf in pairs(lang.lsp) do
                if type(name) == "number" then
                    -- 仅字符串形式
                    table.insert(ensure, conf)
                else
                    local server = conf.mason_lspconfig_name or name
                    table.insert(ensure, server)

                    local cfg = vim.tbl_deep_extend("force", { capabilities = capabilities }, conf)
                    cfg.mason_lspconfig_name = nil
                    vim.lsp.config(server, cfg) -- 定义配置，启用时自动用到
                end
            end
            ::CONTINUE::
        end

        require("mason").setup({})
        require("mason-lspconfig").setup({
            ensure_installed = ensure,
            automatic_enable = true, -- 自动 vim.lsp.enable() 已安装的 server
        })

        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                -- Apply all keymaps from the table
                local keymap = vim.keymap -- for conciseness
                for _, mapping in pairs(lsp_keymaps) do
                    local opts = { buffer = ev.buf, silent = true, desc = mapping.desc }
                    keymap.set(mapping.mode, mapping.key, mapping.action, opts)
                end
            end,
        })

        -- Change the Diagnostic symbols in the sign column (gutter)
        local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        end
    end,
}

local lsp_progress = {
    "linrongbin16/lsp-progress.nvim",
    dependencies = {
        "nvim-lualine/lualine.nvim", -- for status line integrations
    },
    opts = function()
        local ok, lualine = pcall(require, "lualine")
        if not ok then
            return {}
        end

        local lsp_progress_opts = {
            series_format = function(title, message, percentage, done)
                local builder = {}
                local has_title = false
                local has_message = false
                if title and title ~= "" then
                    table.insert(builder, title)
                    has_title = true
                end
                if message and message ~= "" then
                    table.insert(builder, message)
                    has_message = true
                end
                if percentage and (has_title or has_message) then
                    table.insert(builder, string.format("(%.0f%%)", percentage))
                end
                if done and (has_title or has_message) then
                    table.insert(builder, "- done")
                end
                -- return table.concat(builder, " ")
                return { msg = table.concat(builder, " "), done = done }
            end,
            client_format = function(client_name, spinner, series_messages)
                if #series_messages == 0 then
                    return nil
                end
                local builder = {}
                local done = true
                for _, series in ipairs(series_messages) do
                    if not series.done then
                        done = false
                    end
                    table.insert(builder, series.msg)
                end
                if done then
                    -- replace the check mark once done
                    spinner = "%#LspProgressMessageCompleted#✓%*"
                end
                return "[" .. client_name .. "] " .. spinner .. " " .. table.concat(builder, ", ")
            end,
        }

        local lsp_progress_status = require("lualine.component"):extend()

        function lsp_progress_status:init(options)
            lsp_progress_status.super.init(self, options)

            vim.api.nvim_create_augroup("lualine_lsp_progress_augroup", { clear = true })
            vim.api.nvim_create_autocmd("User", {
                group = "lualine_lsp_progress_augroup",
                pattern = "LspProgressStatusUpdated",
                callback = require("lualine").refresh,
            })
        end

        function lsp_progress_status:update_status()
            return require("lsp-progress").progress()
        end

        local lua_conf = lualine.get_config()

        if lua_conf.sections.lualine_c then
            table.insert(lua_conf.sections.lualine_c, lsp_progress_status)
        else
            lua_conf.sections.lualine_c = { lsp_progress_status }
        end
        lualine.setup(lua_conf)

        return lsp_progress_opts
    end,
}

local trouble = {
    "folke/trouble.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "folke/todo-comments.nvim",
    },
    opts = {
        focus = true,
    },
    cmd = "Trouble",
    keys = {
        { "<leader>xx", "<cmd>Trouble toggle <CR>",            desc = "Open/close trouble list" },
        { "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>", desc = "Open trouble workspace diagnostics" },
        {
            "<leader>xd",
            "<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
            desc = "Open trouble document diagnostics",
        },
        { "<leader>xq", "<cmd>Trouble quickfix toggle<CR>", desc = "Open trouble quickfix list" },
        { "<leader>xl", "<cmd>Trouble loclist toggle<CR>",  desc = "Open trouble location list" },
        { "<leader>xt", "<cmd>Trouble todo toggle<CR>",     desc = "Open todos in trouble" },
    },
}


return { treesitter, linter, formatter, lsp, lsp_progress, trouble }
