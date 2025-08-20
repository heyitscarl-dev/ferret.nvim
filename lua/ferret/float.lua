local M = {}

--- @class ferret.OpenFloatOpts
--- @field 

M.open = function()
    M.open_inline()
end

M.open_inline = function()
    local buf = vim.api.nvim_create_buf(false, true)
    local lines = { "🔍 Nothing to see here" }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, #line)
    end

    local height = #lines

    local win = vim.api.nvim_open_win(buf, false, {
        relative = "cursor",
        row = -1,
        col = 0,
        width = width + 2,
        height = height,
        style = "minimal",
        border = false
    })

    local group = vim.api.nvim_create_augroup("HoverFloatAutoclose", { clear = true })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave", "WinLeave" }, {
        group = group,
        once = true,
        callback = function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
        end
    })
end

return M
