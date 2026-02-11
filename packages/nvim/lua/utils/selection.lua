local M = {}

function M.get_selection_range()
    local mode = vim.api.nvim_get_mode().mode
    local start_line, end_line
    
    if mode == "v" or mode == "V" or mode == "\22" then -- \22 == <C-v>
        local start_pos = vim.fn.getpos("v")
        local end_pos = vim.api.nvim_win_get_cursor(0)
        start_line = start_pos[2]
        end_line = end_pos[1]
        
        if start_line > end_line then
            start_line, end_line = end_line, start_line
        end
        
        return {
            start_line = start_line,
            end_line = end_line,
            mode = mode
        }
    else
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        return {
            start_line = cursor_pos[1],
            end_line = cursor_pos[1],
            mode = mode
        }
    end
end

function M.get_current_position()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    return {
        line = cursor_pos[1],
        col = cursor_pos[2]
    }
end

function M.is_visual_mode()
    local mode = vim.api.nvim_get_mode().mode
    return mode == "v" or mode == "V" or mode == "\22"
end

return M