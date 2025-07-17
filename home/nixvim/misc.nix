{
  hax,
  pkgs,
  ...
}:
let
  inherit (hax.vim) set lua;
in
{
  keymaps = [
    (set "<leader>u" "UndotreeToggle" "Undotree")
    (set "<leader>r" (lua "function() require('flash').jump() end") "Jump")
    (
      (set "r" (lua "function() require('flash').treesitter() end") "Treesitter node") // { mode = "o"; }
    )
  ];

  plugins = {
    web-devicons.enable = true;
    sniprun.enable = true;
    nvim-lightbulb.enable = true;
    grug-far.enable = true;
    undotree.enable = true;
    schemastore.enable = true;
    dressing.enable = true;

    # TODO
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
}
