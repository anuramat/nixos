-- Git plugins configuration for nixcats + lze
local u = require('utils.helpers')

return {
  -- Neogit
  {
    "neogit",
    cmd = "Neogit",
    after = function()
      require("neogit").setup({
        kind = 'floating',
      })
    end,
    keys = { 
      { '<leader>go', '<cmd>Neogit<cr>', desc = 'Neogit' } 
    },
  },

  -- Vim fugitive
  {
    "vim-fugitive",
    cmd = { "Git", "G" },
    keys = { 
      {
        '<leader>G',
        '<cmd>Git<cr>',
        desc = 'Fugitive',
      } 
    },
  },

  -- Gitsigns
  {
    "gitsigns.nvim",
    event = "BufRead",
    after = function()
      require("gitsigns").setup({
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
      })
    end,
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

  -- Diffview
  {
    "diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose" },
  },

  -- Gitlinker
  {
    "gitlinker.nvim",
    event = "BufRead",
    after = function()
      require("gitlinker").setup({
        opts = {
          add_current_line_on_normal_mode = false,
          print_url = true,
        },
      })
    end,
  },
}
