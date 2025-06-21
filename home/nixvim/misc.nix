{
  lib,
  hax,
  inputs,
  pkgs,
  ...
}:
let
  inherit (hax.vim) set;
in
{
  keymaps = [
    (set "<leader>u" "<cmd>UndotreeToggle<cr>" "Undotree")
  ];

  plugins = {
    web-devicons.enable = true;

    sniprun.enable = true;

    nvim-lightbulb.enable = true;

    grug-far.enable = true;

    dressing.enable = true;

    # namu = {
    #   keys = [
    #     [
    #       "<leader>s"
    #       "<cmd>Namu symbols<cr>"
    #       {
    #         desc = "Jump to LSP symbol";
    #         silent = true;
    #       }
    #     ]
    #   ];
    #   opts = {
    #     colorscheme = {
    #       enable = true;
    #     };
    #     namu_symbols = {
    #       enable = true;
    #       options = [ ];
    #     };
    #     ui_select = {
    #       enable = true;
    #     };
    #   };
    # };

    undotree.enable = true;

    schemastore.enable = true;

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
        enable = true;
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
    # keymaps = [
    #   (set "<leader>r" (lua "function() require('flash').jump() end") "Jump")
    #   (
    #     (set "r" (lua "function() require('flash').treesitter() end") "Treesitter node") // { mode = "o"; }
    #   )
    # ];

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
}
