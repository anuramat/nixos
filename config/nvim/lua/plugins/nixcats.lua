-- nixcats plugin loader using lze
local u = require('utils.helpers')

-- Load lze for lazy loading
vim.g.lze = {
  verbose = false,
  load = vim.cmd.packadd,
  default_priority = 50,
}

-- Configure lze with our plugins
require('lze').load({
  -- Core UI plugins
  {
    'aerial.nvim',
    event = 'BufEnter',
    after = function()
      require('aerial').setup({
        filter_kind = {
          nix = false,
        },
      })
    end,
    keys = {
      { 'gO', '<cmd>AerialToggle!<cr>', desc = 'Show Aerial Outline' },
    },
  },

  -- Fuzzy finder
  {
    'fzf-lua',
    after = function()
      require('fzf-lua').setup({
        grep = {
          fd_opts = '-c never -t f -HL',
          RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH,
          multiline = 2,
        },
        actions = {
          files = {
            true,
            ['ctrl-q'] = { fn = require('fzf-lua').actions.file_sel_to_qf, prefix = 'select-all' },
          },
        },
      })
    end,
    keys = u.wrap_lazy_keys({
      { 'o', 'files' },
      { 'O', 'oldfiles' },
      { 'a', 'args' },
      { 'b', 'buffers' },
      { 'm', 'marks' },
      { '/', 'curbuf' },
      { 'g', 'live_grep' },
      { 'G', 'grep_last' },
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
      module = 'fzf-lua',
      cmd_prefix = 'FzfLua ',
      exceptions = {
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

  -- File tree
  {
    'neo-tree.nvim',
    cmd = 'Neotree',
  },

  -- TreeSJ - splits/joins code
  {
    'treesj',
    after = function()
      require('treesj').setup({
        use_default_keymaps = false,
        max_join_length = 500,
      })
    end,
    keys = {
      {
        '<leader>j',
        function() require('treesj').toggle() end,
        desc = 'TreeSJ: Split/Join a Treesitter node',
      },
    },
  },

  -- Mini.align
  {
    'mini.align',
    after = function()
      require('mini.align').setup({
        mappings = {
          start = '<leader>a',
          start_with_preview = '<leader>A',
        },
      })
    end,
    keys = {
      { mode = { 'v', 'n' }, '<leader>a', desc = 'Align' },
      { mode = { 'v', 'n' }, '<leader>A', desc = 'Interactive align' },
    },
  },

  -- Flash.nvim - jump around
  {
    'flash.nvim',
    after = function()
      require('flash').setup({
        modes = {
          char = {
            enabled = false,
          },
          treesitter = {
            label = {
              rainbow = { enabled = true },
            },
          },
        },
        label = {
          before = true,
          after = false,
        },
      })
    end,
    keys = {
      {
        '<leader>r',
        mode = 'n',
        function() require('flash').jump() end,
        desc = 'Jump',
      },
      {
        'r',
        mode = 'o',
        function() require('flash').treesitter() end,
        desc = 'TS node',
      },
    },
  },

  -- Undotree
  {
    'undotree',
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

  -- Wastebin
  {
    'wastebin.nvim',
    after = function()
      require('wastebin').setup({
        url = 'https://bin.ctrl.sn',
        open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
        ask = false,
      })
    end,
    keys = {
      { '<leader>w', '<cmd>WastePaste<cr>' },
      { '<leader>w', [[<cmd>'<,'>WastePaste<cr>]], mode = 'v' },
    },
  },

  -- Load other plugin modules
  require('plugins.adapters.cmp-nixcats'),
  require('plugins.adapters.lsp-nixcats'),
  -- TODO: migrate other adapters
  -- require('plugins.adapters.dap-nixcats'),
  -- require('plugins.adapters.treesitter-nixcats'),
  -- require('plugins.adapters.llm-nixcats'),
  -- require('plugins.lang-nixcats'),
  require('plugins.core.git-nixcats'),
  require('plugins.core.ui-nixcats'),
  -- require('plugins.core.rare-nixcats'),
})
