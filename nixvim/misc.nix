{
  lib,
  inputs,
  pkgs,
  ...
}:
{
  plugins = {

    # {
    #   -- uses mathjax
    #   'anuramat/mdmath.nvim',
    #   cond = os.getenv('TERM') == 'xterm-ghostty',
    #   dependencies = 'nvim-treesitter/nvim-treesitter',
    #   ft = 'markdown',
    #   build = ':MdMath build', -- BUG doesn't work; because of lazy loading? have to call manually
    #   opts = function()
    #     local filename = vim.fn.expand('$XDG_CONFIG_HOME/latex/mathjax_preamble.tex')
    #     local file = io.open(filename, 'r')
    #     local chars = ''
    #     if file ~= nil then
    #       chars = file:read('*a')
    #       file:close()
    #     end
    #     return {
    #       filetypes = {},
    #       preamble = chars,
    #     }
    #   end,
    # },
    undotree.enable = true;
    # keys = [
    #   {
    #     __unkeyed-1 = "<leader>u";
    #     __unkeyed-3 = "<cmd>UndotreeToggle<cr>";
    #     desc = "Undotree";
    #   }
    # ];
    ts-comments.enable = true;
    flash = {
      enable = true;
      settings = {
        label = {
          after = false;
          before = true;
        };
        modes = {
          char = {
            enabled = false;
          };
          treesitter = {
            label = {
              rainbow = {
                enabled = true;
              };
            };
          };
        };
      };
      lazyLoad = {
        settings = {
          keys = [
            {
              __unkeyed_1 = "<leader>r";
              __unkeyed_2 = "function() require('flash').jump() end";
              desc = "Jump";
              mode = "n";
            }
            {
              __unkeyed_1 = "r";
              __unkeyed_2 = "function() require('flash').treesitter() end";
              desc = "TS node";
              mode = "o";
            }
          ];
        };
      };
    };
    ts-autotag = {
      enable = true;
    };

    treesj = {
      enable = true;
      lazyLoad = {
        enable = true;
        settings = {
          keys = [
            {
              __unkeyed-1 = "<leader>j";
              __unkeyed-2.__raw = ''function() require('treesj').toggle() end'';
              desc = "TreeSJ: Split/Join a Treesitter node";
            }
          ];
        };
      };
    };
    todo-comments = {
      enable = true;
      settings = {
        signs = false;
        highlight = {
          keyword = "bg"; # only highlight the KEYWORD
          pattern = ''<(KEYWORDS)>'';
          multiline = false;
        };
        search = {
          pattern = ''\b(KEYWORDS)\b'';
        };
      };
    };
  };

  extraPlugins = [
    inputs.wastebin-nvim.packages.${pkgs.system}.default
  ];

  # TODO
  # { '<leader>w', '<cmd>WastePaste<cr>' },
  # { '<leader>w', [[<cmd>'<,'>WastePaste<cr>]], mode = 'v' },
  extraConfigLua = ''
    require('wastebin').setup({
      url = 'https://bin.ctrl.sn',
      open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
      ask = false,
    })
  '';
}

# annotation generation: <https://github.com/danymat/neogen>
# indentation <https://github.com/lukas-reineke/indent-blankline.nvim>
# tests 'nvim-neotest/neotest'
# db stuff:
# * <https://github.com/kristijanhusak/vim-dadbod-completion>
# * <https://github.com/tpope/vim-dadbod>
# * <https://github.com/kristijanhusak/vim-dadbod-ui>

# { 'b', function(m) m.toggle_breakpoint() end, 'Toggle Breakpoint' },
# { 'c', function(m) m.continue() end, 'Continue' },
# { 'd', function(m) m.run_last() end, 'Run Last Debug Session' },
# { 'i', function(m) m.step_into() end, 'Step Into' },
# { 'l', log_point, 'Set Log Point' },
# { 'n', function(m) m.step_over() end, 'Step Over' },
# { 'o', function(m) m.step_out() end, 'Step Out' },
# { 'r', function(m) m.repl.open() end, 'Open Debug REPL' },

# local function log_point(m) m.set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end

# config = function()
#   -- some of these are used in catppuccin
#   local sign = vim.fn.sign_define
#   sign('DapBreakpoint', { text = '', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
#   sign('DapBreakpointCondition', { text = 'C', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
#   sign('DapLogPoint', { text = 'L', texthl = 'DapLogPoint', linehl = '', numhl = '' })
#   sign('DapStopped', { text = '→', texthl = 'DapStopped', linehl = '', numhl = '' })
#   -- sign('DapBreakpointRejected', { text = 'R', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })
# end,

# keys = u.wrap_lazy_keys({
#   { 'u', function(m) m.toggle() end, 'Toggle Dap UI' },
#   { 'e', function(m) m.eval() end,   'Evaluate',     mode = { 'n', 'v' } },
# }, {

# dapui
# opts = {
#   -- setting up default settings explicitly just in case
#   floating = {
#     border = 'single',
#     mappings = {
#       close = { 'q', '<Esc>' },
#     },
#   },
#   {
#     edit = 'e',
#     expand = { '<CR>', '<2-LeftMouse>' },
#     open = 'o',
#     remove = 'd',
#     repl = 'r',
#     toggle = 't',
#   },
# },

# 'ray-x/go.nvim', -- golang aio plugin

# haskell
# s('b', repl_toggler(ht, buffer), 'Toggle Buffer REPL')
# s('e', ht.lsp.buf_eval_all, 'Evaluate All')
# s('h', ht.hoogle.hoogle_signature, 'Show Hoogle Signature')
# s('p', ht.repl.toggle, 'Toggle Package REPL')
# s('q', ht.repl.quit, 'Quit REPL')

# -- ctags-lsp configuration https://github.com/netmute/ctags-lsp.nvim
# -- lsp adapter for ctags https://github.com/netmute/ctags-lsp
# -- cscope support <https://github.com/dhananjaylatkar/cscope_maps.nvim>
# -- regenerates tag files <https://github.com/ludovicchabant/vim-gutentags>
