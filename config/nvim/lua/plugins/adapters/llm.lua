local modelname = 'qwen3:8b'
return {
  {
    'olimorris/codecompanion.nvim',
    -- BUG chat hangs up after one message
    event = 'BufEnter',
    opts = {
      adapters = {
        lmao = function()
          return require('codecompanion.adapters').extend('ollama', {
            -- BUG tools are broken <https://github.com/ollama/ollama/issues/9632>
            name = 'lmao',
            schema = { model = { default = modelname } },
          })
        end,
        pollinations = function()
          -- BUG doesn't work for some reason
          return require('codecompanion.adapters').extend('openai_compatible', {
            env = { url = 'https://text.pollinations.ai/openai' },
            schema = { model = { default = 'openai' } },
          })
        end,
        -- 'githubmodels'
      },
      strategies = {
        chat = { adapter = 'pollinations' },
        -- inline = { adapter = { name = '' } },
      },
    },
    dependencies = 'nvim-treesitter/nvim-treesitter',
  },
  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    version = false,
    opts = {
      provider = 'ollama',
      vendors = {
        pollinations = {
          __inherited_from = 'openai',
          api_key_name = '',
          endpoint = 'https://text.pollinations.ai/openai',
          model = 'openai',
        },
        -- github models is not available yet <https://github.com/yetone/avante.nvim/issues/2042>
      },
      ollama = {
        endpoint = 'http://127.0.0.1:11434',
        model = modelname,
        reasoning_effort = 'low', -- low|medium|high, only used for reasoning models
      },
    },
    build = 'make',
    dependencies = {
      'Kaiser-Yang/blink-cmp-avante',
      'nvim-treesitter/nvim-treesitter',
      'stevearc/dressing.nvim',
      'MunifTanjim/nui.nvim',
      'ibhagwan/fzf-lua',
    },
  },
  -- TODO github models
}
