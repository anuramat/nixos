-- vim: fdl=1
local u = require('utils.helpers')
return {
  {
    'NeogitOrg/neogit',
    dependencies = {
      'sindrets/diffview.nvim',
      'ibhagwan/fzf-lua',
    },
    event = 'VeryLazy',
    opts = {
      kind = 'floating',
    },
    keys = { { '<leader>go', '<cmd>Neogit<cr>', desc = 'Neogit' } },
  },
  -- neogit is unstable as of 03-2024
  'tpope/vim-fugitive',
  keys = { {
    '<leader>G',
    '<cmd>Git<cr>',
    event = 'VeryLazy',
    desc = 'Fugitive',
  } },
  -- gitsigns - gutter, binds, etc.
  {
    -- tanvirtin/vgit.nvim
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
    opts = {
      sign_priority = 1000,
      signs_staged = {
        add = { text = '▎' },
        change = { text = '▎' },
        delete = { text = '▎' },
        topdelete = { text = '▎' },
        changedelete = { text = '▎' },
        untracked = { text = '▎' },
      },
      on_attach = function() end,
    },
    keys = u.wrap_lazy_keys({
      -- stage
      { 's', function(m) m.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, mode = 'v', 'Stage selection' },
      { 's', function(m) m.stage_hunk() end, 'Stage hunk' },
      { 'S', function(m) m.stage_buffer() end, 'Stage buffer' },
      -- reset
      { 'r', function(m) m.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, mode = 'v', 'Reset selection' },
      { 'r', function(m) m.reset_hunk() end, 'Reset hunk' },
      { 'R', function(m) m.reset_buffer() end, 'Reset buffer' },
      -- misc
      { 'b', function(m) m.blame_line({ full = true }) end, 'Blame line' },
      { 'p', function(m) m.preview_hunk() end, 'Preview hunk' },
      { 'd', function(m) m.diffthis() end, 'Diff file' },
    }, {
      lhs_prefix = '<leader>g',
      module = 'gitsigns',
      desc_prefix = 'Gitsigns',
      exceptions = {
        { 'ih', function() require('gitsigns').select_hunk() end, 'Select hunk', mode = { 'o', 'x' } },
        { 'ah', function() require('gitsigns').select_hunk({ greedy = true }) end, 'Select hunk', mode = { 'o', 'x' } },
        { ']h', function() require('gitsigns').next_hunk() end, 'Next hunk' },
        { '[h', function() require('gitsigns').prev_hunk() end, 'Previous hunk' },
      },
    }),
  },
  -- diffview
  {
    'sindrets/diffview.nvim',
    event = 'VeryLazy',
  },
  {
    'ruifm/gitlinker.nvim',
    event = 'VeryLazy',
    opts = {
      opts = {
        add_current_line_on_normal_mode = false,
        print_url = true,
      },
      -- mappings = nil -- '<leader>gy',
      -- TODO move to lazy keys, remove event, add more mappings
    },
  },
}
