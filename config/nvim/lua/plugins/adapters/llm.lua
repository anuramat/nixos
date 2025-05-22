local u = require('utils.helpers')

local ollama_model = 'qwen3:0.6b'
local ollama_endpoint = 'http://localhost:11434'

local copilot_models = {
  gpt = 'gpt-4.1',
  claude = 'claude-3.5-sonnet',
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
    event = 'VeryLazy',
    'yetone/avante.nvim',
    version = false,
    opts = {
      -- mode = 'legacy', -- BUG ollama can't do tools
      provider = 'copilot',
      behaviour = {
        auto_suggestions = false,
      },
      rag_service = { -- experimental: <https://github.com/yetone/avante.nvim/issues/1587>
        -- implemented as a tool
        -- runs on localhost:20250
        -- BUG: 1. not reachable from outside; 2. docker logs full of shit (persist_dir is invalid): <https://github.com/yetone/avante.nvim/issues/1634>
        enabled = false,
        host_mount = '/etc/nixos',
        provider = 'ollama',
        llm_model = ollama_model,
        embed_model = 'nomic-embed-text', -- TODO change?
        endpoint = ollama_endpoint,
      },
      copilot = {
        model = copilot_models.gpt,
        max_tokens = 20480,
      },
      vendors = {
        pollinations = {
          __inherited_from = 'openai',
          api_key_name = '',
          endpoint = 'https://text.pollinations.ai/openai',
          model = 'openai',
        },
        -- TODO github models <https://github.com/yetone/avante.nvim/issues/2042>
      },
      ollama = {
        endpoint = ollama_endpoint,
        model = ollama_model,
        reasoning_effort = 'low', -- low|medium|high, only used for reasoning models
        -- system_prompt = '\\no_think', -- make reasoners shut up -- TODO not sure if this even works per model
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
      'ravitemer/mcphub.nvim',
      'nvim-treesitter/nvim-treesitter',
      'stevearc/dressing.nvim',
      'MunifTanjim/nui.nvim',
      'ibhagwan/fzf-lua',
    },
  },
  {
    'ravitemer/mcphub.nvim',
    build = 'bundled_build.lua',
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
