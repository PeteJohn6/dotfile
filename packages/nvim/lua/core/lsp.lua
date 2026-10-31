local M = {}

M.servers = {
    "clangd",
    "cssls",
    "emmet_ls",
    "html",
    "jsonls",
    "lua_ls",
    "rust_analyzer",
    "solidity_ls_nomicfoundation",
    "tailwindcss",
    "taplo",
    "ts_ls",
    "yamlls",
}

local keymaps = {
    { "gR", "<cmd>Telescope lsp_references<CR>", "Show LSP references" },
    { "gD", vim.lsp.buf.declaration, "Go to declaration" },
    { "gd", "<cmd>Telescope lsp_definitions<CR>", "Show LSP definitions" },
    { "gi", "<cmd>Telescope lsp_implementations<CR>", "Show LSP implementations" },
    { "gp", "<cmd>Telescope lsp_type_definitions<CR>", "Show LSP type definitions" },
    { "<leader>ca", vim.lsp.buf.code_action, "See available code actions", mode = { "n", "v" } },
    { "<leader>rn", vim.lsp.buf.rename, "Smart rename" },
    { "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", "Show buffer diagnostics" },
    { "<leader>d", vim.diagnostic.open_float, "Show line diagnostics" },
    { "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Go to previous diagnostic" },
    { "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Go to next diagnostic" },
    { "K", vim.lsp.buf.hover, "Show documentation for what is under cursor" },
    { "<leader>rs", "<cmd>lsp restart<CR>", "Restart LSP" },
}

function M.setup()
    vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
    })

    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(ev)
            for _, mapping in ipairs(keymaps) do
                vim.keymap.set(mapping.mode or "n", mapping[1], mapping[2], {
                    buf = ev.buf,
                    silent = true,
                    desc = mapping[3],
                })
            end
        end,
    })

    vim.diagnostic.config({
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = " ",
                [vim.diagnostic.severity.WARN] = " ",
                [vim.diagnostic.severity.HINT] = "󰠠 ",
                [vim.diagnostic.severity.INFO] = " ",
            },
        },
        jump = {
            on_jump = function(diagnostic, bufnr)
                if diagnostic then
                    vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
                end
            end,
        },
    })
end

return M
