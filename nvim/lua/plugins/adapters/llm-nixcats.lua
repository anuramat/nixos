-- https://docs.github.com/en/copilot/managing-copilot/monitoring-usage-and-entitlements/about-premium-requests
-- 300 premium requests per month
local models = {
  qwen06 = {
    -- runs even on t480, 100% GPU on ll7
    name = 'qwen3:0.6b',
    num_ctx = nil,
  },
  qwen40 = {
    -- 20480 is default; qwen3:4b -- 20k over, 19.5k under
    name = 'qwen3:4b',
    num_ctx = 19500,
  },
  qwen80 = {
    -- 10k under, 11k over
    name = 'qwen3:8b',
    num_ctx = 10000,
  },
}

local config = {
  reasoning_effort = 'low', -- low|medium|high, only used for reasoning models
  think = false,
  extra_request_body = { options = {} },
  endpoint = 'http://localhost:11434',
}

local function wrapQwen(model)
  config.model = model.name
  if not config.think then config.reasoning_effort = nil end
  config.extra_request_body.options.num_ctx = model.num_ctx
  return config
end

local ollama = wrapQwen(models.qwen40)

local provider = 'copilot'

return {
  {
    'copilot.lua',
    cmd = 'Copilot',
    after = function()
      require('copilot').setup({
        suggestion = {
          enabled = false,
        },
        panel = {
          enabled = false,
        },
      })
    end,
  },
  {
    'avante.nvim',
    keys = { '<leader>a' },
    after = function()
      require('avante').setup({
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
      })
    end,
    build = 'make',
  },
  {
    'mcphub.nvim',
    build = 'bundled_build.lua',
    cmd = 'MCPHub',
    after = function()
      require('mcphub').setup({
        use_bundled_binary = true,
        auto_approve = false,
        extensions = {
          avante = {
            make_slash_commands = true,
          },
        },
      })
    end,
  },
}