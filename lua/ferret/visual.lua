local M = {}

--- @class ferret.VisualSelection
--- @field type "char"|"line"|"block"|"buffer"
--- @field spos? { line: integer, column: integer }
--- @field epos? { line: integer, column: integer }
--- @field text string[]

--- @param spos { line: integer, column: integer }
--- @param epos { line: integer, column: integer }
--- @return ferret.VisualSelection
local function get_linewise_visual(spos, epos, lines)
    return {
        type = "line",
        spos = spos,
        epos = epos,
        text = lines
    }
end

--- @param spos { line: integer, column: integer }
--- @param epos { line: integer, column: integer }
--- @return ferret.VisualSelection
local function get_blockwise_visual(spos, epos, lines)
    for i = 1, #lines do
        lines[i] = string.sub(lines[i], spos.column, epos.column)
    end

    return {
        type = "block",
        spos = spos,
        epos = epos,
        text = lines
    }
end


--- @param spos { line: integer, column: integer }
--- @param epos { line: integer, column: integer }
--- @return ferret.VisualSelection
local function get_charwise_visual(spos, epos, lines)
    local scol, ecol = math.min(spos.column, epos.column), math.max(spos.column, epos.column)

    -- if starts and ends on the same line
    if #lines == 1 then
        lines[1] = string.sub(lines[1], scol, ecol)
    else
        lines[1] = string.sub(lines[1], scol)
        lines[#lines] = string.sub(lines[#lines], 1, ecol)
    end

    return {
        type = "char",
        spos = spos,
        epos = epos,
        text = lines
    }
end

--- @return ferret.VisualSelection
local function get_buffer()
    local lines = vim.api.nvim_buf_get_lines(0, 1, -1, false)
    return {
        type = "buffer",
        text = lines
    }
end

--- @return { line: integer, column: integer }, { line: integer, column: integer }
local function get_positions()
    local from = vim.fn.getpos("v")     -- selection start
    local to = vim.fn.getpos(".")     -- selection end (cursor position)

    local aline, bline = from[2], to[2]
    local acol, bcol = from[3], to[3]

    local sline, eline = math.min(aline, bline), math.max(aline, bline)
    local scol, ecol = math.min(acol, bcol), math.max(acol, bcol)

    return { line = sline, column = scol }, { line = eline, column = ecol }
end

M.get = function()
    local mode = vim.fn.mode()
    if not mode:match("[vV\22]") then
        return get_buffer()
    end

    local spos, epos = get_positions()
    local lines = vim.api.nvim_buf_get_lines(0, spos.line - 1, epos.line, false)

    if mode == "V" then
        return get_linewise_visual(spos, epos, lines)
    end

    if mode == "\22" then
        return get_blockwise_visual(spos, epos, lines)
    end

    return get_charwise_visual(spos, epos, lines)
end

--- Line- and column- numbers are absolute. I.e. they refer to line numbers in the buffer.
--- This has to be converted somehow to instead be relative to the editor.
--- @param bufpos { line: integer, column: integer }
--- @return { line: integer, column: integer }?
M.get_screenpos = function(winnr, bufpos)
    local screenpos = vim.fn.screenpos(winnr, bufpos.line, bufpos.column)
    if not screenpos or screenpos.row == 0 then
        return nil
    end

    return { line = screenpos.row, column = screenpos.col }
end

return M
