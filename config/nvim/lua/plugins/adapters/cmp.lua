return {
  'saghen/blink.cmp',
  dependencies = 'anuramat/friendly-snippets',
  version = '*', -- on nightly - add `build = 'nix run .#build-plugin'`
  opts = {
    completion = { documentation = {
      auto_show = true,
      auto_show_delay_ms = 500,
    } },
    signature = { enabled = true }, -- not really required, we can use <c-s> instead
    appearance = { nerd_font_variant = 'normal' },
    sources = {
      providers = {
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          score_offset = 100, -- prioritize
        },
        avante = {
          module = 'blink-cmp-avante',
          name = 'Avante',
          opts = {
          },
        },
      },
      default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
    },
  },
}
