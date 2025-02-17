-- vim: fdl=1

local u = require('utils.helpers')
return {
  -- autocomplete and signature
  {
    'saghen/blink.cmp',
    dependencies = {
      'anuramat/friendly-snippets',
    },
    version = '*', -- on nightly - add `build = 'nix run .#build-plugin'`
    opts = {
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
    },
  },
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
  -- neogen - annotation generation
  {
    'danymat/neogen',
    opts = {},
    event = 'BufEnter',
  },
  -- neotest
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-neotest/neotest-go', -- go
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = function()
      -- get neotest namespace (api call creates or returns namespace)
      local neotest_ns = vim.api.nvim_create_namespace('neotest')
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            local message = diagnostic.message:gsub('\n', ' '):gsub('\t', ' '):gsub('%s+', ' '):gsub('^%s+', '')
            return message
          end,
        },
      }, neotest_ns)
      return {
        -- your neotest config here
        adapters = {
          require('neotest-go'),
        },
      }
    end,
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
  -- vim-table-mode -  tables for markdown etc
  {
    'dhruvasagar/vim-table-mode',
    init = function()
      vim.g.table_mode_disable_mappings = 1
      vim.g.table_mode_disable_tableize_mappings = 1
      vim.keymap.set('n', '<leader>T', '<cmd>TableModeToggle<cr>', { silent = true, desc = 'Table Mode: Toggle' })
      vim.keymap.set(
        'n',
        '<leader>t',
        '<cmd>TableModeRealign<cr>',
        { silent = true, desc = 'Table Mode: Realign once' }
      )
    end,
    ft = 'markdown',
  },
  -- mini.align - align text interactively
  {
    'echasnovski/mini.align',
    -- See also:
    -- junegunn/vim-easy-align
    -- godlygeek/tabular
    -- tommcdo/vim-lion
    -- Vonr/align.nvim
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
  -- harpoon - project-local file marks
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = function()
      local harpoon = require('harpoon')
      local set = function(lhs, rhs, desc)
        vim.keymap.set('n', '<leader>h' .. lhs, rhs, { silent = true, desc = 'Harpoon: ' .. desc })
      end
   -- stylua: ignore start
    set('a', function() harpoon:list():add() end, 'Add')
    set('l', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, 'List')
    set('n', function() harpoon:list():next() end, 'Next')
    set('p', function() harpoon:list():prev() end, 'Previous')
      -- stylua: ignore end
      for i = 1, 9 do
        local si = tostring(i)
        set(si, function()
          harpoon:list():select(i)
        end, 'Go to #' .. si)
      end
    end,
  },
  -- sniprun - run selected code
  {
    event = 'VeryLazy',
    'michaelb/sniprun',
    build = 'sh install.sh',
    opts = {},
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
  -- compiler.nvim
  {
    'Zeioth/compiler.nvim',
    cmd = { 'CompilerOpen', 'CompilerToggleResults', 'CompilerRedo' },
    dependencies = { 'stevearc/overseer.nvim' },
    opts = {},
    -- TODO steal more shit from https://github.com/Zeioth/compiler.nvim
  },
  -- overseer.nvim - task runner (tasks.json, dap integration, etc)
  {
    'stevearc/overseer.nvim',
    commit = '6271cab7ccc4ca840faa93f54440ffae3a3918bd',
    cmd = { 'CompilerOpen', 'CompilerToggleResults', 'CompilerRedo' },
    opts = {
      task_list = {
        direction = 'bottom',
        min_height = 25,
        max_height = 25,
        default_detail = 1,
      },
    },
  },
  -- improves native comments
  {
    'folke/ts-comments.nvim',
    opts = {},
    event = 'VeryLazy',
  },
  -- project wide find and replace
  {
    'MagicDuck/grug-far.nvim',
    opts = {},
    cmd = 'GrugFar',
    keys = {},
  },
}
