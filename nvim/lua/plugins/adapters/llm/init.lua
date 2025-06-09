local copilot = require('plugins.adapters.llm.copilot')
local ollama = require('plugins.adapters.llm.ollama')

local provider = 'copilot'

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
    vejsion = false,
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
      providers = {
        pollinations = {
          __inherited_from = 'openai',
          api_key_name = '',
          endpoint = 'https://text.pollinations.ai/openai',
          model = 'openai',
        },
        ollama = ollama,
        copilot = {
          model = copilot.claude40,
        },
      },
      system_prompt = function()
        local hub = require('mcphub').get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ''
      end,
      custom_tools = function() return { require('mcphub.extensions.avante').mcp_tool() } end,
      windows = {
        position = 'right', -- the position of the sidebar
        wrap = true,
        width = 40,
        sidebar_header = {
          enabled = false, -- true, false to enable/disable the header
        },
        input = {
          prefix = '',
          height = 12, -- Height of the input window in vertical layout
        },
        edit = { start_insert = false },
        ask = {
          floating = false, -- Open the 'AvanteAsk' prompt in a floating window
          start_insert = false,
        },
      },
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
