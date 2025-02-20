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
        cmdline = {
          keymap = {
            preset = 'default',
            ['<tab>'] = { 'select_next', 'fallback' },
            ['<s-tab>'] = { 'select_prev', 'fallback' },
          },
        },
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
  -- {
  --   'milanglacier/minuet-ai.nvim',
  --   lazy = false,
  --   branch = 'main',
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --     'Saghen/blink.cmp', -- optional, not required if you are using virtual-text frontend
  --   },
  --   opts = function()
  --     return {
  --       virtualtext = {
  --         auto_trigger_ft = { '*' },
  --         auto_trigger_ignore_ft = {},
  --         show_on_completion_menu = true, -- show when menu is visible
  --         keymap = {
  --           -- TODO figure out hotkeys
  --           accept = '<A-a>',
  --           accept_line = '<A-y>',
  --           prev = '<A-p>',
  --           next = '<A-n>',
  --           dismiss = '<A-e>',
  --         },
  --       },
  --       provider = 'openai_fim_compatible',
  --       n_completions = 1,
  --       context_window = 512,
  --       provider_options = {
  --         openai_fim_compatible = {
  --           api_key = 'TERM',
  --           name = 'Ollama',
  --           end_point = 'http://localhost:11434/v1/completions',
  --           model = 'deepseek-coder-v2:16b',
  --         },
  --       },
  --     }
  --   end,
  -- },
}
