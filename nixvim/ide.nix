{ lib, pkgs, ... }:
{

  # -- formatting
  # f.stylua,
  # f.black,
  # f.nixfmt,
  # f.yamlfmt,
  # f.mdformat,
  # ormolu,
  # -- diagnostics
  # -- d.statix, -- TODO turn on when they introduce pipe operator
  # d.protolint,
  # d.yamllint,
  # -- actions
  # a.statix,
  # -- hovers
  # h.printenv,

  plugins = {
    nvim-lightbulb.enable = true;
    # grug-far
    # 'anuramat/figtree.nvim',

    dressing.enable = true;
    # {
    #   'bassamsdata/namu.nvim',
    #   opts = {
    #     namu_symbols = {
    #       enable = true,
    #       options = {},
    #     },
    #     ui_select = {
    #       enable = true,
    #     },
    #     colorscheme = {
    #       enable = true,
    #     },
    #   },
    #   keys = {
    #     { '<leader>s', '<cmd>Namu symbols<cr>', { desc = 'Jump to LSP symbol', silent = true } },
    #   },
    # },

    # {
    #   'ThePrimeagen/harpoon',
    #   branch = 'harpoon2',
    #   keys = u.wrap_lazy_keys({
    #     { 'a', function(m) m:list():add() end, 'Add' },
    #     { 'l', function(m) m.ui:toggle_quick_menu(m:list()) end, 'List' },
    #     { 'n', function(m) m:list():next() end, 'Next' },
    #     { 'p', function(m) m:list():prev() end, 'Previous' },
    #     { '%d', function(i, m) m:list():select(i) end, 'Go to #%d', iterator = true },
    #   }, {
    #     module = 'harpoon',
    #     lhs_prefix = '<leader>h',
    #   }),
    # },

    # {
    #   event = 'VeryLazy',
    #   'michaelb/sniprun',
    #   build = 'sh install.sh',
    #   opts = {},
    # },

    # {
    # -- task runner (tasks.json, dap integration, etc)
    #   'stevearc/overseer.nvim',
    #   event = 'VeryLazy', -- todo use cmd to lazy load
    #   opts = {
    #     task_list = {
    #       direction = 'bottom',
    #       min_height = 25,
    #       max_height = 25,
    #       default_detail = 1,
    #     },
    #   },
    # },

    conform-nvim = {
      enable = true;
      settings = {
        format_on_save = {
          lsp_format = "fallback";
          formatters_by_ft = {
            lua = "stylua";

            python = [
              "isort"
              "black"
            ];
          };
          formatters = {
            stylua.command = lib.getExe pkgs.stylua;
            # ormolu
            #
          };
        };
      };
    };
    blink-cmp = {
      enable = true;
      luaConfig.post = ''
        require('blink.cmp').setup({
          sources = {
            providers = {
              snippets = {
                opts = {
                  search_paths = { vim.fn.stdpath("data") .. "/lazy/friendly-snippets" }
                }
              }
            }
          }
        })
      '';
    };

    lsp = {
      enable = true;
      onAttach = ''
        vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
          vim.lsp.diagnostic.on_publish_diagnostics, {
            update_in_insert = true,
          }
        )
      '';
    };

    dap.enable = true;
    #   local sign = vim.fn.sign_define
    #   sign('DapBreakpoint', { text = '', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    #   sign('DapBreakpointCondition', { text = 'C', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
    #   sign('DapLogPoint', { text = 'L', texthl = 'DapLogPoint', linehl = '', numhl = '' })
    #   sign('DapStopped', { text = '→', texthl = 'DapStopped', linehl = '', numhl = '' })

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
    #   -- sign('DapBreakpointRejected', { text = 'R', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })
    # end,
    dap-ui.enable = true;
    dap-ui.settings = {
      #   { 'u', function(m) m.toggle() end, 'Toggle Dap UI' },
      #   { 'e', function(m) m.eval() end,   'Evaluate',     mode = { 'n', 'v' } },
      keys = {
        edit = "e";
        expand = [
          "<CR>"
          "<2-LeftMouse>"
        ];
        open = "o";
        remove = "d";
        repl = "r";
        toggle = "t";
      };
      floating = {
        border = "single";
        mappings = {
          close = [
            "q"
            "<Esc>"
          ];
        };
      };
    };
  };
}
