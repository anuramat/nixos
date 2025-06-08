-- Blink.cmp configuration for nixcats + lze
return {
  'blink.cmp',
  event = 'InsertEnter',
  after = function()
    require('blink.cmp').setup({
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
        },
      },
      signature = { enabled = true },
      appearance = { nerd_font_variant = 'normal' },
      sources = {
        providers = {
          lazydev = {
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            score_offset = 100,
          },
          avante = {
            module = 'blink-cmp-avante',
            name = 'Avante',
            opts = {},
          },
        },
        default = { 'avante', 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
      },
    })
  end,
}
