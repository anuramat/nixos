{
  lib,
  inputs,
  pkgs,
  ...
}:
let
  _mkMap =
    key: action: desc:
    {
      mode = "n";
      key = "key";
      inherit action;
    }
    // (
      if builtins.typeOf action == "string" then
        {
          action = "<cmd>${action}<cr>";
          desc = action;
        }
      else
        { }
    );
  mkMap =
    k: a: d:
    _mkMap ("<leader>hk") a d;
in
{
  keymaps = [
    {
      key = "<leader>u";
      action = "<cmd>UndotreeToggle<cr>";
      options.desc = "Undotree";
    }
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

  # TODO finish
  # extraPlugins = [
  #   (pkgs.vimUtils.buildVimPlugin {
  #     pname = "wastebin.nvim";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "matze";
  #       repo = "wastebin.nvim";
  #       rev = "HEAD";
  #       sha256 = lib.fakeSha256;
  #     };
  #   })
  #   (pkgs.vimUtils.buildVimPlugin {
  #     pname = "figtree.nvim";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "anuramat";
  #       repo = "figtree.nvim";
  #       rev = "HEAD";
  #       sha256 = lib.fakeSha256;
  #     };
  #   })
  #   (pkgs.vimUtils.buildVimPlugin {
  #     pname = "namu.nvim";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "namu-nvim";
  #       repo = "namu.nvim";
  #       rev = "HEAD";
  #       sha256 = lib.fakeSha256;
  #     };
  #   })
  #   (pkgs.vimUtils.buildVimPlugin {
  #     pname = "mdmath.nvim";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "anuramat";
  #       repo = "mdmath.nvim";
  #       rev = "HEAD";
  #       sha256 = lib.fakeSha256;
  #     };
  # })
  # ];
  # extraConfigLua = ''
  #   require('wastebin').setup({
  #     url = 'https://bin.ctrl.sn',
  #     open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
  #     ask = false,
  #   })
  # '';
}
