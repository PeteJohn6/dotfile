---@type vim.lsp.Config
return {
    settings = {
        ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
            procMacro = { enable = true },
        },
    },
}
