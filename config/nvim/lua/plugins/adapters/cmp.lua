local modelname = 'qwen3:8b'
return {
  -- autocomplete and signature
  {
    'saghen/blink.cmp',
    dependencies = 'anuramat/friendly-snippets',
    version = '*', -- on nightly - add `build = 'nix run .#build-plugin'`
    opts = function()
      return {
        completion = { documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
        } },
        signature = { enabled = true },
        -- TODO maybe replace with native stuff:
        -- inoremap <c-k> <cmd>lua vim.lsp.buf.signature_help()<cr>
        appearance = { nerd_font_variant = 'normal' },
      }
    end,
  },
  -- llm autocomplete, chat, agents/tools
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
      'nvim-treesitter/nvim-treesitter',
      'stevearc/dressing.nvim',
      'MunifTanjim/nui.nvim',
      'ibhagwan/fzf-lua',
    },
  },
  -- TODO github models
}
