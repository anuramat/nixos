{
  lib,
  inputs,
  pkgs,
  ...
}:
{

  keymaps = [
    {
      key = "<leader>u";
      action = "<cmd>UndotreeToggle<cr>";
      desc = "Undotree";
    }
  ];
  plugins = {
    undotree.enable = true;
    ts-comments.enable = true;
    plugins.schemastore.enable = true;
    # TODO mdmath mcphub figtree
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
            grammars = [ pkgs.vimPlugins.nvim-treesitter-parsers.todotxt ];
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

# 'ray-x/go.nvim', -- golang aio plugin

# haskell
# s('b', repl_toggler(ht, buffer), 'Toggle Buffer REPL')
# s('e', ht.lsp.buf_eval_all, 'Evaluate All')
# s('h', ht.hoogle.hoogle_signature, 'Show Hoogle Signature')
# s('p', ht.repl.toggle, 'Toggle Package REPL')
# s('q', ht.repl.quit, 'Quit REPL')
