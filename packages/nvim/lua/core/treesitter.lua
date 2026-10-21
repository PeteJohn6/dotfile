local M = {}

function M.setup()
    local bundle = vim.fn.stdpath("data") .. "/treesitter-bundle"
    if vim.fn.isdirectory(bundle) == 1 then
        vim.opt.runtimepath:prepend(bundle)
    end

    local function attach(buf)
        if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= "" then
            return
        end
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        if not lang or #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0 then
            return
        end
        local ok, err = pcall(vim.treesitter.start, buf, lang)
        if not ok then
            vim.notify_once("Treesitter: " .. tostring(err), vim.log.levels.WARN)
            return
        end
        vim.keymap.set({ "n", "x" }, "<C-space>", function()
            vim.treesitter.select("parent", vim.v.count1)
        end, { buffer = buf, desc = "Expand syntax node selection" })
        vim.keymap.set("x", "<BS>", function()
            vim.treesitter.select("child", vim.v.count1)
        end, { buffer = buf, desc = "Shrink syntax node selection" })
    end

    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("dotfile_treesitter", { clear = true }),
        callback = function(event)
            attach(event.buf)
        end,
    })
    -- Setup follows lazy.nvim so its runtimepath reset cannot remove the bundle.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        attach(buf)
    end
end

return M
