---@class MyTermConfig
---@field name_formatter fun(cwd:string, rel:string, id:integer):string|nil
---@field split_default '"h"'|'"v"'|'"horizontal"'|'"vertical"'
---@field refresh_events string[]

local M = {}

-- ========= state =========
local State = {
    next_id = 1,
    id2buf = {}, -- id -> bufnr
    root = nil,
}

-- ========= config =========
local Cfg = {
    name_formatter = nil,
    split_default = 'h',
    refresh_events = { 'BufEnter', 'TermEnter', 'CursorHold', 'FocusGained' },
}

-- ========= utils =========
local A = vim.api
local F = vim.fn
local U = {}

function U.valid_buf(buf) return buf and buf > 0 and A.nvim_buf_is_valid(buf) end

function U.normalize(p) return type(p) == 'string' and p:gsub('\\', '/') or '' end

function U.getcwd_project()
    if State.root and vim.loop.fs_stat(State.root) then return State.root end
    State.root = F.getcwd(-1, -1)
    return State.root
end

function U.relpath(path, base)
    local P = U.normalize(path); if P == '' then return 'unknown' end
    local B = U.normalize(base or U.getcwd_project() or F.getcwd())
    if #B > 0 and P:sub(1, #B) == B then
        local rel = P:sub(#B + 2) -- drop trailing '/'
        return (rel and #rel > 0) and rel or '.'
    end
    local t = F.fnamemodify(P, ':t')
    return (t ~= '' and t) or 'term'
end

local function default_name(_, rel, id)
    return string.format('term[%s] · #%d', rel or 'unknown', id or 0)
end

function U.format_name(cwd, id)
    cwd = (cwd and #cwd > 0) and cwd or (F.getcwd() or 'unknown')
    id = (id and id > 0) and id or 1
    local rel = U.relpath(cwd)
    local f = Cfg.name_formatter or default_name
    local name = f(cwd, rel, id)
    if not name or #name == 0 then name = default_name(cwd, rel, id) end
    return name, rel
end

function U.set_buf_meta(buf, cwd, id)
    if not U.valid_buf(buf) then return end
    vim.b[buf].myterm_id = id
    vim.b[buf].myterm_cwd = cwd
    local name, rel = U.format_name(cwd, id)
    vim.b[buf].myterm_name = name
    pcall(A.nvim_buf_set_name, buf, string.format('myterm://%s#%d', rel, id))
end

local function open_split(dir)
    local d = dir or Cfg.split_default or 'h'
    if d == 'v' or d == 'vertical' then
        vim.cmd('vsplit')
    else
        vim.cmd('split')
    end
end

-- ========= cwd detection =========
local Detect = {}

function Detect.linux(pid)
    local ok, link = pcall(vim.loop.fs_readlink, string.format('/proc/%d/cwd', pid))
    if ok and type(link) == 'string' and #link > 0 then return link end
end

function Detect.darwin(pid)
    local out = F.system({ '/usr/sbin/lsof', '-a', '-p', tostring(pid), '-d', 'cwd', '-Fn' })
    if vim.v.shell_error ~= 0 or type(out) ~= 'string' then return end
    return out:match('\nn([^\n]+)') or out:match('^n([^\n]+)')
end

function Detect.windows(pid)
    local ps = F.system(string.format(
        'powershell -Command "(Get-Process -Id %d).Path | Split-Path -Parent"', pid))
    if vim.v.shell_error == 0 and type(ps) == 'string' and #ps > 0 then
        return ps:gsub('[\r\n]+$', ''):gsub('\\', '/')
    end
    local wmic = F.system(string.format(
        'wmic process where "processid=%d" get ExecutablePath /value', pid))
    if vim.v.shell_error == 0 and type(wmic) == 'string' then
        local p = wmic:match('ExecutablePath=([^\r\n]+)')
        if p and #p > 0 then return F.fnamemodify(p, ':h'):gsub('\\', '/') end
    end
end

local function detect_cwd(buf)
    if not U.valid_buf(buf) then return nil end
    local pid = vim.b[buf].terminal_job_pid
    if not pid then return vim.b[buf].myterm_cwd end

    local sys = (vim.loop.os_uname().sysname or ''):lower()
    local cwd
    if sys:find('linux') then
        cwd = Detect.linux(pid)
    elseif sys:find('darwin') then
        cwd = Detect.darwin(pid)
    elseif sys:find('windows') or F.has('win32') == 1 then
        cwd = Detect.windows(pid)
    end

    if cwd and #cwd > 0 then
        U.set_buf_meta(buf, cwd, vim.b[buf].myterm_id)
    end
    return vim.b[buf].myterm_cwd
end

-- ========= terminal =========
local function set_terminal_keymaps(buf)
    local opt = { noremap = true, silent = true, buffer = buf }
    vim.keymap.set('t', '<C-q>', [[<C-\><C-n>]], opt)
    vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-W>h]], opt)
    vim.keymap.set('t', '<C-j>', [[<C-\><C-n><C-W>j]], opt)
    vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-W>k]], opt)
    vim.keymap.set('t', '<C-l>', [[<C-\><C-n><C-W>l]], opt)
