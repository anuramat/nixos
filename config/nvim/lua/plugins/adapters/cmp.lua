-- vim: fdl=1

return {
  'saghen/blink.cmp',
  dependencies = {
    'anuramat/friendly-snippets',
  },
  version = '*', -- on nightly - add `build = 'nix run .#build-plugin'`
  opts = {
    keymap = {
      preset = 'default',
    },
    appearance = {
      -- adjusts spacing: mono - Nerd Font Mono, normal - Nerd Font
      nerd_font_variant = 'normal',
    },
  },
}
