local M = {}

--- @param text string
local function trim(text)
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Try to get the openai api key via a shell command
--- @param command table command to run
--- @param on_success function to be ran when the command succeeds
--- @param on_error function to be ran when the command fails
--- @return nil
local function get_api_key_via_cmd(command, on_success, on_error)
    vim.system(command, {}, function(out)
        if out.code ~= 0 then
            on_error("Could not generate api key. Command failed with exit code " .. out.code .. ".")
        end

        if not out.stdout or out.stdout == "" then
            on_error("Could not generate api key. Command did not output anything.")
        end

        local api_key = trim(out.stdout)
        if api_key == "" then
            on_error("Could not generate api key. Command yielded whitespace-only api key.")
        end

        on_success(api_key)
    end)
end

M.setup = function(opts)
    -- nothing
end

M.ask = function()
    local selection = require("ferret.visual").get()
    local float = require("ferret.float").open(selection, { "💭 Thinking...", "Request sent to openai." })
    -- get_api_key_via_cmd({ "pass", "show", "openai/api/chatgpt.nvim" }, function(api_key)
    --     vim.schedule(function()
    --         M.ask_with_api_key(api_key)
    --     end)
    -- end, error)
end

M.ask_with_api_key = function(api_key)
    local has_selection, selection = pcall(get_visual)
    local fenced = "```\n" .. (has_selection and selection or get_buffer()) .. "\n```"

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

    vim.system({
        "curl", "-sS",
        "-H", "Content-Type: application/json",
        "-H", "Authorization: Bearer " .. api_key,
        "-d", payload,
        "https://api.openai.com/v1/chat/completions"
    }, {}, function(out)
        vim.schedule(function()
            M.ask_with_response(out)
        end)
    end)
end

--- @param out vim.SystemCompleted
M.ask_with_response = function(out)
    if out.code ~= 0 then
        error("Could not ask AI. Could not reach openai.")
    end

    if not out.stdout or out.stdout == "" then
        error("Could not ask AI. No response from openai.")
    end

    local has_data, data = pcall(vim.json.decode, out.stdout)
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