end

local function register_terminal(buf, cwd)
    local id = State.next_id; State.next_id = id + 1

    State.id2buf[id] = buf

    vim.bo[buf].buflisted = false
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].swapfile = false

    U.set_buf_meta(buf, cwd, id)
    set_terminal_keymaps(buf)

    A.nvim_create_autocmd({ 'BufWipeout', 'TermClose' }, {
        buffer = buf,
        once = true,
        callback = function() State.id2buf[id] = nil end,
    })
end

---@param direction '"h"'|'"v"'|'"horizontal"'|'"vertical"'|nil
function M.term_new(direction)
    open_split(direction)
    local buf = A.nvim_create_buf(false, true)
    A.nvim_win_set_buf(0, buf)

    local cwd = F.getcwd()
    F.termopen(vim.o.shell, { cwd = cwd })

    register_terminal(buf, cwd)
    vim.cmd('startinsert')
    return buf
end

-- ========= setup =========
---@param user_cfg MyTermConfig|nil
function M.setup(user_cfg)
    if user_cfg then
        for k, v in pairs(user_cfg) do Cfg[k] = v end
    end
    U.getcwd_project()

    local aug = A.nvim_create_augroup('MyTerm_Autos', { clear = true })

    A.nvim_create_user_command('TermNew', function(opts)
        M.term_new(opts.args ~= '' and opts.args or Cfg.split_default)
    end, { nargs = '?', complete = function() return { 'h', 'v' } end })

    A.nvim_create_autocmd('DirChanged', {
        group = aug,
        callback = function()
            for _, buf in pairs(State.id2buf) do
                if U.valid_buf(buf) then
                    local cur = detect_cwd(buf) or vim.b[buf].myterm_cwd
                    U.set_buf_meta(buf, cur, vim.b[buf].myterm_id)
                end
            end
        end,
    })

    A.nvim_create_autocmd(Cfg.refresh_events, {
        group = aug,
        callback = function(a)
            local b = a.buf
            if U.valid_buf(b) and vim.b[b].myterm_id then detect_cwd(b) end
        end,
    })
end

-- ========= TermSelect =========

function M.get_all_terminal_buffers()
    local term_buffers = {}
    for _, buf in ipairs(A.nvim_list_bufs()) do
        if U.valid_buf(buf) and vim.bo[buf].buftype == 'terminal' then
            table.insert(term_buffers, buf)
        end
    end
    return term_buffers
end

function M.get_git_branch(cwd)
    if not cwd or cwd == '' then return nil end

    local git_dir = cwd .. '/.git'
    if not vim.loop.fs_stat(git_dir) then
        local parent = vim.fn.fnamemodify(cwd, ':h')
        if parent == cwd then return nil end
        return M.get_git_branch(parent)
    end

    local head_file = git_dir .. '/HEAD'
    local stat = vim.loop.fs_stat(head_file)
    if not stat then return nil end

    local handle = vim.loop.fs_open(head_file, 'r', stat.mode)
    if not handle then return nil end

    local content = vim.loop.fs_read(handle, stat.size, 0)
    vim.loop.fs_close(handle)

    if content and content:match('^ref: refs/heads/(.+)') then
        return content:match('^ref: refs/heads/(.+)'):gsub('\n', '')
    end

    return nil
end

function M.get_running_process(buf)
    if not U.valid_buf(buf) then return nil end

    local pid = vim.b[buf].terminal_job_pid
    if not pid then return nil end

    local sys = (vim.loop.os_uname().sysname or ''):lower()

    if sys:find('windows') or F.has('win32') == 1 then
        local cmd = string.format(
            'powershell -Command "Get-WmiObject -Class Win32_Process | Where-Object { $_.ParentProcessId -eq %d } | Select-Object -First 1 | ForEach-Object { $_.Name }"',
            pid
        )
        local result = F.system(cmd)
        if vim.v.shell_error == 0 and result and #result > 0 then
            return result:gsub('[\r\n]+$', '')
        end
    elseif sys:find('linux') then
        local cmd = string.format('ps --ppid %d -o comm= | head -1', pid)
        local result = F.system(cmd)
        if vim.v.shell_error == 0 and result and #result > 0 then
            return result:gsub('[\r\n]+$', '')
        end
    elseif sys:find('darwin') then
        local cmd = string.format('ps -o comm= --ppid %d | head -1', pid)
        local result = F.system(cmd)
        if vim.v.shell_error == 0 and result and #result > 0 then
            return result:gsub('[\r\n]+$', '')
        end
    end

    return nil
