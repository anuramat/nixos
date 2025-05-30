local m = require('plugins.adapters.llm.models')

local provider = 'copilot'

local copilot = {
  model = m.copilot.gpt41,
}

local ollama = {
  model = m.ollama.qwen17,
  endpoint = 'http://localhost:11434',
  proxy_endpoint = 'http://localhost:11435',
}

return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    opts = {
      suggestion = {
        enabled = false,
      },
      panel = {
        enabled = false,
      },
    },
  },
  {
    'yetone/avante.nvim',
    version = false,
    keys = { '<leader>a' },
    opts = {
      provider = provider,
      behaviour = {
        auto_suggestions = false,
      },
      rag_service = { -- experimental: <https://github.com/yetone/avante.nvim/issues/1587>
        -- implemented as a tool
        -- runs on localhost:20250
        -- BUG: 1. not reachable from outside; 2. docker logs full of shit (persist_dir is invalid): <https://github.com/yetone/avante.nvim/issues/1634>
        -- NOTE do we need this? cline people (iirc) say we don't
        enabled = false,
      },
      copilot = {
        model = copilot.model,
      },
      vendors = {
        pollinations = {
          __inherited_from = 'openai',
          api_key_name = '',
          endpoint = 'https://text.pollinations.ai/openai',
          model = 'openai',
        },
        ollama_proxy = {
          __inherited_from = 'ollama',
          api_key_name = '',
          endpoint = ollama.proxy_endpoint,
          model = ollama.model,
        },
      },
      ollama = {
        endpoint = ollama.endpoint,
        model = ollama.model,
        reasoning_effort = 'low', -- low|medium|high, only used for reasoning models
        think = false,
      },
      system_prompt = function()
        local hub = require('mcphub').get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ''
      end,
      custom_tools = function() return { require('mcphub.extensions.avante').mcp_tool() } end,
    },
    build = 'make',
    dependencies = {
      { 'Kaiser-Yang/blink-cmp-avante', version = false },
      'nvim-treesitter/nvim-treesitter',
      'stevearc/dressing.nvim',
      'MunifTanjim/nui.nvim',
      'ibhagwan/fzf-lua',
    },
  },
  {
    'ravitemer/mcphub.nvim',
    -- todo
    -- - <https://smithery.ai/?q=search>
    -- - search <https://github.com/nickclyde/duckduckgo-mcp-server>
    -- - paper search
    -- - hyperbrowser
    build = 'bundled_build.lua',
    cmd = 'MCPHub',
    opts = {
      use_bundled_binary = true,
      auto_approve = false,
      extensions = {
        avante = {
          make_slash_commands = true,
        },
      },
    },
  },
}
