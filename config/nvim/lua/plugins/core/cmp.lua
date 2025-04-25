local adapter = 'llmao' -- just a bound name

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
  -- llm stuff
  {
    'olimorris/codecompanion.nvim',
    event = 'BufEnter',
    opts = {
      adapters = {
        [adapter] = function()
          return require('codecompanion.adapters').extend('ollama', {
            name = adapter,
            schema = { model = { default = 'deepseek-coder-v2:16b' } },
          })
        end,
      },
      strategies = {
        chat = { adapter = adapter },
        inline = { adapter = { name = adapter } },
      },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
  },
}
