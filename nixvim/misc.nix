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

  extraPlugins = [
    inputs.wastebin-nvim.packages.${pkgs.system}.default
  ];
  extraConfigLua = ''
    require('wastebin').setup({
      url = 'https://bin.ctrl.sn',
      open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
      ask = false,
    })
  '';
}
