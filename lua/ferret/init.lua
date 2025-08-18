local M = {}

--- @param text string
local function trim(text)
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- @return string concatenated visual selection
local function get_visual()
    local has_start, start = pcall(vim.fn.getpos, "'<")
    local has_end, end_ = pcall(vim.fn.getpos, "'>")

    if not has_start or not has_end then
        error("Cannot get visual selection if no '< or '> is set.")
    end

    local sline, scol = start[2], start[3]
    local eline, ecol = end_[2], end_[3]

    local lines = vim.api.nvim_buf_get_text(0, sline - 1, scol - 1, eline - 1, ecol, {})
    if #lines > 0 then
        return table.concat(lines, "\n")
    end

    error("Cannot get visual selection if nothing is selected.")
end

--- @return string concatenated buffer contents
local function get_buffer()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    return table.concat(lines, "\n")
end

--- @param command table command to run
local function get_api_key(command)
    local key_out = vim.fn.system(command)
    if vim.v.shell_error ~= 0 then
        error("Could not generate api key. Command failed.")
    end

    local api_key = trim(key_out)
    if api_key == "" then
        error("Could not generate api key. Result was empty.")
    end

    return api_key
end

M.setup = function()
    -- nothing
end

M.ask = function()
    local has_api_key, api_key = pcall(get_api_key, { "pass", "show", "openai/api/chatgpt.nvim" })
    if not has_api_key then
        error("Could not ask AI. Could not generate api key.")
    end

    local has_selection, selection = pcall(get_visual)
    local context = has_selection and selection or get_buffer()
    local fenced = "```\n" .. context .. "\n```"

    local user_prompt = vim.fn.input("Ask AI...")
    if not user_prompt or user_prompt == "" then
        error("Could not ask AI. No prompt provided.")
    end

    local payload = vim.json.encode({
        model = "gpt-5",
        messages = {
            { role = "system", content = "You are a helpful coding assistant." },
            { role = "user", content = ("Selection: \n%s\n\nQuestion: %s"):format(fenced, user_prompt)}
        }
    })

    local response = vim.fn.system({
        "curl", "-sS",
        "-H", "Content-Type: application/json",
        "-H", "Authorization: Bearer " .. api_key,
        "-d", payload,
        "https://api.openai.com/v1/chat/completions"
    })

    if vim.v.shell_error ~= 0 then
        error("Could not ask AI. Could not reach openai.")
    end

    local has_data, data = pcall(vim.json.decode, response)
    if not has_data then
        error("Could not ask AI. Invalid response from openai.")
    end

    local text = data
        and data.choices and data.choices[1]
        and data.choices[1].message and data.choices[1].message.content

    if not text then
        error("Could not ask AI. Response from openai missing content.")
    end

    vim.notify(text, vim.log.levels.INFO)
end

return M
