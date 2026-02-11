local M = {}
local selection = require("utils.selection")
local path = require("utils.path")

function M.get_selected_location()
    if not path.validate_current_file() then
        return
    end

    local path_part = path.get_current_relative_path()
    local range = selection.get_selection_range()
    
    local location = (range.start_line == range.end_line)
        and string.format("%s:%d", path_part, range.start_line)
        or string.format("%s:%d-%d", path_part, range.start_line, range.end_line)

    -- 尝试写系统剪贴板与备用选择缓冲区
    pcall(vim.fn.setreg, "+", location)
    pcall(vim.fn.setreg, "*", location)

    if selection.is_visual_mode() then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
    end

    vim.notify("Location copied: " .. location, vim.log.levels.INFO)
    return location
end

-- ========= Plugin Configuration =========
local ai_assistant = {
    name = "ai-assistant",
    dir = vim.fn.stdpath("config"),
    lazy = true,
    keys = {
        { "<leader>al", function() M.get_selected_location() end, desc = "Get selected code location", mode = { "v" } },
    },
}

return { ai_assistant }