end

function M.get_buffer_tail_lines(buf, lines)
    if not U.valid_buf(buf) then return {} end
    lines = lines or 5

    local line_count = A.nvim_buf_line_count(buf)
    local start_line = math.max(0, line_count - lines)

    local ok, content = pcall(A.nvim_buf_get_lines, buf, start_line, line_count, false)
    if not ok then return {} end

    local filtered = {}
    for _, line in ipairs(content) do
        if line and #line > 0 then
            table.insert(filtered, line)
        end
    end

    return filtered
end

function M.display_cur_window(buf)
    if not U.valid_buf(buf) then return false end
    A.nvim_win_set_buf(0, buf)
    if vim.bo[buf].buftype == 'terminal' then
        vim.cmd('startinsert')
    end
    return true
end

function M.goto_buffer(buf)
    if not U.valid_buf(buf) then return false end

    for _, win in ipairs(A.nvim_list_wins()) do
        if A.nvim_win_get_buf(win) == buf then
            A.nvim_set_current_win(win)
            if vim.bo[buf].buftype == 'terminal' then
                vim.cmd('startinsert')
            end
            return true
        end
    end

    vim.cmd('split')
    A.nvim_win_set_buf(0, buf)
    if vim.bo[buf].buftype == 'terminal' then
        vim.cmd('startinsert')
    end
    return true
end

function M.term_select()
    local has_telescope, telescope = pcall(require, 'telescope')
    if not has_telescope then
        vim.notify('Telescope not found', vim.log.levels.ERROR)
        return
    end

    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local previewers = require('telescope.previewers')

    local term_buffers = M.get_all_terminal_buffers()
    if #term_buffers == 0 then
        vim.notify('No terminal buffers found', vim.log.levels.INFO)
        return
    end

    local entries = {}
    for _, buf in ipairs(term_buffers) do
        local cwd = detect_cwd(buf) or vim.b[buf].myterm_cwd or F.getcwd()
        local rel_path = U.relpath(cwd)
        local git_branch = M.get_git_branch(cwd)
        local running_process = M.get_running_process(buf)

        local display_parts = { rel_path }
        if git_branch then
            table.insert(display_parts, string.format('[%s]', git_branch))
        end
        if running_process and running_process ~= 'powershell.exe' and running_process ~= 'bash' and running_process ~= 'zsh' then
            table.insert(display_parts, string.format('(%s)', running_process))
        end

        table.insert(entries, {
            value = buf,
            display = table.concat(display_parts, ' '),
            ordinal = table.concat(display_parts, ' '),
            cwd = cwd,
            rel_path = rel_path,
            git_branch = git_branch,
            running_process = running_process,
            buffer = buf,
        })
    end

    pickers.new({}, {
        prompt_title = 'Terminal Select',
        finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
                return entry
            end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = previewers.new_buffer_previewer({
            title = 'Terminal Preview',
            define_preview = function(self, entry, status)
                local buf_lines = {}

                table.insert(buf_lines, string.format('Path: %s', entry.rel_path))
                if entry.git_branch then
                    table.insert(buf_lines, string.format('Branch: %s', entry.git_branch))
                end
                if entry.running_process then
                    table.insert(buf_lines, string.format('Process: %s', entry.running_process))
                end
                table.insert(buf_lines, string.rep('-', 50))

                local tail_lines = M.get_buffer_tail_lines(entry.buffer, 10)
                for _, line in ipairs(tail_lines) do
                    table.insert(buf_lines, line)
                end

                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, buf_lines)
            end,
        }),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection then
                    M.display_cur_window(selection.buffer)
                end
            end)

            map('i', '<C-g>', function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection then
                    M.goto_buffer(selection.buffer)
                end
            end)

            return true
        end,
    }):find()
end

-- ========= Plugin Configuration =========
local terminal = {
    name = "custom-terminal",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    config = function()
        M.setup({
            split_default = 'h',
            name_formatter = function(cwd, rel, id)
                return string.format("term[%s] · #%d", rel, id)
            end,
            refresh_events = { 'BufEnter', 'TermEnter', 'CursorHold', 'FocusGained' }
        })
    end,
    keys = {
        { "<leader>tf", function() M.term_new('h') end, desc = "Horizontal terminal" },
        { "<leader>tt", function() M.term_new('h') end, desc = "New terminal" },
        { "<leader>tv", function() M.term_new('v') end, desc = "Vertical terminal" },
        { "<leader>ts", function() M.term_new('h') end, desc = "Horizontal terminal" },
        { "<leader>tl", function() M.term_select() end, desc = "Terminal select" },
    },
}

return { terminal }

