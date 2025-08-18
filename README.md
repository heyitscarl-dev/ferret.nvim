# 🦦 ferret.nvim
A minimal neovim plugin that allows you to ask questions about your code - and have them answered!

## Features

- [ ] Select text in **visual mode** and query an LLM with a single keymap.
- [ ] Get answers back directly, inside a floating window or a scratch buffer.
- [ ] Pluggable **provider system** (OpenAI, Anthropic, etc.)

## Installation

Use your package manager of choice. _Minimal example using lazy.nvim_:

```lua
{
    "heyitscarl-dev/ferret.nvim",
    opts = {
        auth = {
            api_key_cmd = "pass show my-openai-api-key"  -- example using password store...
            -- api_key_env = "OPENAI_API_KEY"            -- ...or via an environment variable
        },
        provider = "openai"
    },
    config = function(_, opts)
        require("ferret").setup(opts)
        vim.keymap.set({ "n", "v" }, "<Leader>qa", ":Ferret<CR>", { desc = "Ask AI" })
    end
}
```

## Usage

1. Visually **select** some code or text.
2. Press your configured keymap (e.g. `<Leader>qa`).
3. Type your prompt (e.g. "Explain this code" or "Translate to Rust")
4. Receive the AI's response inline or in a floating window

## Configuration

_Default Configuration:_

```
opts = {
    -- coming soon
}
```

## Roadmap

- [ ] [Persistant and re-openable conversation-like chats via a Telescope picker.](https://github.com/heyitscarl-dev/ferret.nvim/issues/3)
- [ ] [Response streaming instead of awaiting the whole response.](https://github.com/heyitscarl-dev/ferret.nvim/issues/2)
- [ ] [Local LLM support via an `ollama` provider.](https://github.com/heyitscarl-dev/ferret.nvim/issues/1)

## Contributing

PRs, Issues and Ideas are always welcome 🐵
