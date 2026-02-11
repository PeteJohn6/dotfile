local M = {}

function M.get_buffer_file_path(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(buf)
    return file_path ~= "" and file_path or nil
end

function M.get_current_file_path()
    return M.get_buffer_file_path()
end

function M.to_relative_path(file_path)
    if not file_path or file_path == "" then
        return nil
    end
    
    local uv = vim.loop
    local real_file = (uv.fs_realpath(file_path) or file_path)
    local cwd = vim.fn.getcwd(-1, -1)
    local real_cwd = (uv.fs_realpath(cwd) or cwd)

    local rel = vim.fn.fnamemodify(real_file, ":.")
    if rel == real_file then
        rel = vim.fn.fnamemodify(real_file, ":t")
    end
    return rel
end

function M.format_display_path(relative_path)
    if not relative_path then
        return nil
    end
    return (relative_path == "." and "." or ("./" .. relative_path))
end

function M.get_current_relative_path()
    local file_path = M.get_current_file_path()
    if not file_path then
        return nil
    end
    
    local rel_path = M.to_relative_path(file_path)
    return M.format_display_path(rel_path)
end

function M.validate_current_file()
    local file_path = M.get_current_file_path()
    if not file_path then
        vim.notify("No file associated with current buffer", vim.log.levels.WARN)
        return false
    end
    return true
end

return M