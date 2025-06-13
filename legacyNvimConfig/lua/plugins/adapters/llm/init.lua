-- https://docs.github.com/en/copilot/managing-copilot/monitoring-usage-and-entitlements/about-premium-requests
-- 300 premium requests per month
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
      providers = {
        ollama = ollama,
        copilot = {
          model = 'claude-sonnet-4',
        },
      },
      system_prompt = function()
        local hub = require('mcphub').get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ''
      end,
      custom_tools = function() return { require('mcphub.extensions.avante').mcp_tool() } end,
      windows = {
        position = 'bottom', -- the position of the sidebar
        wrap = true,
        width = 40,
        input = {
          prefix = '',
          height = 12,
        },
        edit = { start_insert = false },
        ask = {
          floating = true,
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
