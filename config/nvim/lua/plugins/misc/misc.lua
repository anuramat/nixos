-- vim: fdl=1

return {
  -- indent-blankline.nvim
  {
    'lukas-reineke/indent-blankline.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    event = 'VeryLazy',
    main = 'ibl',
    init = function()
      vim.cmd([[se lcs+=lead:\ ]])
    end,
    opts = function()
      return {
        exclude = {
          filetypes = {
            'lazy',
          },
        },
        indent = {
          -- highlight = rainbow_lines(),
          char = '│',
          -- char = '┃',
        },
        scope = {
          enabled = true,
          show_start = false,
          show_end = false,
        },
      }
    end,
  },
  -- neotest
  {
    'nvim-neotest/neotest',
    lazy = false,
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-neotest/neotest-go', -- go
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
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
      require('neotest').setup({
        -- your neotest config here
        adapters = {
          require('neotest-go'),
        },
      })
    end,
  },
  -- todo-comments.nvim - highlights TODO, HACK, etc
  {
    'folke/todo-comments.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
    opts = {
      sign_priority = -1000,
      highlight = {
        keyword = 'bg', -- only highlight the word
        pattern = [[<(KEYWORDS)>]], -- vim regex
        multiline = false, -- enable multine todo comments
      },
      search = {
        pattern = [[\b(KEYWORDS)\b]], -- ripgrep regex
      },
    },
  },
  -- pywal16.nvim
  {
    lazy = false,
    'uZer/pywal16.nvim',
    as = 'pywal16',
    config = function()
      local pywal16 = require('pywal16')
      pywal16.setup()
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
        show_hidden = false,
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
  -- vim-illuminate - highlights the word under cursor using LSP/TS/regex
  {
    'RRethy/vim-illuminate',
    event = 'VeryLazy',
    config = function()
      require('illuminate').configure({
        filetypes_denylist = { -- TODO make a vim.g.nonfiles
          'NeogitStatus',
          'NeogitPopup',
          'oil',
          'lazy',
          'lspinfo',
          'null-ls-info',
          'NvimTree',
          'neo-tree',
          'alpha',
          'help',
        },
      })
    end,
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
  -- mini.trailspace - highlight and delete trailing whitespace
  {
    'echasnovski/mini.trailspace',
    event = 'VeryLazy',
    config = function()
      vim.api.nvim_create_user_command('Trim', require('mini.trailspace').trim, {})
      vim.cmd(
        [[autocmd FileType lazy lua vim.b.minitrailspace_disable = true; require('mini.trailspace').unhighlight()]]
      )
    end,
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
  -- nvim-surround - standard surround plugin
  {
    -- The most popular surround plugin (right after tpope/vim-surround)
    'kylechui/nvim-surround',
    opts = {
      keymaps = {
        insert = false,
        insert_line = false,
        -- normal = '<leader>s',
        -- normal_cur = '<leader>ss',
        -- normal_line = '<leader>S',
        -- normal_cur_line = '<leader>SS',
        -- visual = '<leader>s',
        -- visual_line = '<leader>S',
        delete = 'ds',
        change = 'cs',
        change_line = 'cS',
      },
    },
    event = 'BufEnter',
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
  -- vim-dadbod - never used, might be broken
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      { 'tpope/vim-dadbod' },
      {
        'kristijanhusak/vim-dadbod-completion',
        ft = { 'sql', 'mysql', 'plsql' },
        dependencies = { 'hrsh7th/nvim-cmp' },
        init = function()
          -- untested
          vim.cmd(
            [[autocmd FileType sql,mysql,plsql lua require('cmp').setup.buffer({ sources = {{ name = 'vim-dadbod-completion' }} })]]
          )
        end,
      },
    },
    cmd = {
      'DBUI',
      'DBUIToggle',
      'DBUIAddConnection',
      'DBUIFindBuffer',
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  -- vim-fetch - allows for ':e file.txt:1337'
  {
    lazy = false,
    'wsdjeg/vim-fetch',
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
  -- vim-sleuth - autodetects indentation settings
  {
    'tpope/vim-sleuth',
    lazy = false,
  },
  -- nvim-colorizer.lua - highlights eg #012345
  {
    'NvChad/nvim-colorizer.lua',
    event = 'VeryLazy',
    opts = {},
  },
  -- mini.bracketed - new ]/[ targets
  {
    'echasnovski/mini.bracketed',
    lazy = false,
    opts = {},
  },
  -- sniprun - run selected code
  {
    event = 'VeryLazy',
    'michaelb/sniprun',
    branch = 'master',
    build = 'sh install.sh',
    opts = {},
  },
  -- info.vim - gnu info browser
  {
    'HiPhish/info.vim',
    event = 'VeryLazy',
  },
  -- flash.nvim - jump around
  {
    'folke/flash.nvim',
    opts = {
      modes = {
        search = { enabled = false },
        char = { enabled = false },
      },
    },
    keys = {
      {
        's',
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
}
