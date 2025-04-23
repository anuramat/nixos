return {
  -- autocomplete and signature
  {
    'saghen/blink.cmp',
    dependencies = {
      'anuramat/friendly-snippets',
    },
    version = '*', -- on nightly - add `build = 'nix run .#build-plugin'`
    opts = function()
      return {
        -- NOTE apparently this breaks on the new version, and might be actually included by default
        -- cmdline = {
        --   keymap = {
        --     preset = 'default',
        --     -- ['<tab>'] = { 'select_next', 'fallback' },
        --     -- ['<s-tab>'] = { 'select_prev', 'fallback' },
        --   },
        -- },
        keymap = {
          preset = 'default',
        },
        completion = {
          documentation = { auto_show = true, auto_show_delay_ms = 500 },
        },
        signature = { enabled = true },
        -- TODO maybe replace with native stuff:
        -- inoremap <c-k> <cmd>lua vim.lsp.buf.signature_help()<cr>
        appearance = {
          nerd_font_variant = 'mono', -- 'normal' adds spacing between the icon and the name
        },
      }
    end,
  },
  -- llm stuff
  {
    'olimorris/codecompanion.nvim',
    event = 'BufEnter',
    opts = {
      adapters = {
        llmao = function()
          return require('codecompanion.adapters').extend('ollama', {
            name = 'llmao',
            schema = {
              model = {
                default = 'deepseek-coder-v2:16b',
              },
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = 'llmao',
        },
        inline = {
          adapter = {
            name = 'llmao',
          },
        },
      },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
  },
}
