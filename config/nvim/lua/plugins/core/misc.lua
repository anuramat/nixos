-- vim: fdl=1

local u = require('utils.helpers')
return {
  -- fuzzy finder
  {
    'ibhagwan/fzf-lua',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    event = 'VeryLazy',
    opts = function()
      return {
        grep = {
          fd_opts = '-c never -t f -HL',
          RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH,
        },
        actions = {
          files = {
            true,
            ['ctrl-q'] = { fn = require('fzf-lua').actions.file_sel_to_qf, prefix = 'select-all' },
          },
        },
      }
    end,
    keys = u.wrap_lazy_keys({
      -- :he fzf-lua-commands

      { 'o', 'files' },
      { 'O', 'oldfiles' },
      { 'a', 'args' },
      { 'b', 'buffers' },
      { 'm', 'marks' },

      { '/', 'curbuf' },
      { 'g', 'live_grep' },
      { 'G', 'grep_last' },
      -- { 'G', 'grep' }, -- useful on large projects

      { 'd', 'diagnostics_document' },
      { 'D', 'diagnostics_workspace' },
      { 's', 'lsp_document_symbols' },
      { 'S', 'lsp_workspace_symbols' },
      { 't', 'treesitter' },

      { 'r', 'resume' },
      { 'h', 'helptags' },
      { 'k', 'keymaps' },
      { 'p', 'builtin' },
    }, {
      lhs_prefix = '<leader>f',
      desc_prefix = 'FzfLua: ',
      cmd_prefix = 'FzfLua ',
      wrapped = {
        {
          '<C-x><C-f>',
          function()
            require('fzf-lua').complete_file({
              cmd = 'fd -t f -HL',
              winopts = { preview = { hidden = 'nohidden' } },
            })
          end,
          mode = 'i',
          silent = true,
          desc = 'path completion',
        },
      },
    }),
  },
  -- treesj - splits/joins code using TS
  {
    'Wansmer/treesj',
    enabled = true,
    opts = { use_default_keymaps = false },
    keys = {
      {
        '<leader>j',
        function()
          require('treesj').toggle()
        end,
        desc = 'TreeSJ: Split/Join a Treesitter node',
      },
    },
  },
  -- oil.nvim - file manager
  {
    'stevearc/oil.nvim',
    lazy = false, -- so that it overrides `nvim <path>`
    opts = {
      default_file_explorer = true,
      columns = {
        'icon',
        'permissions',
        'size',
        'mtime',
      },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      constrain_cursor = 'editable', -- name false editable
      experimental_watch_for_changes = true,
      keymaps_help = {
        border = vim.g.border,
      },
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
        natural_order = true,
        sort = {
          -- sort order can be "asc" or "desc"
          -- see :help oil-columns to see which columns are sortable
          { 'type', 'asc' },
          { 'name', 'asc' },
        },
      },
      float = { border = vim.g.border },
      preview = { border = vim.g.border },
      progress = { border = vim.g.border },
      ssh = {
        border = vim.g.border,
      },
    },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '<leader>o', '<cmd>Oil<cr>', desc = 'File CWD' },
      { '<leader>O', '<cmd>Oil .<cr>', desc = 'Open Parent Directory' },
    },
  },
  -- eunuch - rm, mv, etc
  {
    -- basic file commads for the current file (remove, rename, etc.)
    -- see also:
    -- chrisgrieser/nvim-genghis - drop in lua replacement with some bloat/improvements
    'tpope/vim-eunuch',
    event = 'VeryLazy',
  },
  -- undotree
  {
    'mbbill/undotree',
    cmd = {
      'UndotreeHide',
      'UndotreeShow',
      'UndotreeFocus',
      'UndotreeToggle',
    },
    keys = {
      {
        '<leader>u',
        '<cmd>UndotreeToggle<cr>',
        desc = 'Undotree',
      },
    },
  },
  -- mini.align - align text interactively
  {
    'echasnovski/mini.align',
    opts = {
      mappings = {
        start = '<leader>a',
        start_with_preview = '<leader>A',
      },
    },
    keys = {
      { mode = { 'x', 'n' }, '<leader>a', desc = 'Align' },
      { mode = { 'x', 'n' }, '<leader>A', desc = 'Interactive align' },
    },
  },
  -- flash.nvim - jump around
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      modes = {
        char = {
          enable = true,
          label = {
            rainbow = { enabled = false },
          },
        },
        treesitter = {},
      },
      label = {
        before = true,
        after = false,
        reuse = 'none',
        rainbow = { enabled = true },
      },
    },
    keys = {
      {
        '<leader>r',
        mode = 'n',
        function()
          require('flash').jump()
        end,
        desc = 'Jump',
      },
      {
        'r',
        mode = 'o',
        function()
          require('flash').treesitter()
        end,
        desc = 'TS node',
      },
    },
  },
  -- improves native commenting
  {
    'folke/ts-comments.nvim',
    opts = {},
    event = 'VeryLazy',
  },
}

-- annotation generation: <https://github.com/danymat/neogen>
-- indentation <https://github.com/lukas-reineke/indent-blankline.nvim>
-- tests 'nvim-neotest/neotest'
