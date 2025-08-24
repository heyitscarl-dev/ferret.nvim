local M = {}

--- @class ferret.FloatingWindow
--- @field type "inline"|"large"
--- @field buffer integer
--- @field window integer

--- @type ferret.FloatingWindow?
local current = nil

--- @param selection ferret.VisualSelection: used to determine reference point / anchor
--- @param lines string[]
M.open = function(selection, lines)
    if current and current.type == "inline" then
        local old_lines = vim.api.nvim_buf_get_lines(current.buffer, 0, -1, false)
        M.close()
        current = M.open_large(old_lines)
        return
    elseif current then
        return
    end

    local anchor_line = (selection.spos and selection.spos.line) or vim.fn.getpos(".")[2]
    local anchor_col = vim.fn.indent(anchor_line) + 1   -- convert from 0-based to 1-based
    local anchor = { line = anchor_line, column = anchor_col }

    if selection.type == "buffer" then
        current = M.open_large(lines)
    else
        current = M.open_inline(require("ferret.visual").get_screenpos(0, anchor) or {}, lines)
    end
end

--- @param lines string[]
local function open_buffer(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, #line)
    end

    local height = #lines

    return buf, width, height
end

--- @param buffer integer
--- @param width integer
--- @param height integer
--- @param anchor { line: integer, column: integer }
--- @return ferret.FloatingWindow
local function open_inline(buffer, width, height, anchor)
    local window = vim.api.nvim_open_win(buffer, false, {
        relative = "editor",
        row = anchor.line - 2,
        col = anchor.column - 1,
        width = width + 2,
        height = height,
        style = "minimal",
    })

    return {
        type = "inline",
        buffer = buffer,
        window = window
    }
end

--- @param buffer integer
local function open_large(buffer)
    local window = vim.api.nvim_open_win(buffer, true, {
        split = "right",
        win = -1,
    })

    return {
        type = "large",
        buffer = buffer,
        window = window
    }
end

--- @param anchor { line: integer, column: integer }
--- @param lines string[]
--- @return ferret.FloatingWindow
M.open_inline = function(anchor, lines)
    local buffer, width, height = open_buffer(lines)
    local window = open_inline(buffer, width, height, anchor)

    vim.api.nvim_create_autocmd({
        "ModeChanged",
        "CursorMoved",
        "CursorMovedI"
    }, {
        buffer = 0,
        once = true,
        callback = function()
            if current and current.window == window then
                M.close()
            end
        end
    })

    return window
end

--- @param lines string[]
--- @return ferret.FloatingWindow
M.open_large = function(lines)
    local buffer, _, _ = open_buffer(lines)

    vim.api.nvim_create_autocmd({
        "WinClosed"
    }, {
        buffer = buffer,
        once = true,
        callback = M.close
    })

    return open_large(buffer)
end

M.close = function()
    if not current then
        return false
    end

    if not vim.api.nvim_win_is_valid(current.window) then
        return false
    end

    vim.api.nvim_win_close(current.window, true)
    current = nil
    return true
end

return M
