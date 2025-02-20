return {
  -- autocomplete and signature
  {
    'saghen/blink.cmp',
    dependencies = {
      'anuramat/friendly-snippets',
      'milanglacier/minuet-ai.nvim',
    },
    version = '*', -- on nightly - add `build = 'nix run .#build-plugin'`
    opts = function()
      return {
        cmdline = {
          keymap = {
            preset = 'default',
            ['<tab>'] = { 'select_next', 'fallback' },
            ['<s-tab>'] = { 'select_prev', 'fallback' },
          },
        },
        keymap = {
          preset = 'default',
          ['<a-y>'] = require('minuet').make_blink_map(),
        },
        completion = {
          documentation = { auto_show = true, auto_show_delay_ms = 500 },
        },
        sources = {
          default = { 'lsp', 'path', 'snippets', 'buffer', 'minuet' },
          providers = {
            minuet = {
              name = 'minuet',
              module = 'minuet.blink',
              score_offset = 8,
            },
          },
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
  {
    'milanglacier/minuet-ai.nvim',
    lazy = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'Saghen/blink.cmp', -- optional, not required if you are using virtual-text frontend
    },
    config = function()
      require('minuet').setup({
        provider = 'openai_fim_compatible',
        n_completions = 1, -- recommend for local model for resource saving
        -- I recommend beginning with a small context window size and incrementally
        -- expanding it, depending on your local computing power. A context window
        -- of 512, serves as an good starting point to estimate your computing
        -- power. Once you have a reliable estimate of your local computing power,
        -- you should adjust the context window to a larger value.
        context_window = 512,
        provider_options = {
          openai_fim_compatible = {
            api_key = 'TERM',
            name = 'Ollama',
            end_point = 'http://localhost:11434/v1/completions',
            model = 'deepseek-coder-v2:16b',
            optional = {
              max_tokens = 56,
              top_p = 0.9,
            },
          },
        },
      })
    end,
  },
}
